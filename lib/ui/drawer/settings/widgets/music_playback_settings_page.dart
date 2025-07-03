import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/commons/app_flavour.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/commons/utils/app_utilities.dart';
import 'package:neom_core/core/utils/enums/app_hive_box.dart';
import 'package:neom_core/core/utils/enums/app_in_use.dart';
import 'package:neom_media_player/utils/constants/player_translation_constants.dart';

import '../../../../utils/constants/audio_player_constants.dart';
import 'hive_box_switch_tile.dart';

class MusicPlaybackSettingsPage extends StatefulWidget {
  final Function? callback;
  const MusicPlaybackSettingsPage({super.key, this.callback});

  @override
  State<MusicPlaybackSettingsPage> createState() => _MusicPlaybackSettingsPageState();
}

class _MusicPlaybackSettingsPageState extends State<MusicPlaybackSettingsPage> {
  String streamingMobileQuality = Hive.box(AppHiveBox.settings.name).get('streamingQuality', defaultValue: '96 kbps') as String;
  String streamingWifiQuality = Hive.box(AppHiveBox.settings.name).get('streamingWifiQuality', defaultValue: '320 kbps') as String;
  String region = Hive.box(AppHiveBox.settings.name).get('region', defaultValue: 'México') as String;

  List preferredLanguage = Hive.box(AppHiveBox.settings.name).get('preferredLanguage', defaultValue: ['Español'])?.toList() as List;

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
              if(AppFlavour.appInUse == AppInUse.g) ListTile(
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
                                  itemCount: AudioPlayerConstants.musicLanguages.length,
                                  itemBuilder: (context, idx) {
                                    return CheckboxListTile(
                                      activeColor: Theme.of(context).colorScheme.secondary,
                                      checkColor: Theme.of(context).colorScheme.secondary == Colors.white
                                          ? Colors.black : null,
                                      value: checked.contains(AudioPlayerConstants.musicLanguages[idx],),
                                      title: Text(AudioPlayerConstants.musicLanguages[idx],),
                                      onChanged: (bool? value) {
                                        value!
                                            ? checked.add(AudioPlayerConstants.musicLanguages[idx])
                                            : checked.remove(
                                          AudioPlayerConstants.musicLanguages[idx],
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
                                        Hive.box(AppHiveBox.settings.name).put('preferredLanguage', checked,);
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
                  underline: const SizedBox.shrink(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                          streamingMobileQuality = newValue;
                          Hive.box(AppHiveBox.settings.name).put('streamingQuality', newValue);
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
                  underline: const SizedBox.shrink(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(
                        () {
                          streamingWifiQuality = newValue;
                          Hive.box(AppHiveBox.settings.name)
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
                title: PlayerTranslationConstants.loadLast.tr,
                subtitle: PlayerTranslationConstants.loadLastSub.tr,
                keyName: 'loadStart',
                defaultValue: true,
              ),
              HiveBoxSwitchTile(
                title: PlayerTranslationConstants.resetOnSkip.tr,
                subtitle: PlayerTranslationConstants.resetOnSkipSub.tr,
                keyName: 'resetOnSkip',
                defaultValue: false,
              ),
              HiveBoxSwitchTile(
                title: PlayerTranslationConstants.enforceRepeat.tr,
                subtitle: PlayerTranslationConstants.enforceRepeatSub.tr,
                keyName: 'enforceRepeat',
                defaultValue: false,
              ),
              // HiveBoxSwitchTile(
              //   title: PlayerTranslationConstants.autoplay.tr,
              //   subtitle: PlayerTranslationConstants.autoplaySub.tr,
              //   keyName: 'autoplay',
              //   defaultValue: true,
              //   isThreeLine: true,
              // ),
              HiveBoxSwitchTile(
                title: PlayerTranslationConstants.cacheMediaItem.tr,
                subtitle: PlayerTranslationConstants.cacheMediaItemSub.tr,
                keyName: 'cacheSong',
                defaultValue: true,
              ),
            ],
        ),
      ),
    );
  }

}
