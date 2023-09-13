import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/data/implementations/spotify_hive_controller.dart';
import 'package:neom_music_player/ui/widgets/box_switch_tile.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/music_player_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:get/get.dart';

class MusicPlaybackPage extends StatefulWidget {
  final Function? callback;
  const MusicPlaybackPage({this.callback});

  @override
  State<MusicPlaybackPage> createState() => _MusicPlaybackPageState();
}

class _MusicPlaybackPageState extends State<MusicPlaybackPage> {
  String streamingMobileQuality = Hive.box(AppHiveConstants.settings).get('streamingQuality', defaultValue: '96 kbps') as String;
  String streamingWifiQuality = Hive.box(AppHiveConstants.settings).get('streamingWifiQuality', defaultValue: '320 kbps') as String;
  // String ytQuality = Hive.box(AppHiveConstants.settings).get('ytQuality', defaultValue: 'Low') as String;
  String region = Hive.box(AppHiveConstants.settings).get('region', defaultValue: 'México') as String;

  List preferredLanguage = Hive.box(AppHiveConstants.settings).get('preferredLanguage', defaultValue: ['Español'])?.toList() as List;

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: AppColor.main75,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColor.main75,
          centerTitle: true,
          title: Text(
            PlayerTranslationConstants.musicPlayback.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(10.0),
          children: [
            ListTile(
              title: Text(
                PlayerTranslationConstants.musicLang.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.musicLangSub.tr,
              ),
              trailing: SizedBox(
                width: 150,
                child: Text(
                  preferredLanguage.isEmpty
                      ? 'None'
                      : preferredLanguage.join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
              dense: true,
              onTap: () {
                showModalBottomSheet(
                  isDismissible: true,
                  backgroundColor: AppColor.main75,
                  context: context,
                  builder: (BuildContext context) {
                    final List checked = List.from(preferredLanguage);
                    return StatefulBuilder(
                      builder: (
                        BuildContext context,
                        StateSetter setStt,
                      ) {
                        return BottomGradientContainer(
                          borderRadius: BorderRadius.circular(
                            20.0,
                          ),
                          hasOpacity: true,
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    10,
                                    0,
                                    10,
                                  ),
                                  itemCount: MusicPlayerConstants.musicLanguages.length,
                                  itemBuilder: (context, idx) {
                                    return CheckboxListTile(
                                      activeColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      checkColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary ==
                                              Colors.white
                                          ? Colors.black
                                          : null,
                                      value: checked.contains(
                                        MusicPlayerConstants.musicLanguages[idx],
                                      ),
                                      title: Text(
                                        MusicPlayerConstants.musicLanguages[idx],
                                      ),
                                      onChanged: (bool? value) {
                                        value!
                                            ? checked.add(MusicPlayerConstants.musicLanguages[idx])
                                            : checked.remove(
                                          MusicPlayerConstants.musicLanguages[idx],
                                              );
                                        setStt(
                                          () {},
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      PlayerTranslationConstants.cancel.tr,
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () {
                                          preferredLanguage = checked;
                                          Navigator.pop(context);
                                          Hive.box(AppHiveConstants.settings).put('preferredLanguage', checked,);
                                          //TODO VERIFY FUNCTIONALITY
                                          // widget.fetched = false;
                                          // widget.preferredLanguage = preferredLanguage;
                                          widget.callback!();
                                        },
                                      );
                                      if (preferredLanguage.isEmpty) {
                                        ShowSnackBar().showSnackBar(
                                          context,
                                          PlayerTranslationConstants.noLangSelected.tr,
                                        );
                                      }
                                    },
                                    child: Text(
                                      PlayerTranslationConstants.ok.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            ListTile(
              title: Text(
                PlayerTranslationConstants.chartLocation.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.chartLocationSub.tr,
              ),
              trailing: SizedBox(
                width: 150,
                child: Text(
                  region,
                  textAlign: TextAlign.end,
                ),
              ),
              dense: true,
              onTap: () async {
                region = await SpotifyHiveController().changeCountry(context: context);
                setState(
                  () {},
                );
              },
            ),
            ListTile(
              title: Text(
                PlayerTranslationConstants.streamQuality.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.streamQualitySub.tr,
              ),
              onTap: () {},
              trailing: DropdownButton(
                value: streamingMobileQuality,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(
                      () {
                        streamingMobileQuality = newValue;
                        Hive.box(AppHiveConstants.settings).put('streamingQuality', newValue);
                      },
                    );
                  }
                },
                items: <String>['96 kbps', '160 kbps', '320 kbps']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              dense: true,
            ),
            ListTile(
              title: Text(
                PlayerTranslationConstants.streamWifiQuality.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.streamWifiQualitySub.tr,
              ),
              onTap: () {},
              trailing: DropdownButton(
                value: streamingWifiQuality,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(
                      () {
                        streamingWifiQuality = newValue;
                        Hive.box(AppHiveConstants.settings)
                            .put('streamingWifiQuality', newValue);
                      },
                    );
                  }
                },
                items: <String>['96 kbps', '160 kbps', '320 kbps']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              dense: true,
            ),
            // ListTile(
            //   title: Text(
            //     PlayerTranslationConstants.ytStreamQuality.tr,
            //   ),
            //   subtitle: Text(
            //     PlayerTranslationConstants.ytStreamQualitySub.tr,
            //   ),
            //   onTap: () {},
            //   trailing: DropdownButton(
            //     value: ytQuality,
            //     style: TextStyle(
            //       fontSize: 12,
            //       color: Theme.of(context).textTheme.bodyLarge!.color,
            //     ),
            //     underline: const SizedBox(),
            //     onChanged: (String? newValue) {
            //       if (newValue != null) {
            //         setState(
            //           () {
            //             ytQuality = newValue;
            //             Hive.box(AppHiveConstants.settings).put('ytQuality', newValue);
            //           },
            //         );
            //       }
            //     },
            //     items: <String>['Low', 'High']
            //         .map<DropdownMenuItem<String>>((String value) {
            //       return DropdownMenuItem<String>(
            //         value: value,
            //         child: Text(value),
            //       );
            //     }).toList(),
            //   ),
            //   dense: true,
            // ),
            BoxSwitchTile(
              title: Text(
                PlayerTranslationConstants.loadLast.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.loadLastSub.tr,
              ),
              keyName: 'loadStart',
              defaultValue: true,
            ),
            BoxSwitchTile(
              title: Text(
                PlayerTranslationConstants.resetOnSkip.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.resetOnSkipSub.tr,
              ),
              keyName: 'resetOnSkip',
              defaultValue: false,
            ),
            BoxSwitchTile(
              title: Text(
                PlayerTranslationConstants.enforceRepeat.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.enforceRepeatSub.tr,
              ),
              keyName: 'enforceRepeat',
              defaultValue: false,
            ),
            BoxSwitchTile(
              title: Text(
                PlayerTranslationConstants.autoplay.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.autoplaySub.tr,
              ),
              keyName: 'autoplay',
              defaultValue: true,
              isThreeLine: true,
            ),
            BoxSwitchTile(
              title: Text(
                PlayerTranslationConstants.cacheSong.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.cacheSongSub.tr,
              ),
              keyName: 'cacheSong',
              defaultValue: true,
            ),
          ],
        ),
      ),
    );
  }
}
