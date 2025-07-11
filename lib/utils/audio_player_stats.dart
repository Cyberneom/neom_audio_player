import 'dart:convert';

import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

class AudioPlayerStats {

  static Future<void> addRecentlyPlayed(AppMediaItem appMediaItem) async {
    AppConfig.logger.d('Adding ${appMediaItem.id} to recently played');

    try {
      final playerBox = await AppHiveController().getBox(AppHiveBox.player.name);
      final statsBox = await AppHiveController().getBox(AppHiveBox.stats.name);

      List recentList = await playerBox.get(AppHiveConstants.recentSongs, defaultValue: [])?.toList() as List;
      final Map songStats = await statsBox.get(appMediaItem.id, defaultValue: {}) as Map;
      final Map mostPlayed = await statsBox.get(AppHiveConstants.mostPlayed, defaultValue: {}) as Map;

      songStats[AppHiveConstants.lastPlayed] = DateTime.now().millisecondsSinceEpoch;
      songStats[AppHiveConstants.playCount] = songStats[AppHiveConstants.playCount] == null ? 1 : songStats[AppHiveConstants.playCount] + 1;
      songStats[AppHiveConstants.title] = appMediaItem.name;
      songStats[AppHiveConstants.artist] = appMediaItem.artist;
      songStats[AppHiveConstants.album] = appMediaItem.album;
      songStats[AppHiveConstants.id] = appMediaItem.id;
      statsBox.put(appMediaItem.id, songStats);

      if ((songStats[AppHiveConstants.playCount] as int) > (mostPlayed[AppHiveConstants.playCount] as int? ?? 0)) {
        statsBox.put(AppHiveConstants.mostPlayed, songStats);
      }
      AppConfig.logger.i('Adding mediaItemId: ${appMediaItem.id} Name: ${appMediaItem.name} data to stats');

      recentList.insert(0, appMediaItem.toJSON());

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
