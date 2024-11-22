import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart' as getx;
import 'package:get_it/get_it.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:path_provider/path_provider.dart';

import 'data/implementations/app_hive_controller.dart';
import 'domain/use_cases/neom_audio_handler.dart';
import 'utils/helpers/media_item_mapper.dart';

// ignore: avoid_classes_with_only_static_members
class NeomPlayerInvoker {

  // static final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();
  static NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  static Future<void> init({required List<AppMediaItem> appMediaItems, required int index,
    bool fromMiniPlayer = false, bool isOffline = false, bool recommend = true,
    bool fromDownloads = false, bool shuffle = false, String? playlistBox, bool playItem = true,}) async {


    try {
      if (GetIt.I.isRegistered<NeomAudioHandler>()) {
        audioHandler = await GetIt.I.getAsync<NeomAudioHandler>();
      }

      final int globalIndex = index < 0 ? 0 : index;
      final List<AppMediaItem> finalList = appMediaItems;
      if (shuffle) finalList.shuffle();

      if (!fromMiniPlayer) {
        if (Platform.isIOS) {
          audioHandler.stop(); /// Don't know why but it fixes the playback issue with iOS Side
        }
        if (isOffline) {
          fromDownloads ? setDownValues(finalList, globalIndex) : setOffValues(finalList, globalIndex);
        } else {
          setValues(finalList, globalIndex, recommend: recommend, playItem: playItem);
        }
      }

      ///This would be needed when adding offline mode downloading audio.
      // await MetadataGod.initialize();
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  static Future<void> setValues(List<AppMediaItem> appMediaItems, int index, {bool recommend = true, bool playItem = false}) async {
    AppUtilities.logger.t('Settings Values for index $index');

    try {
      final List<MediaItem> queue = [];
      AppMediaItem appMediaItem = appMediaItems[index];
      AppUtilities.logger.t('Loading media ${appMediaItem.name} for music player with index $index');

      queue.addAll(
        appMediaItems.map(
              (song) => MediaItemMapper.appMediaItemToMediaItem(appMediaItem: song,
            autoplay: recommend,
            // playlistBox: playlistBox,
          ),
        ),
      );
      if(queue.isNotEmpty) {
        audioHandler.currentMediaItem = queue.first;
      }
      await updateNowPlaying(queue, index, playItem: playItem);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  static void setOffValues(List<AppMediaItem> response, int index) {
    getTemporaryDirectory().then((tempDir) async {
      final File file = File('${tempDir.path}/cover.jpg');
      if (!await file.exists()) {
        final byteData = await rootBundle.load(AppAssets.audioPlayerCover);
        await file.writeAsBytes(
          byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        );
      }
      final List<MediaItem> queue = [];
      for (int i = 0; i < response.length; i++) {
        queue.add(
          await setTags(response[i], tempDir),
        );
      }
      await updateNowPlaying(queue, index);
    });
  }

  static Future<void> setDownValues(List<AppMediaItem> response, int index) async {
    final List<MediaItem> queue = [];
    queue.addAll(
      response.map((song) => MediaItemMapper.appMediaItemToMediaItem(appMediaItem: song),),
    );
    await updateNowPlaying(queue, index);
  }

  static Future<MediaItem> setTags(AppMediaItem response, Directory tempDir,) async {
    String playTitle = response.name;
    if(playTitle.isEmpty && response.album.isNotEmpty) {
      playTitle = response.album;
    }
    String playArtist = response.artist;
    playArtist == '<unknown>' ? playArtist = 'Unknown' : playArtist = response.artist;

    final String playAlbum = response.album;
    final int playDuration = response.duration;
    final String imagePath = '${tempDir.path}/${response.name.removeAllWhitespace}.png';

    final MediaItem tempDict = MediaItem(
      id: response.id.toString(),
      album: playAlbum,
      duration: Duration(milliseconds: playDuration),
      title: playTitle.split('(')[0],
      artist: playArtist,
      genre: response.genre,
      artUri: Uri.file(imagePath),
      extras: {
        'url': response.url,
        'date_added': response.publishedYear,
        'date_modified': response.releaseDate,
        // 'size': response.size,
        'year': response.publishedYear,
      },
    );
    return tempDict;
  }

  static Future<void> updateNowPlaying(List<MediaItem> queue, int index, {bool playItem = true}) async {

    bool nowPlaying = audioHandler.playbackState.value.playing;
    AppUtilities.logger.d('Updating Now Playing info. Now Playing: $nowPlaying');

    try {
      ///DEPRECATED await audioHandler.startService();
      if(Platform.isAndroid || Platform.isIOS) {
        await audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
        await audioHandler.updateQueue(queue);

        int nextIndex = 0;
        if (queue.indexWhere((item) => item.id == queue[index].id) >= 0) {
          nextIndex = queue.indexWhere((item) => item.id == queue[index].id);
          AppUtilities.logger.d('MediaItem found in Queue with Index $index');
        }

        await audioHandler.customAction('skipToMediaItem', {'id': queue[index].id, 'index': nextIndex},);

        audioHandler.currentMediaItem = queue.elementAt(index);

        if(playItem || nowPlaying) {
          AppUtilities.logger.d("Starting stream for ${queue[index].artist ?? ''} - ${queue[index].title} and URL ${queue[index].extras!['url'].toString()}");
          await audioHandler.play();
        }

        // getx.Get.find<MiniPlayerController>().setMediaItem(queue.elementAt(index));
        // getx.Get.find<MediaPlayerController>().setMediaItem(queue.elementAt(index));
        ///DEPRECATED await audioHandler.playFromUri(Uri.parse(queue[index].extras!['url'].toString()));
        enforceRepeat();
      } else {
        AppUtilities.logger.i('MusicPlayer not available yet.');
        AppUtilities.showSnackBar(
          title: MessageTranslationConstants.underConstruction,
          message: MessageTranslationConstants.featureAvailableSoon,
        );
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  static void enforceRepeat() {
    final bool enforceRepeat = AppHiveController().enforceRepeat;
    if (enforceRepeat) {
      final AudioServiceRepeatMode repeatMode = AppHiveController().repeatMode;
      switch (repeatMode) {
        case AudioServiceRepeatMode.none:
          audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        case AudioServiceRepeatMode.all:
          audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        case AudioServiceRepeatMode.one:
          audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        default:
          break;
      }
    } else {
      audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
      AppHiveController().updateRepeatMode(AudioServiceRepeatMode.none);
    }
  }
}
