import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'constants/app_hive_constants.dart';

class MusicPlayerStats {

  static Future<void> addRecentlyPlayed(AppMediaItem appMediaItem) async {
    AppUtilities.logger.d('Adding ${appMediaItem.id} to recently played');

    try {
      List recentList = await Hive.box(AppHiveConstants.cache).get('recentSongs', defaultValue: [])?.toList() as List;
      final Map songStats = await Hive.box(AppHiveConstants.stats).get(appMediaItem.id, defaultValue: {}) as Map;
      final Map mostPlayed = await Hive.box(AppHiveConstants.stats).get('mostPlayed', defaultValue: {}) as Map;

      songStats['lastPlayed'] = DateTime.now().millisecondsSinceEpoch;
      songStats['playCount'] = songStats['playCount'] == null ? 1 : songStats['playCount'] + 1;
      songStats['isYoutube'] = appMediaItem.genre == 'YouTube';
      songStats['title'] = appMediaItem.name;
      songStats['artist'] = appMediaItem.artist;
      songStats['album'] = appMediaItem.album;
      songStats['id'] = appMediaItem.id;
      Hive.box(AppHiveConstants.stats).put(appMediaItem.id, songStats);

      if ((songStats['playCount'] as int) > (mostPlayed['playCount'] as int? ?? 0)) {
        Hive.box(AppHiveConstants.stats).put('mostPlayed', songStats);
      }
      AppUtilities.logger.i('Adding ${appMediaItem.id} ${appMediaItem.name} data to stats');

      recentList.insert(0, appMediaItem.toJSON());

      final jsonList = recentList.map((item) => jsonEncode(item)).toList();
      final uniqueJsonList = jsonList.toSet().toList();
      recentList = uniqueJsonList.map((item) => jsonDecode(item)).toList();

      if (recentList.length > 30) {
        recentList = recentList.sublist(0, 30);
      }
      Hive.box(AppHiveConstants.cache).put('recentSongs', recentList);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

  }


}
