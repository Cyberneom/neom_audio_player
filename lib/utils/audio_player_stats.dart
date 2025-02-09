import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_hive_constants.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';
class AudioPlayerStats {

  static Future<void> addRecentlyPlayed(AppMediaItem appMediaItem) async {
    AppUtilities.logger.d('Adding ${appMediaItem.id} to recently played');

    try {
      List recentList = await Hive.box(AppHiveBox.player.name).get(AppHiveConstants.recentSongs, defaultValue: [])?.toList() as List;
      final Map songStats = await Hive.box(AppHiveBox.stats.name).get(appMediaItem.id, defaultValue: {}) as Map;
      final Map mostPlayed = await Hive.box(AppHiveBox.stats.name).get(AppHiveConstants.mostPlayed, defaultValue: {}) as Map;

      songStats[AppHiveConstants.lastPlayed] = DateTime.now().millisecondsSinceEpoch;
      songStats[AppHiveConstants.playCount] = songStats[AppHiveConstants.playCount] == null ? 1 : songStats[AppHiveConstants.playCount] + 1;
      songStats[AppHiveConstants.title] = appMediaItem.name;
      songStats[AppHiveConstants.artist] = appMediaItem.artist;
      songStats[AppHiveConstants.album] = appMediaItem.album;
      songStats[AppHiveConstants.id] = appMediaItem.id;
      Hive.box(AppHiveBox.stats.name).put(appMediaItem.id, songStats);

      if ((songStats[AppHiveConstants.playCount] as int) > (mostPlayed[AppHiveConstants.playCount] as int? ?? 0)) {
        Hive.box(AppHiveBox.stats.name).put(AppHiveConstants.mostPlayed, songStats);
      }
      AppUtilities.logger.i('Adding mediaItemId: ${appMediaItem.id} Name: ${appMediaItem.name} data to stats');

      recentList.insert(0, appMediaItem.toJSON());

      final jsonList = recentList.map((item) => jsonEncode(item)).toList();
      final uniqueJsonList = jsonList.toSet().toList();
      recentList = uniqueJsonList.map((item) => jsonDecode(item)).toList();

      if (recentList.length > 30) {
        recentList = recentList.sublist(0, 30);
      }
      Hive.box(AppHiveBox.player.name).put(AppHiveConstants.recentSongs, recentList);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

  }


}
