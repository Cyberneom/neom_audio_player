import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';

import 'data/implementations/player_hive_controller.dart';
import 'data/providers/neom_audio_provider.dart';
import 'neom_audio_handler.dart';
import 'ui/player/miniplayer_controller.dart';
import 'utils/mappers/media_item_mapper.dart';
import 'utils/platform_io_helper.dart' as platform_io;

class AudioPlayerInvoker implements AudioPlayerInvokerService {

  NeomAudioHandler? audioHandler;
  List<AppMediaItem> currentMediaItems = [];
  List<AppReleaseItem> currentReleaseItems = [];

  @override
  Future<void> init({List<AppReleaseItem>? releaseItems, List<AppMediaItem>? mediaItems, int index = 0,
    bool fromMiniPlayer = false, bool isOffline = false, bool recommend = true,
    bool fromDownloads = false, bool shuffle = false, String? playlistBox, bool playItem = true,}) async {


    try {

      audioHandler = await getOrInitAudioHandler();

      if(releaseItems == null && mediaItems == null) {
        AppConfig.logger.e('No media items provided to play.');
        return;
      }

      if(releaseItems != null) {
        currentReleaseItems = releaseItems.where((item) => item.isAudioContent).toList();
        currentMediaItems = [];
        for (var item in currentReleaseItems) {
          currentMediaItems.add(AppMediaItemMapper.fromAppReleaseItem(item));
        }
      }

      if(mediaItems != null) {
        currentMediaItems = mediaItems.where((item) => item.isAudioContent).toList();
      }

      if (currentMediaItems.isEmpty) {
        AppConfig.logger.e('No audio content items to play.');
        return;
      }

      final int globalIndex = index.clamp(0, currentMediaItems.length - 1);
      if(shuffle) currentMediaItems.shuffle();

      if (!fromMiniPlayer) {
        await audioHandler?.stop();

        if (isOffline) {
          await updateNowPlaying(index: globalIndex, fromDownloads: fromDownloads, isOffline: isOffline);
        } else {
          await setValues(globalIndex, recommend: recommend, playItem: playItem);
        }
      } else {
        AppConfig.logger.d('Item is free - Session is not active.');
      }

      ///This would be needed when adding offline mode downloading audio.
      // await MetadataGod.initialize();
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'init');
    }
  }

  @override
  Future<void> setValues(int index, {bool recommend = true, bool playItem = false}) async {
    AppConfig.logger.t('Settings Values for index $index');

    try {
      if(currentReleaseItems.isNotEmpty && index < currentReleaseItems.length) {
        AppReleaseItemFirestore().existsOrInsert(currentReleaseItems[index]);
      } else if(currentMediaItems.isNotEmpty && index < currentMediaItems.length) {
        AppMediaItemFirestore().existsOrInsert(currentMediaItems[index]);
      }

      await updateNowPlaying(index: index, recommend: recommend, playItem: playItem);
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'setValues');
    }
  }

  @override
  Future<void> updateNowPlaying({List<AppMediaItem>? items, int index = 0, bool recommend = true,
    bool playItem = true, bool fromDownloads = false, bool isOffline = false}) async {

    bool nowPlaying = audioHandler?.playbackState.value.playing ?? false;
    AppConfig.logger.d('Updating Now Playing info. Now Playing: $nowPlaying');

    List<MediaItem> queue = [];

    if(items?.isNotEmpty ?? false) {
      currentMediaItems = items!;
    }

    try {
      if(isOffline && !kIsWeb) {
        final tempDirPath = await platform_io.getTempDirPath();
        if (tempDirPath != null) {
          final coverPath = '$tempDirPath/cover.jpg';
          if (!await platform_io.fileExists(coverPath)) {
            final byteData = await rootBundle.load(AppAssets.audioPlayerCover);
            await platform_io.writeFileBytes(
              coverPath,
              byteData.buffer
                  .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
            );
          }
          for (int i = 0; i < currentMediaItems.length; i++) {
            queue.add(await setTags(currentMediaItems[i], tempDirPath));
          }
        }
      } else {
        queue = currentMediaItems.map((item) => MediaItemMapper.fromAppMediaItem(
          item: item,
          autoplay: recommend,
        ),).toList();
      }
      await audioHandler?.setShuffleMode(AudioServiceShuffleMode.none);

      if (queue.isEmpty) {
        AppConfig.logger.e('Queue is empty, nothing to play.');
        return;
      }

      final safeIndex = index.clamp(0, queue.length - 1);

      List<MediaItem> orderedQueue = [
        ...queue.sublist(safeIndex),
        ...queue.sublist(0, safeIndex)
      ];

      await audioHandler?.updateQueue(orderedQueue);

      final selectedItem = queue[safeIndex];
      // The selected item is always at index 0 in orderedQueue
      await audioHandler?.customAction('skipToMediaItem', {'id': selectedItem.id, 'index': 0},);
      AppConfig.logger.d('skipToMediaItem: ${selectedItem.title} at orderedQueue index 0');

      audioHandler?.currentMediaItem = selectedItem;

      if(playItem || nowPlaying) {
        AppConfig.logger.d("Starting stream for ${selectedItem.artist ?? ''} - ${selectedItem.title} and URL ${selectedItem.extras!['url'].toString()}");
        await audioHandler?.play();
        Sint.find<MiniPlayerController>().setMediaItem(selectedItem);
      }

      enforceRepeat();
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'updateNowPlaying');
    }
  }

  Future<MediaItem> setTags(AppMediaItem appMediaItem, String tempDirPath) async {
    String playTitle = appMediaItem.name;
    if(playTitle.isEmpty && appMediaItem.album.isNotEmpty) {
      playTitle = appMediaItem.album;
    }
    String playArtist = appMediaItem.ownerName;
    playArtist == '<unknown>' ? playArtist = 'Unknown' : playArtist = appMediaItem.ownerName;

    String playAlbum = appMediaItem.album;
    int playDuration = appMediaItem.duration;
    String imagePath = '$tempDirPath/${TextUtilities.removeAllWhitespace(appMediaItem.name)}.png';

    MediaItem tempDict = MediaItem(
      id: appMediaItem.id.toString(),
      album: playAlbum,
      duration: Duration(milliseconds: playDuration),
      title: playTitle.split('(')[0],
      artist: playArtist,
      genre: appMediaItem.categories?.isNotEmpty ?? false ? appMediaItem.categories?.first : null,
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
      final AudioServiceRepeatMode repeatMode = PlayerHiveController().repeatMode;
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
        AppConfig.logger.d("NeomAudioHandler not registered, getting and registering...");

        // Obtener la instancia del AudioHandler de forma asíncrona
        // Reemplaza NeomAudioProvider().getAudioHandler() con tu lógica real para obtener el handler
        handler = await NeomAudioProvider().getAudioHandler();

        // Registrar la instancia obtenida como un singleton en GetX
        Sint.put<NeomAudioHandler>(handler);
        AppConfig.logger.i("NeomAudioHandler registered successfully with GetX.");
      } else {
        AppConfig.logger.d("NeomAudioHandler is already registered with GetX.");
        handler = Sint.find<NeomAudioHandler>();
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'initAudioHandler');
    }

    audioHandler = handler;
  }

  @override
  Future<NeomAudioHandler?> getOrInitAudioHandler() async {
    NeomAudioHandler? handler;

    try {
      if (!Sint.isRegistered<NeomAudioHandler>()) {
        AppConfig.logger.d("NeomAudioHandler not registered, getting and registering...");

        // Obtener la instancia del AudioHandler de forma asíncrona
        // Reemplaza NeomAudioProvider().getAudioHandler() con tu lógica real para obtener el handler
        handler = await NeomAudioProvider().getAudioHandler();

        // Registrar la instancia obtenida como un singleton en GetX
        Sint.put<NeomAudioHandler>(handler);
        AppConfig.logger.i("NeomAudioHandler registered successfully with SINT.");
      } else {
        AppConfig.logger.d("NeomAudioHandler is already registered with SINT.");
        handler = Sint.find<NeomAudioHandler>();
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'getOrInitAudioHandler');
    }

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
