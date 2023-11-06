import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../../../../utils/constants/app_hive_constants.dart';
import '../../../../utils/constants/music_player_constants.dart';
import '../../../../utils/constants/player_translation_constants.dart';
import '../../../widgets/box_switch_tile.dart';

class MusicPlaybackSettingsPage extends StatefulWidget {
  final Function? callback;
  const MusicPlaybackSettingsPage({super.key, this.callback});

  @override
  State<MusicPlaybackSettingsPage> createState() => _MusicPlaybackSettingsPageState();
}

class _MusicPlaybackSettingsPageState extends State<MusicPlaybackSettingsPage> {
  String streamingMobileQuality = Hive.box(AppHiveConstants.settings).get('streamingQuality', defaultValue: '96 kbps') as String;
  String streamingWifiQuality = Hive.box(AppHiveConstants.settings).get('streamingWifiQuality', defaultValue: '320 kbps') as String;
  String region = Hive.box(AppHiveConstants.settings).get('region', defaultValue: 'México') as String;

  List preferredLanguage = Hive.box(AppHiveConstants.settings).get('preferredLanguage', defaultValue: ['Español'])?.toList() as List;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColor.main50,
        appBar: AppBarChild(title: PlayerTranslationConstants.musicPlayback.tr,),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(10.0),
            children: [
              ListTile(
                title: Text(PlayerTranslationConstants.musicLang.tr,),
                subtitle: Text(PlayerTranslationConstants.musicLangSub.tr,),
                trailing: SizedBox(
                  width: 150,
                  child: Text(preferredLanguage.isEmpty ? 'None' : preferredLanguage.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
                dense: true,
                onTap: () {
                  showModalBottomSheet(
                    isDismissible: true,
                    backgroundColor: AppColor.getMain(),
                    context: context,
                    builder: (BuildContext context) {
                      final List checked = List.from(preferredLanguage);
                      return StatefulBuilder(
                        builder: (
                          BuildContext context,
                          StateSetter setStt,
                        ) {
                          return Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(vertical:10),
                                  itemCount: MusicPlayerConstants.musicLanguages.length,
                                  itemBuilder: (context, idx) {
                                    return CheckboxListTile(
                                      activeColor: Theme.of(context).colorScheme.secondary,
                                      checkColor: Theme.of(context).colorScheme.secondary == Colors.white
                                          ? Colors.black : null,
                                      value: checked.contains(MusicPlayerConstants.musicLanguages[idx],),
                                      title: Text(MusicPlayerConstants.musicLanguages[idx],),
                                      onChanged: (bool? value) {
                                        value!
                                            ? checked.add(MusicPlayerConstants.musicLanguages[idx])
                                            : checked.remove(
                                          MusicPlayerConstants.musicLanguages[idx],
                                        );
                                        setState(() {});
                                      },
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.secondary,),
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(PlayerTranslationConstants.cancel.tr,),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.secondary,),
                                    onPressed: () {
                                      setState(() {
                                        preferredLanguage = checked;
                                        Navigator.pop(context);
                                        Hive.box(AppHiveConstants.settings).put('preferredLanguage', checked,);
                                        //TODO VERIFY FUNCTIONALITY
                                        // widget.fetched = false;
                                        // widget.preferredLanguage = preferredLanguage;
                                        widget.callback!();
                                        },
                                      );
                                      if(preferredLanguage.isEmpty) {
                                        AppUtilities.showSnackBar(
                                          message: PlayerTranslationConstants.noLangSelected.tr,
                                        );
                                      }
                                    },
                                    child: Text(PlayerTranslationConstants.ok.tr.toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.w600,),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              ///VERIFY IF NEEDED WITHOUT SPOTIFY. USEFUL WHEN HAVING UPLOADED SONGS AROUND THE GLOBE
              // ListTile(
              //   title: Text(PlayerTranslationConstants.chartLocation.tr,),
              //   subtitle: Text(PlayerTranslationConstants.chartLocationSub.tr,),
              //   trailing: SizedBox(
              //     width: 150,
              //     child: Text(region,
              //       textAlign: TextAlign.end,
              //     ),
              //   ),
              //   dense: true,
              //   onTap: () async {
              //     region = await SpotifyHiveController().changeCountry(context: context);
              //     setState(
              //       () {},
              //     );
              //   },
              // ),
              ListTile(
                title: Text(PlayerTranslationConstants.streamQuality.tr,),
                subtitle: Text(PlayerTranslationConstants.streamQualitySub.tr,),
                onTap: () {},
                trailing: DropdownButton(
                  dropdownColor: AppColor.getMain(),
                  value: streamingMobileQuality,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
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
                  dropdownColor: AppColor.getMain(),
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
              HiveBoxSwitchTile(
                title: Text(PlayerTranslationConstants.loadLast.tr,),
                subtitle: Text(PlayerTranslationConstants.loadLastSub.tr,),
                keyName: 'loadStart',
                defaultValue: true,
              ),
              HiveBoxSwitchTile(
                title: Text(PlayerTranslationConstants.resetOnSkip.tr,),
                subtitle: Text(PlayerTranslationConstants.resetOnSkipSub.tr,),
                keyName: 'resetOnSkip',
                defaultValue: false,
              ),
              HiveBoxSwitchTile(
                title: Text(PlayerTranslationConstants.enforceRepeat.tr,),
                subtitle: Text(PlayerTranslationConstants.enforceRepeatSub.tr,),
                keyName: 'enforceRepeat',
                defaultValue: false,
              ),
              HiveBoxSwitchTile(
                title: Text(PlayerTranslationConstants.autoplay.tr,),
                subtitle: Text(PlayerTranslationConstants.autoplaySub.tr,),
                keyName: 'autoplay',
                defaultValue: true,
                isThreeLine: true,
              ),
              HiveBoxSwitchTile(
                title: Text(PlayerTranslationConstants.cacheSong.tr,),
                subtitle: Text(PlayerTranslationConstants.cacheSongSub.tr,),
                keyName: 'cacheSong',
                defaultValue: true,
              ),
            ],
        ),
      ),
    );
  }

}
