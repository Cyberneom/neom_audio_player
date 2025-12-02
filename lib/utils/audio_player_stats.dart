import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

import 'mappers/media_item_mapper.dart';

class AudioPlayerStats {

  static Future<void> addRecentlyPlayed(MediaItem mediaItem) async {
    AppConfig.logger.d('Adding ${mediaItem.id} to recently played');

    try {
      final playerBox = await AppHiveController().getBox(AppHiveBox.player.name);
      final statsBox = await AppHiveController().getBox(AppHiveBox.stats.name);

      List recentList = await playerBox.get(AppHiveConstants.recentSongs, defaultValue: [])?.toList() as List;
      final Map songStats = await statsBox.get(mediaItem.id, defaultValue: {}) as Map;
      final Map mostPlayed = await statsBox.get(AppHiveConstants.mostPlayed, defaultValue: {}) as Map;

      songStats[AppHiveConstants.lastPlayed] = DateTime.now().millisecondsSinceEpoch;
      songStats[AppHiveConstants.playCount] = songStats[AppHiveConstants.playCount] == null ? 1 : songStats[AppHiveConstants.playCount] + 1;
      songStats[AppHiveConstants.title] = mediaItem.title;
      songStats[AppHiveConstants.artist] = mediaItem.artist;
      songStats[AppHiveConstants.album] = mediaItem.album;
      songStats[AppHiveConstants.id] = mediaItem.id;
      statsBox.put(mediaItem.id, songStats);

      if ((songStats[AppHiveConstants.playCount] as int) > (mostPlayed[AppHiveConstants.playCount] as int? ?? 0)) {
        statsBox.put(AppHiveConstants.mostPlayed, songStats);
      }
      AppConfig.logger.i('Adding mediaItemId: ${mediaItem.id} Name: ${mediaItem.title} data to stats');

      recentList.insert(0, MediaItemMapper.toJSON(mediaItem));

      final jsonList = recentList.map((item) => jsonEncode(item)).toList();
      final uniqueJsonList = jsonList.toSet().toList();
      recentList = uniqueJsonList.map((item) => jsonDecode(item)).toList();

      if (recentList.length > 30) {
        recentList = recentList.sublist(0, 30);
      }
      playerBox.put(AppHiveConstants.recentSongs, recentList);
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

  }


}
