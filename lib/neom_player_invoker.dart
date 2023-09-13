/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_music_player/data/implementations/app_hive_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';
import 'package:neom_music_player/ui/player/miniplayer_controller.dart';
import 'package:neom_music_player/utils/helpers/media_item_mapper.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/utils/music_player_utilities.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart' as getx;

// ignore: avoid_classes_with_only_static_members
class NeomPlayerInvoker {
  static final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  static Future<void> init({required List<AppMediaItem> appMediaItems, required int index,
    bool fromMiniPlayer = false, bool isOffline = false, bool recommend = true,
    bool fromDownloads = false, bool shuffle = false, String? playlistBox,}) async {

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
        setValues(finalList, globalIndex, recommend: recommend,);
      }
    }
  }

  static Future<void> setValues(List<AppMediaItem> response, int index, {bool recommend = true}) async {
    AppUtilities.logger.i("Settings Values for index $index");
    final List<MediaItem> queue = [];
    AppMediaItem playItem = response[index];
    // final AppMediaItem? nextItem = index == response.length - 1 ? null : response[index + 1];

    if (playItem.mediaSource == AppMediaSource.youtube) {
      playItem = await MusicPlayerUtilities.refreshYtLink(playItem);
    }
    // if (nextItem != null && playItem.mediaSource == AppMediaSource.youtube) {
    //   await refreshYtLink(nextItem);
    // }

    queue.addAll(
      response.map(
            (song) => MediaItemMapper.appMediaItemToMediaItem(appMediaItem: song,
          autoplay: recommend,
          // playlistBox: playlistBox,
        ),
      ),
    );
    await updateNowPlaying(queue, index, playItem: false);
  }

  static void setOffValues(List<AppMediaItem> response, int index) {
    getTemporaryDirectory().then((tempDir) async {
      final File file = File('${tempDir.path}/cover.jpg');
      if (!await file.exists()) {
        final byteData = await rootBundle.load(AppAssets.musicPlayerCover);
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
      updateNowPlaying(queue, index);
    });
  }

  static void setDownValues(List<AppMediaItem> response, int index) {
    final List<MediaItem> queue = [];
    queue.addAll(
      response.map((song) => MediaItemMapper.appMediaItemToMediaItem(appMediaItem: song),),
    );
    updateNowPlaying(queue, index);
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
    AppUtilities.logger.i("Updating Now Playing info.");

    try {
      // await audioHandler.startService();
      if(Platform.isAndroid || Platform.isIOS) {
        await audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
        await audioHandler.updateQueue(queue);

        int nextIndex = 0;
        if (queue.indexWhere((item) => item.id == queue[index].id) >= 0) {
          nextIndex = queue.indexWhere((item) => item.id == queue[index].id);
          AppUtilities.logger.d("MediaItem found in Queue with Index $index");
        }

        await audioHandler.customAction(
            'skipToMediaItem', {'id': queue[index].id, 'index': nextIndex});
        audioHandler.currentMediaItem = queue.elementAt(index);
        AppUtilities.logger.d(
            "Starting stream for ${queue[index].title} and URL ${queue[index]
                .extras!['url'].toString()}");

        if(playItem || (audioHandler.playbackState.valueWrapper?.value?.playing ?? false)) {
          await audioHandler.play();
        }

        getx.Get.find<MiniPlayerController>().setMediaItem(
            queue.elementAt(index));
        // await audioHandler.playFromUri(Uri.parse(queue[index].extras!['url'].toString()));
        final bool enforceRepeat = AppHiveController().enforceRepeat;
        if (enforceRepeat) {
          final AudioServiceRepeatMode repeatMode = AppHiveController()
              .repeatMode;
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
      } else {
        AppUtilities.logger.i("MusicPlayer not available yet.");
        AppUtilities.showSnackBar(
          MessageTranslationConstants.underConstruction.tr,
          MessageTranslationConstants.featureAvailableSoon.tr,
        );
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

  }
}
