import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_music_player/data/implementations/app_hive_controller.dart';
import 'package:neom_music_player/domain/entities/app_media_item.dart';
import 'package:neom_music_player/utils/helpers/extensions.dart';
import 'package:neom_music_player/utils/helpers/media_item_mapper.dart';
import 'package:neom_music_player/domain/entities/youtube_item.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/domain/use_cases/youtube_services.dart';
import 'package:neom_music_player/ui/player/audioplayer.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

class MusicPlayerUtilities {

  static Future<AppMediaItem> refreshYtLink(AppMediaItem playItem) async {
    // final bool cacheSong = Hive.box(AppHiveConstants.settings).get('cacheSong', defaultValue: true) as bool;
    final int expiredAt = playItem.expireAt ?? 0;
    if ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 350 > expiredAt) {
      AppUtilities.logger.i('Before service | youtube link expired for ${playItem.title}',);
      if (Hive.box(AppHiveConstants.ytLinkCache).containsKey(playItem.id)) {
        final Map cache = await Hive.box(AppHiveConstants.ytLinkCache).get(playItem.id) as Map;
        final int expiredAt = int.parse((cache['expire_at'] ?? '0').toString());

        if ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 350 > expiredAt) {
          AppUtilities.logger.i('youtube link expired in cache for ${playItem.title}');
          AppMediaItem? newMediaItem = await YouTubeServices().refreshLink(playItem.id);
          AppUtilities.logger.i(
            'before service | received new link for ${playItem.title}',
          );
          if (newMediaItem != null) {
            playItem.url = newMediaItem.url;
            playItem.duration = newMediaItem.duration;
            playItem.expireAt = newMediaItem.expireAt;
          }
        } else {
          AppUtilities.logger.i('youtube link found in cache for ${playItem.title}');
          playItem.url = cache['url'].toString();
          playItem.expireAt = int.parse(cache['expire_at'].toString());
        }
      } else {
        final newData = await YouTubeServices().refreshLink(playItem.id);
        AppUtilities.logger.i('before service | received new link for ${playItem.title}',);
        if (newData != null) {
          playItem.url = newData.url;
          playItem.duration = newData.duration;
          playItem.expireAt = newData.expireAt;
        }
      }
    }

    return playItem;
  }

  String getSubTitle(Map item) {
    AppUtilities.logger.e("Getting SubtTitle.");
    final type = item['type'];
    switch (type) {
      case 'charts':
        return '';
      case 'radio_station':
        return 'Radio • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle']?.toString().unescape()}';
      case 'playlist':
        return 'Playlist • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'song':
        return 'Single • ${item['artist']?.toString().unescape()}';
      case 'mix':
        return 'Mix • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'show':
        return 'Podcast • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'album':
        final artists = item['more_info']?['artistMap']?['artists'].map((artist) => artist['name']).toList();
        if (artists != null) {
          return 'Album • ${artists?.join(', ')?.toString().unescape()}';
        } else if (item['subtitle'] != null && item['subtitle'] != '') {
          return 'Album • ${item['subtitle']?.toString().unescape()}';
        }
        return 'Album';
      default:
        final artists = item['more_info']?['artistMap']?['artists']
            .map((artist) => artist['name'])
            .toList();
        return artists?.join(', ')?.toString().unescape() ?? '';
    }
  }

}