import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart' as getx;
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/message_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/use_cases/audio_player_service.dart';
import 'package:neom_media_player/utils/helpers/media_item_mapper.dart';
import 'package:path_provider/path_provider.dart';

import 'data/implementations/player_hive_controller.dart';
import 'data/providers/neom_audio_provider.dart';
import 'neom_audio_handler.dart';

class AudioPlayerInvoker implements AudioPlayerService {

  NeomAudioHandler? audioHandler;

  @override
  Future<void> init({required List<AppMediaItem> appMediaItems, required int index,
    bool fromMiniPlayer = false, bool isOffline = false, bool recommend = true,
    bool fromDownloads = false, bool shuffle = false, String? playlistBox, bool playItem = true,}) async {


    try {
      audioHandler = await getOrInitAudioHandler();

      final int globalIndex = index < 0 ? 0 : index;
      if(shuffle) appMediaItems.shuffle();

      if (!fromMiniPlayer) {
        if (Platform.isIOS) audioHandler?.stop();

        if (isOffline) {
          await updateNowPlaying(appMediaItems, index, fromDownloads: fromDownloads, isOffline: isOffline);
        } else {
          setValues(appMediaItems, globalIndex, recommend: recommend, playItem: playItem);
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
  Future<void> setValues(List<AppMediaItem> appMediaItems, int index, {bool recommend = true, bool playItem = false}) async {
    AppConfig.logger.t('Settings Values for index $index');

    try {
      // final List<MediaItem> queue = [];
      AppMediaItem appMediaItem = appMediaItems[index];
      AppConfig.logger.t('Loading media ${appMediaItem.name} for music player with index $index');
      AppMediaItemFirestore().existsOrInsert(appMediaItem);

      updateNowPlaying(appMediaItems, index, recommend: recommend, playItem: playItem);
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> updateNowPlaying(List<AppMediaItem> appMediaItems, int index,
      {bool recommend = true, bool playItem = true, bool fromDownloads = false, bool isOffline = false}) async {

    bool nowPlaying = audioHandler?.playbackState.value.playing ?? false;
    AppConfig.logger.d('Updating Now Playing info. Now Playing: $nowPlaying');

    List<MediaItem> queue = [];

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
          for (int i = 0; i < appMediaItems.length; i++) {
            queue.add(await setTags(appMediaItems[i], tempDir),);
          }
        });
      } else {
        queue = appMediaItems.map((item) => MediaItemMapper
            .fromAppMediaItem(appMediaItem: item, autoplay: recommend,),).toList();
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
        }

        enforceRepeat();
      } else {
        AppConfig.logger.i('MusicPlayer not available yet.');
        AppUtilities.showSnackBar(
          title: MessageTranslationConstants.underConstruction,
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
    String playArtist = appMediaItem.artist;
    playArtist == '<unknown>' ? playArtist = 'Unknown' : playArtist = appMediaItem.artist;

    String playAlbum = appMediaItem.album;
    int playDuration = appMediaItem.duration;
    String imagePath = '${tempDir.path}/${appMediaItem.name.removeAllWhitespace}.png';

    MediaItem tempDict = MediaItem(
      id: appMediaItem.id.toString(),
      album: playAlbum,
      duration: Duration(milliseconds: playDuration),
      title: playTitle.split('(')[0],
      artist: playArtist,
      genre: appMediaItem.genres?.isNotEmpty ?? false ? appMediaItem.genres?.first : null,
      artUri: Uri.file(imagePath),
      extras: {
        'url': appMediaItem.url,
        'date_added': appMediaItem.publishedYear,
        'date_modified': appMediaItem.releaseDate,
        'year': appMediaItem.publishedYear,
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
      if (!getx.Get.isRegistered<NeomAudioHandler>()) {
        AppConfig.logger.d("NeomAudioHandler not registered, getting and registering...");

        // Obtener la instancia del AudioHandler de forma asíncrona
        // Reemplaza NeomAudioProvider().getAudioHandler() con tu lógica real para obtener el handler
        handler = await NeomAudioProvider().getAudioHandler();

        // Registrar la instancia obtenida como un singleton en GetX
        getx.Get.put<NeomAudioHandler>(handler);
        AppConfig.logger.i("NeomAudioHandler registered successfully with GetX.");
      } else {
        AppConfig.logger.d("NeomAudioHandler is already registered with GetX.");
        handler = getx.Get.find<NeomAudioHandler>();
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    audioHandler = handler;
  }

  Future<NeomAudioHandler?> getOrInitAudioHandler() async {
    NeomAudioHandler? handler;

    try {
      if (!getx.Get.isRegistered<NeomAudioHandler>()) {
        AppConfig.logger.d("NeomAudioHandler not registered, getting and registering...");

        // Obtener la instancia del AudioHandler de forma asíncrona
        // Reemplaza NeomAudioProvider().getAudioHandler() con tu lógica real para obtener el handler
        handler = await NeomAudioProvider().getAudioHandler();

        // Registrar la instancia obtenida como un singleton en GetX
        getx.Get.put<NeomAudioHandler>(handler);
        AppConfig.logger.i("NeomAudioHandler registered successfully with GetX.");
      } else {
        AppConfig.logger.d("NeomAudioHandler is already registered with GetX.");
        handler = getx.Get.find<NeomAudioHandler>();
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return handler;
  }

}
