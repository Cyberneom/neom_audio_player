import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/playable_item.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';

import 'data/implementations/player_hive_controller.dart';
import 'data/providers/neom_audio_provider.dart';
import 'neom_audio_handler.dart';
import 'ui/player/miniplayer_controller.dart';
import 'utils/mappers/media_item_mapper.dart';
import 'utils/platform_io_helper.dart' as platform_io;
import 'utils/audio_item_source_availability.dart';

/// Entry-point service that converts arbitrary `PlayableItem`s
/// (`AppMediaItem`, `AppReleaseItem`, `Itemlist`) into [MediaItem]s and
/// pushes them into the [NeomAudioHandler] queue.
///
/// Use this from outside the module instead of touching the audio handler
/// directly — it lazy-initialises the handler on first call, hides the
/// platform branching (web has no offline cache), and applies the host
/// app's `AppFlavour` rules (audio limitation for non-owners, etc.).
///
/// Typical usage from a list tile:
/// ```dart
/// Sint.find<AudioPlayerInvokerService>().init(
///   mediaItems: items,
///   index: tappedIndex,
///   playItem: true,
/// );
/// ```
class AudioPlayerInvoker implements AudioPlayerInvokerService {
  NeomAudioHandler? audioHandler;
  List<AppMediaItem> currentMediaItems = [];
  List<AppReleaseItem> currentReleaseItems = [];
  bool _isInitProcessing = false;

  @override
  Future<void> init({
    List<PlayableItem>? items,
    List<AppReleaseItem>? releaseItems,
    List<AppMediaItem>? mediaItems,
    int index = 0,
    bool fromMiniPlayer = false,
    bool isOffline = false,
    bool recommend = true,
    bool fromDownloads = false,
    bool shuffle = false,
    String? playlistBox,
    bool playItem = true,
  }) async {
    // Prevent concurrent executions if multiple playlists are tapped rapidly
    while (_isInitProcessing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _isInitProcessing = true;

    try {
      audioHandler = await getOrInitAudioHandler();
      if (audioHandler == null) {
        throw StateError('The audio player could not be initialized.');
      }

      if (items == null && releaseItems == null && mediaItems == null) {
        AppConfig.logger.e('No media items provided to play.');
        return;
      }

      final List<PlayableItem> requestedItems =
          mediaItems ?? releaseItems ?? items ?? const [];
      final requestedItem = requestedItems.isEmpty
          ? null
          : requestedItems[index.clamp(0, requestedItems.length - 1)];
      final playableItems = requestedItems
          .where((item) => isAudioPlaybackItem(item) && !hasNoAudioSource(item))
          .toList();
      currentReleaseItems = playableItems.whereType<AppReleaseItem>().toList();
      currentMediaItems = playableItems
          .map(
            (item) => item is AppReleaseItem
                ? AppMediaItemMapper.fromAppReleaseItem(item)
                : item as AppMediaItem,
          )
          .toList();

      // Keep the tapped item after filtering. An unavailable selection must
      // never silently select a different track or reuse the previous queue.
      var globalIndex = requestedItem == null
          ? -1
          : playableItems.indexOf(requestedItem);
      if (globalIndex < 0) {
        throw StateError('The requested audio item has no playable source.');
      }
      if (shuffle) {
        final selected = currentMediaItems[globalIndex];
        currentMediaItems.shuffle();
        globalIndex = currentMediaItems.indexOf(selected);
      }

      if (!fromMiniPlayer) {
        await audioHandler?.stop();

        if (isOffline) {
          await updateNowPlaying(
            index: globalIndex,
            fromDownloads: fromDownloads,
            isOffline: isOffline,
          );
        } else {
          await setValues(
            globalIndex,
            recommend: recommend,
            playItem: playItem,
          );
        }
      } else {
        AppConfig.logger.d('Item is free - Session is not active.');
      }

      ///This would be needed when adding offline mode downloading audio.
      // await MetadataGod.initialize();
    } catch (e, st) {
      await audioHandler?.stop();
      audioHandler?.currentMediaItem = null;
      audioHandler?.mediaItem.add(null);
      audioHandler?.queue.add(const <MediaItem>[]);
      if (Sint.isRegistered<MiniPlayerController>()) {
        Sint.find<MiniPlayerController>().clear();
      }
      try {
        if (Sint.context != null) {
          AppUtilities.showSnackBar(
            message: AppTranslationConstants.playbackErrorStopped.tr,
          );
        }
      } catch (_) {
        // A standalone caller may not have mounted the navigation root yet.
      }
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'init',
      );
    } finally {
      _isInitProcessing = false;
    }
  }

