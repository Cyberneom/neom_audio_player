import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';

import '../domain/use_cases/neom_audio_handler.dart';
import '../ui/player/widgets/add_to_playlist.dart';
import '../ui/widgets/textinput_dialog.dart';
import 'constants/player_translation_constants.dart';

class MusicPlayerUtilities {

  static final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  ///DEPRECATED
  // static String getSubTitle(Map item) {
  //   AppUtilities.logger.e('Getting SubtTitle.');
  //   final type = item['type'];
  //   switch (type) {
  //     case 'charts':
  //       return '';
  //     case 'radio_station':
  //       return 'Radio • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle']?.toString().unescape()}';
  //     case 'playlist':
  //       return 'Playlist • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
  //     case 'song':
  //       return 'Single • ${item['artist']?.toString().unescape()}';
  //     case 'mix':
  //       return 'Mix • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
  //     case 'show':
  //       return 'Podcast • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
  //     case 'album':
  //       final artists = item['more_info']?['artistMap']?['artists'].map((artist) => artist['name']).toList();
  //       if (artists != null) {
  //         return 'Album • ${artists?.join(', ')?.toString().unescape()}';
  //       } else if (item['subtitle'] != null && item['subtitle'] != '') {
  //         return 'Album • ${item['subtitle']?.toString().unescape()}';
  //       }
  //       return 'Album';
  //     default:
  //       final artists = item['more_info']?['artistMap']?['artists']
  //           .map((artist) => artist['name'])
  //           .toList();
  //       return artists?.join(', ')?.toString().unescape() ?? '';
  //   }
  // }

  static Future<dynamic> setCounter(BuildContext context) async {
    showTextInputDialog(
      context: context,
      title: PlayerTranslationConstants.enterItemsCount.tr,
      initialText: '',
      keyboardType: TextInputType.number,
      onSubmitted: (String value, BuildContext context) {
        sleepCounter(
          int.parse(value),
        );
        Navigator.pop(context);
        AppUtilities.showSnackBar(
          message: '${PlayerTranslationConstants.sleepTimerSetFor.tr} $value ${PlayerTranslationConstants.mediaItems.tr}',
        );
      },
    );
  }

  static void sleepTimer(int time) {
    audioHandler.customAction('sleepTimer', {'time': time});
  }

  static void sleepCounter(int count) {
    audioHandler.customAction('sleepCounter', {'count': count});
  }

  static Future<dynamic> setTimer(BuildContext context, BuildContext? scaffoldContext, Duration time,) {
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
                      time = value;
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
                    sleepTimer(0);
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
                    sleepTimer(time.inMinutes);
                    Navigator.pop(context);
                    AppUtilities.showSnackBar(
                      message: '${PlayerTranslationConstants.sleepTimerSetFor.tr} ${time.inMinutes} ${PlayerTranslationConstants.minutes.tr}',
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

  static void onSelectedPopUpMenu(BuildContext context, int value, AppMediaItem appMediaItem, Duration time, {BuildContext? scaffoldContext}) {
    switch(value) {
      case 0:
        AddToPlaylist().addToPlaylist(context, appMediaItem);
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
                    setTimer(context, scaffoldContext, time,);
                  },
                ),
                ListTile(
                  title: Text(PlayerTranslationConstants.sleepAfter.tr,),
                  subtitle: Text(PlayerTranslationConstants.sleepAfterSub.tr,),
                  dense: true,
                  isThreeLine: true,
                  onTap: () {
                    Navigator.pop(context);
                    setCounter(context);
                  },
                ),
              ],
            );
          },
        );
      case 10:
        final Map details = appMediaItem.toJSON();
        details['duration'] = '${(int.parse(details["duration"].toString()) ~/ 60).toString().padLeft(2, "0")}'
            ':${(int.parse(details["duration"].toString()) % 60).toString().padLeft(2, "0")}';
        // style: Theme.of(context).textTheme.caption,
        showPopup(
          context: context,
          child: Container(
            color: AppColor.getMain(),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.keys.map((e) {
                  final String msg = '$e\n';
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
      default:
        break;
    }

  }

  static bool isOwnMediaItem(AppMediaItem appMediaItem) {
    final bool isOwnMediaItem = appMediaItem.url.contains(AppFlavour.getHubName())
        || appMediaItem.url.contains(AppFlavour.getStorageServerName())
        || appMediaItem.mediaSource == AppMediaSource.internal;

    return isOwnMediaItem;
  }

  static bool isInternal(String url) {
    final bool isInternal = url.contains(AppFlavour.getHubName())
        || url.contains(AppFlavour.getStorageServerName());
    return isInternal;
  }

  static void showSpeedSliderDialog({
    required BuildContext context,
    required String title,
    required int divisions,
    required double min,
    required double max,
    required NeomAudioHandler audioHandler,
    String valueSuffix = '',
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.main75,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: StreamBuilder<double>(
          stream: audioHandler.speed,
          builder: (context, snapshot) {
            double value = snapshot.data ?? audioHandler.speed.value;
            if (value > max) value = max;
            if (value < min) value = min;

            return SizedBox(
              height: 100.0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.minus),
                        onPressed: audioHandler.speed.value > min
                            ? () {
                          audioHandler
                              .setSpeed(audioHandler.speed.value - 0.1);
                        }
                            : null,
                      ),
                      Text(
                        '${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                        style: const TextStyle(
                          fontFamily: 'Fixed',
                          fontWeight: FontWeight.bold,
                          fontSize: 24.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.plus),
                        onPressed: audioHandler.speed.value < max
                            ? () {
                          audioHandler.setSpeed(audioHandler.speed.value + 0.1);
                        } : null,
                      ),
                    ],
                  ),
                  Slider(
                    inactiveColor: Theme.of(context).iconTheme.color!.withOpacity(0.4),
                    activeColor: Theme.of(context).iconTheme.color,
                    divisions: divisions,
                    min: min,
                    max: max,
                    value: value,
                    onChanged: audioHandler.setSpeed,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static void showPopup({
    required BuildContext context,
    required Widget child,
    double radius = 20.0,
    Color? backColor,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          backgroundColor: AppColor.main75,
          content: Stack(
            children: [
              GestureDetector(onTap: () => Navigator.pop(context)),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Card(
                  elevation: 0.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  clipBehavior: Clip.antiAlias,
                  color: backColor,
                  child: child,
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Card(
                  elevation: 15.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


}
