import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:path_provider/path_provider.dart';

import 'data/implementations/player_hive_controller.dart';
import 'data/providers/neom_audio_provider.dart';
import 'neom_audio_handler.dart';
import 'ui/player/miniplayer_controller.dart';
import 'utils/mappers/media_item_mapper.dart';

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
        currentReleaseItems = releaseItems;
        currentMediaItems = [];
        for (var item in currentReleaseItems) {
          currentMediaItems.add(AppMediaItemMapper.fromAppReleaseItem(item));
        }
      }

      if(mediaItems != null) {
        currentMediaItems = [];
        for (var item in mediaItems) {
          currentMediaItems.add(item);
        }
      }

      final int globalIndex = index < 0 ? 0 : index;
      if(shuffle) currentMediaItems.shuffle();

      if (!fromMiniPlayer) {
        if (Platform.isIOS) audioHandler?.stop();

        if (isOffline) {
          await updateNowPlaying(index: index, fromDownloads: fromDownloads, isOffline: isOffline);
        } else {
          setValues(globalIndex, recommend: recommend, playItem: playItem);
        }
      } else {
        AppConfig.logger.d('Item is free - Session is not active.');
      }

      ///This would be needed when adding offline mode downloading audio.
      // await MetadataGod.initialize();
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> setValues(int index, {bool recommend = true, bool playItem = false}) async {
    AppConfig.logger.t('Settings Values for index $index');

    try {
      if(currentReleaseItems.isNotEmpty) {
        AppReleaseItemFirestore().existsOrInsert(currentReleaseItems[index]);
      } else {
        AppMediaItemFirestore().existsOrInsert(currentMediaItems[index]);
      }

      await updateNowPlaying(index: index, recommend: recommend, playItem: playItem);
    } catch(e) {
      AppConfig.logger.e(e.toString());
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
      if(isOffline) {
        getTemporaryDirectory().then((tempDir) async {
          final File file = File('${tempDir.path}/cover.jpg');
          if (!await file.exists()) {
            final byteData = await rootBundle.load(AppAssets.audioPlayerCover);
            await file.writeAsBytes(
              byteData.buffer
                  .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
            );
          }
          for (int i = 0; i < currentMediaItems.length; i++) {
            queue.add(await setTags(currentMediaItems[i], tempDir),);
          }
        });
      } else {
        queue = currentMediaItems.map((item) => MediaItemMapper.fromAppMediaItem(
          item: item,
          autoplay: recommend,
        ),).toList();
      }
      if(Platform.isAndroid || Platform.isIOS) {
        await audioHandler?.setShuffleMode(AudioServiceShuffleMode.none);

        List<MediaItem> orderedQueue = [
          ...queue.sublist(index),
          ...queue.sublist(0, index)
        ];

        await audioHandler?.updateQueue(orderedQueue);

        int nextIndex = 0;
        if (queue.indexWhere((item) => item.id == queue[index].id) >= 0) {
          nextIndex = queue.indexWhere((item) => item.id == queue[index].id);
          AppConfig.logger.d('MediaItem found in Queue with Index $index');
        }

        await audioHandler?.customAction('skipToMediaItem', {'id': queue[index].id, 'index': nextIndex},);

        audioHandler?.currentMediaItem = queue.elementAt(index);

        if(playItem || nowPlaying) {
          AppConfig.logger.d("Starting stream for ${queue[index].artist ?? ''} - ${queue[index].title} and URL ${queue[index].extras!['url'].toString()}");
          await audioHandler?.play();
          Sint.find<MiniPlayerController>().setMediaItem(queue.elementAt(index));
        }

        enforceRepeat();
      } else {
        AppConfig.logger.i('MusicPlayer not available yet.');
        AppUtilities.showSnackBar(
          title: CommonTranslationConstants.underConstruction,
          message: MessageTranslationConstants.featureAvailableSoon,
        );
      }
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
  }

  Future<MediaItem> setTags(AppMediaItem appMediaItem, Directory tempDir,) async {
    String playTitle = appMediaItem.name;
    if(playTitle.isEmpty && appMediaItem.album.isNotEmpty) {
      playTitle = appMediaItem.album;
    }
    String playArtist = appMediaItem.ownerName;
    playArtist == '<unknown>' ? playArtist = 'Unknown' : playArtist = appMediaItem.ownerName;

    String playAlbum = appMediaItem.album;
    int playDuration = appMediaItem.duration;
    String imagePath = '${tempDir.path}/${TextUtilities.removeAllWhitespace(appMediaItem.name)}.png';

    MediaItem tempDict = MediaItem(
      id: appMediaItem.id.toString(),
      album: playAlbum,
      duration: Duration(milliseconds: playDuration),
      title: playTitle.split('(')[0],
      artist: playArtist,
      genre: appMediaItem.categories?.isNotEmpty ?? false ? appMediaItem.categories?.first : null,
      artUri: Uri.file(imagePath),
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