  @override
  Future<void> setValues(
    int index, {
    bool recommend = true,
    bool playItem = false,
  }) async {
    AppConfig.logger.t('Settings Values for index $index');

    try {
      // Guests may play public catalog entries, but playback must not create
      // or mutate catalog documents as a side effect.
      if (AppConfig.instance.canPersistUserActivity) {
        final selectedItem = currentMediaItems[index];
        final releaseItem = currentReleaseItems.firstWhereOrNull(
          (item) => item.id == selectedItem.id,
        );
        if (releaseItem != null) {
          AppReleaseItemFirestore().existsOrInsert(releaseItem);
        } else {
          AppMediaItemFirestore().existsOrInsert(selectedItem);
        }
      }

      await updateNowPlaying(
        index: index,
        recommend: recommend,
        playItem: playItem,
      );
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'setValues',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateNowPlaying({
    List<AppMediaItem>? items,
    int index = 0,
    bool recommend = true,
    bool playItem = true,
    bool fromDownloads = false,
    bool isOffline = false,
  }) async {
    bool nowPlaying = audioHandler?.playbackState.value.playing ?? false;
    AppConfig.logger.d('Updating Now Playing info. Now Playing: $nowPlaying');

    List<MediaItem> queue = [];

    if (items?.isNotEmpty ?? false) {
      currentMediaItems = items!;
    }

    try {
      if (isOffline && !kIsWeb) {
        final tempDirPath = await platform_io.getTempDirPath();
        if (tempDirPath != null) {
          final coverPath = '$tempDirPath/cover.jpg';
          if (!await platform_io.fileExists(coverPath)) {
            final byteData = await rootBundle.load(AppAssets.audioPlayerCover);
            await platform_io.writeFileBytes(
              coverPath,
              byteData.buffer.asUint8List(
                byteData.offsetInBytes,
                byteData.lengthInBytes,
              ),
            );
          }
          for (int i = 0; i < currentMediaItems.length; i++) {
            queue.add(await setTags(currentMediaItems[i], tempDirPath));
          }
        }
      } else {
        queue = currentMediaItems
            .map(
              (item) => MediaItemMapper.fromAppMediaItem(
                item: item,
                autoplay: recommend,
              ),
            )
            .toList();
      }
      await audioHandler?.setShuffleMode(AudioServiceShuffleMode.none);

      if (queue.isEmpty) {
        AppConfig.logger.e('Queue is empty, nothing to play.');
        return;
      }

      final safeIndex = index.clamp(0, queue.length - 1);

      List<MediaItem> orderedQueue = [
        ...queue.sublist(safeIndex),
        ...queue.sublist(0, safeIndex),
      ];

      await audioHandler?.updateQueue(orderedQueue);

      final selectedItem = queue[safeIndex];
      // The selected item is always at index 0 in orderedQueue
      await audioHandler?.customAction('skipToMediaItem', {
        'id': selectedItem.id,
        'index': 0,
      });
      AppConfig.logger.d(
        'skipToMediaItem: ${selectedItem.title} at orderedQueue index 0',
      );

      audioHandler?.currentMediaItem = selectedItem;
      if (Sint.isRegistered<MiniPlayerController>()) {
        await Sint.find<MiniPlayerController>().setMediaItem(selectedItem);
      }

      if (playItem || nowPlaying) {
        AppConfig.logger.d(
          "Starting stream for ${selectedItem.artist ?? ''} - ${selectedItem.title}",
        );
        // just_audio's play future lasts until playback stops. Releasing the
        // request here lets the next song replace this queue immediately.
        unawaited(audioHandler?.play());
      }

      enforceRepeat();
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'updateNowPlaying',
      );
      rethrow;
    }
  }

  Future<MediaItem> setTags(
    AppMediaItem appMediaItem,
    String tempDirPath,
  ) async {
    String playTitle = appMediaItem.name;
    if (playTitle.isEmpty && appMediaItem.album.isNotEmpty) {
      playTitle = appMediaItem.album;
    }
    String playArtist = appMediaItem.ownerName;
    playArtist == '<unknown>'
        ? playArtist = 'Unknown'
        : playArtist = appMediaItem.ownerName;

    String playAlbum = appMediaItem.album;
    int playDuration = appMediaItem.duration;
    String imagePath =
        '$tempDirPath/${TextUtilities.removeAllWhitespace(appMediaItem.name)}.png';

    MediaItem tempDict = MediaItem(
      id: appMediaItem.id.toString(),
      album: playAlbum,
      duration: Duration(milliseconds: playDuration),
      title: playTitle.split('(')[0],
      artist: playArtist,
      genre: appMediaItem.categories?.isNotEmpty ?? false
          ? appMediaItem.categories?.first
          : null,
      artUri: platform_io.fileUri(imagePath),
      extras: {
        'url': appMediaItem.url,
        'publishedYear': appMediaItem.publishedYear,
        'releaseDate': appMediaItem.releaseDate,
      },
    );
    return tempDict;
  }

  @override
  void enforceRepeat() {
    final bool enforceRepeat = PlayerHiveController().enforceRepeat;
    if (enforceRepeat) {
      final AudioServiceRepeatMode repeatMode =
          PlayerHiveController().repeatMode;
      switch (repeatMode) {
        case AudioServiceRepeatMode.none:
          audioHandler?.setRepeatMode(AudioServiceRepeatMode.none);
        case AudioServiceRepeatMode.all:
          audioHandler?.setRepeatMode(AudioServiceRepeatMode.all);
        case AudioServiceRepeatMode.one:
          audioHandler?.setRepeatMode(AudioServiceRepeatMode.one);
        default:
          break;
      }
    } else {
      audioHandler?.setRepeatMode(AudioServiceRepeatMode.none);
      PlayerHiveController().updateRepeatMode(AudioServiceRepeatMode.none);
    }
  }

  @override
  Future<void> initAudioHandler() async {
    AppConfig.logger.d("Initializing NeomAudioHandler...");

    NeomAudioHandler? handler;

    try {
      if (!Sint.isRegistered<NeomAudioHandler>()) {
        AppConfig.logger.d(
          "NeomAudioHandler not registered, getting and registering...",
        );

        // Obtener la instancia del AudioHandler de forma asíncrona
        // Reemplaza NeomAudioProvider().getAudioHandler() con tu lógica real para obtener el handler
        handler = await NeomAudioProvider().getAudioHandler();

        // Registrar la instancia obtenida como un singleton en GetX
        Sint.put<NeomAudioHandler>(handler);
        AppConfig.logger.i(
          "NeomAudioHandler registered successfully with GetX.",
        );
      } else {
        AppConfig.logger.d("NeomAudioHandler is already registered with GetX.");
        handler = Sint.find<NeomAudioHandler>();
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'initAudioHandler',
      );
    }

    audioHandler = handler;
    await audioHandler?.enforcePersonalStateBoundary();
  }

  @override
  Future<NeomAudioHandler?> getOrInitAudioHandler() async {
    NeomAudioHandler? handler;

    try {
      if (!Sint.isRegistered<NeomAudioHandler>()) {
        AppConfig.logger.d(
          "NeomAudioHandler not registered, getting and registering...",
        );

        // Obtener la instancia del AudioHandler de forma asíncrona
        // Reemplaza NeomAudioProvider().getAudioHandler() con tu lógica real para obtener el handler
        handler = await NeomAudioProvider().getAudioHandler();

        // Registrar la instancia obtenida como un singleton en GetX
        Sint.put<NeomAudioHandler>(handler);
        AppConfig.logger.i(
          "NeomAudioHandler registered successfully with SINT.",
        );
      } else {
        AppConfig.logger.d("NeomAudioHandler is already registered with SINT.");
        handler = Sint.find<NeomAudioHandler>();
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'getOrInitAudioHandler',
      );
    }

    await handler?.enforcePersonalStateBoundary();
    return handler;
  }

  @override
  Future<void> pause() async {
    await audioHandler?.pause();
  }

  @override
  Future<void> play() async {
    await audioHandler?.play();
  }

  @override
  Future<void> stop() async {
    await audioHandler?.stop();
  }
}
