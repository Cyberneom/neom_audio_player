import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/ui/widgets/box_switch_tile.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/ui/home/saavn.dart' as home_screen;
import 'package:neom_music_player/ui/spotify/spotify_top_page.dart' as top_screen;
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/countrycodes.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:get/get.dart';

class MusicPlaybackPage extends StatefulWidget {
  final Function? callback;
  const MusicPlaybackPage({this.callback});

  @override
  State<MusicPlaybackPage> createState() => _MusicPlaybackPageState();
}

class _MusicPlaybackPageState extends State<MusicPlaybackPage> {
  String streamingMobileQuality = Hive.box('settings')
      .get('streamingQuality', defaultValue: '96 kbps') as String;
  String streamingWifiQuality = Hive.box('settings')
      .get('streamingWifiQuality', defaultValue: '320 kbps') as String;
  String ytQuality =
      Hive.box(AppHiveConstants.settings).get('ytQuality', defaultValue: 'Low') as String;
  String region =
      Hive.box(AppHiveConstants.settings).get('region', defaultValue: 'México') as String;
  List<String> languages = [
    'Hindi',
    'English',
    'Punjabi',
    'Tamil',
    'Telugu',
    'Marathi',
    'Gujarati',
    'Bengali',
    'Kannada',
    'Bhojpuri',
    'Malayalam',
    'Urdu',
    'Haryanvi',
    'Rajasthani',
    'Odia',
    'Assamese'
  ];
  List preferredLanguage = Hive.box('settings')
      .get('preferredLanguage', defaultValue: ['Hindi'])?.toList() as List;

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
                                  itemCount: languages.length,
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
                                        languages[idx],
                                      ),
                                      title: Text(
                                        languages[idx],
                                      ),
                                      onChanged: (bool? value) {
                                        value!
                                            ? checked.add(languages[idx])
                                            : checked.remove(
                                                languages[idx],
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
                                          Hive.box(AppHiveConstants.settings).put(
                                            'preferredLanguage',
                                            checked,
                                          );
                                          home_screen.fetched = false;
                                          home_screen.preferredLanguage =
                                              preferredLanguage;
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
                region = await SpotifyCountry().changeCountry(context: context);
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
                        Hive.box('settings')
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
            ListTile(
              title: Text(
                PlayerTranslationConstants.ytStreamQuality.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.ytStreamQualitySub.tr,
              ),
              onTap: () {},
              trailing: DropdownButton(
                value: ytQuality,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(
                      () {
                        ytQuality = newValue;
                        Hive.box(AppHiveConstants.settings).put('ytQuality', newValue);
                      },
                    );
                  }
                },
                items: <String>['Low', 'High']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              dense: true,
            ),
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

class SpotifyCountry {
  Future<String> changeCountry({required BuildContext context}) async {
    String region =
        Hive.box(AppHiveConstants.settings).get('region', defaultValue: 'México') as String;
    if (!CountryCodes.localChartCodes.containsKey(region)) {
      region = 'India';
    }

    await showModalBottomSheet(
      isDismissible: true,
      backgroundColor: AppColor.main75,
      context: context,
      builder: (BuildContext context) {
        const Map<String, String> codes = CountryCodes.localChartCodes;
        final List<String> countries = codes.keys.toList();
        return BottomGradientContainer(
          borderRadius: BorderRadius.circular(
            20.0,
          ),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              0,
              10,
              0,
              10,
            ),
            itemCount: countries.length,
            itemBuilder: (context, idx) {
              return ListTileTheme(
                selectedColor: Theme.of(context).colorScheme.secondary,
                child: ListTile(
                  title: Text(
                    countries[idx],
                  ),
                  leading: Radio(
                    value: countries[idx],
                    groupValue: region,
                    onChanged: (value) {
                      top_screen.localSongs = [];
                      region = countries[idx];
                      top_screen.localFetched = false;
                      top_screen.localFetchFinished.value = false;
                      Hive.box(AppHiveConstants.settings).put('region', region);
                      Navigator.pop(context);
                    },
                  ),
                  selected: region == countries[idx],
                  onTap: () {
                    top_screen.localSongs = [];
                    region = countries[idx];
                    top_screen.localFetchFinished.value = false;
                    Hive.box(AppHiveConstants.settings).put('region', region);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        );
      },
    );
    return region;
  }
}
