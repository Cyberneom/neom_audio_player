import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/ui/widgets/add_playlist.dart';
import 'package:neom_music_player/ui/widgets/popup.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/ui/widgets/song_list.dart';
import 'package:neom_music_player/ui/widgets/textinput_dialog.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:neom_music_player/utils/helpers/extensions.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/domain/use_cases/youtube_services.dart';
import 'package:get/get.dart';
import 'package:neom_music_player/utils/helpers/media_item_mapper.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicPlayerUtilities {

  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  static Future<AppMediaItem> refreshYtLink(AppMediaItem playItem) async {
    // final bool cacheSong = Hive.box(AppHiveConstants.settings).get('cacheSong', defaultValue: true) as bool;
    final int expiredAt = playItem.expireAt ?? 0;
    if ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 350 > expiredAt) {
      AppUtilities.logger.i('Before service | youtube link expired for ${playItem.name}',);
      if (Hive.box(AppHiveConstants.ytLinkCache).containsKey(playItem.id)) {
        final Map cache = await Hive.box(AppHiveConstants.ytLinkCache).get(playItem.id) as Map;
        final int expiredAt = int.parse((cache['expire_at'] ?? '0').toString());

        if ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 350 > expiredAt) {
          AppUtilities.logger.i('youtube link expired in cache for ${playItem.name}');
          AppMediaItem? newMediaItem = await YouTubeServices().refreshLink(playItem.id);
          AppUtilities.logger.i(
            'before service | received new link for ${playItem.name}',
          );
          if (newMediaItem != null) {
            playItem.url = newMediaItem.url;
            playItem.duration = newMediaItem.duration;
            playItem.expireAt = newMediaItem.expireAt;
          }
        } else {
          AppUtilities.logger.i('youtube link found in cache for ${playItem.name}');
          playItem.url = cache['url'].toString();
          playItem.expireAt = int.parse(cache['expire_at'].toString());
        }
      } else {
        final newData = await YouTubeServices().refreshLink(playItem.id);
        AppUtilities.logger.i('before service | received new link for ${playItem.name}',);
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

  Future<dynamic> setCounter(BuildContext context) async {
    showTextInputDialog(
      context: context,
      title: PlayerTranslationConstants.enterSongsCount.tr,
      initialText: '',
      keyboardType: TextInputType.number,
      onSubmitted: (String value, BuildContext context) {
        sleepCounter(
          int.parse(value),
        );
        Navigator.pop(context);
        ShowSnackBar().showSnackBar(
          context,
          '${PlayerTranslationConstants.sleepTimerSetFor.tr} $value ${PlayerTranslationConstants.songs.tr}',
        );
      },
    );
  }

  void sleepTimer(int time) {
    audioHandler.customAction('sleepTimer', {'time': time});
  }

  void sleepCounter(int count) {
    audioHandler.customAction('sleepCounter', {'count': count});
  }

  Future<dynamic> setTimer(
      BuildContext context,
      BuildContext? scaffoldContext,
      Duration _time,
      ) {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: AppColor.getMain(),
          title: Center(
            child: Text(
              PlayerTranslationConstants.selectDur.tr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          children: [
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    primaryColor: Theme.of(context).colorScheme.secondary,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    onTimerDurationChanged: (value) {
                      _time = value;
                    },

                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    MusicPlayerUtilities().sleepTimer(0);
                    Navigator.pop(context);
                  },
                  child: Text(PlayerTranslationConstants.cancel.tr),
                ),
                const SizedBox(width: 10,),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColor.bondiBlue,
                    foregroundColor: Theme.of(context).colorScheme.secondary == Colors.white
                        ? Colors.black : Colors.white,
                  ),
                  onPressed: () {
                    MusicPlayerUtilities().sleepTimer(_time.inMinutes);
                    Navigator.pop(context);
                    ShowSnackBar().showSnackBar(
                      context,
                      '${PlayerTranslationConstants.sleepTimerSetFor.tr} ${_time.inMinutes} ${PlayerTranslationConstants.minutes.tr}',
                    );
                  },
                  child: Text(PlayerTranslationConstants.ok.tr.toUpperCase()),
                ),
                const SizedBox(width: 20,),
              ],
            ),
          ],
        );
      },
    );
  }

  static void onSelectedPopUpMenu(BuildContext context, int value, AppMediaItem appMediaItem, Duration _time, {BuildContext? scaffoldContext}) {
    switch(value) {
      case 0:
        AddToPlaylist().addToPlaylist(context, appMediaItem);
        break;
      case 1:
        showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
              backgroundColor: AppColor.main75,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: Text(
                PlayerTranslationConstants.sleepTimer.tr,
                style: TextStyle(
                  color:
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
              contentPadding: const EdgeInsets.all(10.0),
              children: [
                ListTile(
                  title: Text(
                    PlayerTranslationConstants.sleepDur.tr,
                  ),
                  subtitle: Text(
                    PlayerTranslationConstants.sleepDurSub.tr,
                  ),
                  dense: true,
                  onTap: () {
                    Navigator.pop(context);
                    MusicPlayerUtilities().setTimer(
                        context,
                        scaffoldContext,
                        _time
                    );
                  },
                ),
                ListTile(
                  title: Text(
                    PlayerTranslationConstants.sleepAfter.tr,
                  ),
                  subtitle: Text(
                    PlayerTranslationConstants.sleepAfterSub.tr,
                  ),
                  dense: true,
                  isThreeLine: true,
                  onTap: () {
                    Navigator.pop(context);
                    MusicPlayerUtilities().setCounter(context);
                  },
                ),
              ],
            );
          },
        );
        break;
      case 10:
        final Map details = appMediaItem.toJSON();
        details['duration'] = '${(int.parse(details["duration"].toString()) ~/ 60).toString().padLeft(2, "0")}:${(int.parse(details["duration"].toString()) % 60).toString().padLeft(2, "0")}';
        // style: Theme.of(context).textTheme.caption,
        PopupDialog().showPopup(
          context: context,
          child: Container(
            color: AppColor.getMain(),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.keys.map((e) {
                  String msg = '$e\n';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SelectableText.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(text: '${msg[0].toUpperCase()}${msg.substring(1)}'.replaceAll('_', ' '),
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 15,
                              color: Theme.of(context).textTheme.bodySmall!.color,
                            ),
                          ),
                          TextSpan(text: '${details[e]}',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      showCursor: true,
                      cursorColor: Colors.black,
                      cursorRadius: const Radius.circular(5),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
        break;
    // case 5:
    //   Navigator.push(
    //     context,
    //     PageRouteBuilder(
    //       opaque: false,
    //       pageBuilder: (_, __, ___) => SongsListPage(
    //           itemlist: Itemlist()
    //         //TODO TO VERIFY
    //         // {
    //         //   'type': 'album',
    //         //   'id': mediaItem.extras?['album_id'],
    //         //   'title': mediaItem.album,
    //         //   'image': mediaItem.artUri,
    //         // },
    //       ),
    //     ),
    //   );
    //   break;
    // case 3:
    //   launchUrl(
    //     Uri.parse(
    //       appMediaItem.genre == 'YouTube'
    //           ? 'https://youtube.com/watch?v=${appMediaItem.id}'
    //           : 'https://www.youtube.com/results?search_query=${appMediaItem.name} by ${appMediaItem.artist}',
    //     ),
    //     mode: LaunchMode.externalApplication,
    //   );
    //   break;
      default:
        break;
    }

  }
}