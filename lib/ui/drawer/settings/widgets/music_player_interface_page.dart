import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

import '../../../../utils/constants/audio_player_constants.dart';
import '../../../../utils/constants/audio_player_translation_constants.dart';
import 'hive_box_switch_tile.dart';

class MusicPlayerInterfacePage extends StatefulWidget {
  final Function? callback;
  const MusicPlayerInterfacePage({super.key, this.callback});

  @override
  State<MusicPlayerInterfacePage> createState() => _MusicPlayerInterfacePageState();
}

class _MusicPlayerInterfacePageState extends State<MusicPlayerInterfacePage> {

  final Box settingsBox = Hive.box(AppHiveBox.settings.name);

  List miniButtonsOrder = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.miniButtonsOrder,
    defaultValue: AudioPlayerConstants.defaultMiniButtonsOrder,) as List;

  List preferredMiniButtons = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.preferredMiniButtons,
    defaultValue: AudioPlayerConstants.defaultControlButtons)?.toList() as List;

  List<int> preferredCompactNotificationButtons = Hive.box(AppHiveBox.settings.name)
      .get(AppHiveConstants.preferredCompactNotificationButtons,
      defaultValue: AudioPlayerConstants.preferredCompactNotificationButtons) as List<int>;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppFlavour.getBackgroundColor(),
        appBar: AppBarChild(title: AudioPlayerTranslationConstants.ui.tr,),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: ListView(
            padding: const EdgeInsets.all(10.0),
            physics: const BouncingScrollPhysics(),
            children: [
              ListTile(
                title: Text(
                  AudioPlayerTranslationConstants.miniButtons.tr,
                ),
                subtitle: Text(
                  AudioPlayerTranslationConstants.miniButtonsSub.tr,
                ),
                dense: true,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      final List checked = List.from(preferredMiniButtons);
                      final List<String> order = List.from(miniButtonsOrder);
                      return StatefulBuilder(
                        builder: (
                          BuildContext context,
                          StateSetter setStt,
                        ) {
                          return AlertDialog(
                            backgroundColor: AppColor.getMain(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0,),
                            ),
                            content: SizedBox(
                              width: 500,
                              child: ReorderableListView(
                                physics: const BouncingScrollPhysics(),
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                onReorder: (int oldIndex, int newIndex) {
                                  if (oldIndex < newIndex) {
                                    newIndex--;
                                  }
                                  final temp = order.removeAt(
                                    oldIndex,
                                  );
                                  order.insert(newIndex, temp);
                                  setState(() {});
                                },
                                header: Center(
                                  child: Text(AudioPlayerTranslationConstants.changeOrder.tr,),
                                ),
                                children: order.map((e) {
                                  return Row(
                                    key: Key(e),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ReorderableDragStartListener(
                                        index: order.indexOf(e),
                                        child: const Icon(Icons.drag_handle_rounded,),
                                      ),
                                      Expanded(
                                        child: SizedBox(
                                          child: CheckboxListTile(
                                            dense: true,
                                            contentPadding: const EdgeInsets.only(left: 16.0,),
                                            activeColor: Theme.of(context).colorScheme.secondary,
                                            checkColor: Theme.of(context,).colorScheme.secondary == Colors.white
                                                ? Colors.black : null,
                                            value: checked.contains(e),
                                            title: Text(e),
                                            onChanged: (bool? value) {
                                              setStt(
                                                () {
                                                  value! ? checked.add(e) : checked.remove(e);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(AppTranslationConstants.cancel.tr,),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColor.bondiBlue,
                                ),
                                onPressed: () {
                                  setState(
                                    () {
                                      final List temp = [];
                                      for (int i = 0; i < order.length; i++) {
                                        if (checked.contains(order[i])) {
                                          temp.add(order[i]);
                                        }
                                      }
                                      preferredMiniButtons = temp;
                                      miniButtonsOrder = order;
                                      Navigator.pop(context);
                                      Hive.box(AppHiveBox.settings.name).put(
                                        'preferredMiniButtons',
                                        preferredMiniButtons,
                                      );
                                      Hive.box(AppHiveBox.settings.name).put(
                                        'miniButtonsOrder',
                                        order,
                                      );
                                    },
                                  );
                                },
                                child: Text(AppTranslationConstants.ok.tr.toUpperCase(),),
                              ),
                              const SizedBox(
                                width: 5,
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
                title: Text(AudioPlayerTranslationConstants.compactNotificationButtons.tr,),
                subtitle: Text(AudioPlayerTranslationConstants.compactNotificationButtonsSub.tr),
                dense: true,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      final Set<int> checked = {
                        ...preferredCompactNotificationButtons,
                      };
                      final List<Map> buttons = [
                        {
                          'name': 'Like',
                          'index': 0,
                        },
                        {
                          'name': 'Previous',
                          'index': 1,
                        },
                        {
                          'name': 'Play/Pause',
                          'index': 2,
                        },
                        {
                          'name': 'Next',
                          'index': 3,
                        },
                        {
                          'name': 'Stop',
                          'index': 4,
                        },
                      ];
                      return StatefulBuilder(
                        builder: (
                          BuildContext context,
                          StateSetter setStt,
                        ) {
                          return AlertDialog(
                            backgroundColor: AppColor.getMain(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                15.0,
                              ),
                            ),
                            content: SizedBox(
                              width: 500,
                              child: ListView(
                                physics: const BouncingScrollPhysics(),
                                shrinkWrap: true,
                                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10,),
                                children: [
                                  Center(
                                    child: Text(
                                      AudioPlayerTranslationConstants.compactNotificationButtonsHeader.tr,
                                    ),
                                  ),
                                  ...buttons.map((value) {
                                    return CheckboxListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.only(left: 16.0,),
                                      activeColor:
                                      Theme.of(context).colorScheme.secondary,
                                      checkColor: Theme.of(context,).colorScheme.secondary == Colors.white
                                          ? Colors.black : null,
                                      value: checked.contains(value['index'] as int,),
                                      title: Text(value['name'] as String,),
                                      onChanged: (bool? isChecked) {
                                        setState(
                                          () {
                                            if (isChecked!) {
                                              while (checked.length >= 3) {
                                                checked.remove(
                                                  checked.first,
                                                );
                                              }

                                              checked.add(
                                                value['index'] as int,
                                              );
                                            } else {
                                              checked.removeWhere(
                                                (int element) =>
                                                    element == value['index'],
                                              );
                                            }
                                          },
                                        );
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(AppTranslationConstants.cancel.tr,),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColor.bondiBlue,
                                ),
                                onPressed: () {
                                  setState(
                                    () {
                                      while (checked.length > 3) {
                                        checked.remove(
                                          checked.first,
                                        );
                                      }
                                      preferredCompactNotificationButtons = checked.toList()..sort();
                                      Navigator.pop(context);
                                      Hive.box(AppHiveBox.settings.name).put('preferredCompactNotificationButtons', preferredCompactNotificationButtons,
                                      );
                                    },
                                  );
                                },
                                child: Text(AppTranslationConstants.ok.tr.toUpperCase(),),
                              ),
                              AppTheme.widthSpace5,
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              HiveBoxSwitchTile(
                title: AudioPlayerTranslationConstants.showPlaylists.tr,
                keyName: 'showPlaylist',
                defaultValue: true,
              ),
              HiveBoxSwitchTile(
                title: AudioPlayerTranslationConstants.showLast.tr,
                subtitle: AudioPlayerTranslationConstants.showLastSub.tr,
                keyName: 'showRecent',
                defaultValue: true,
              ),
              HiveBoxSwitchTile(
                title: AudioPlayerTranslationConstants.enableGesture.tr,
                subtitle: AudioPlayerTranslationConstants.enableGestureSub.tr,
                keyName: 'enableGesture',
                defaultValue: true,
                isThreeLine: true,
              ),
              HiveBoxSwitchTile(
                title: AudioPlayerTranslationConstants.useLessDataImage.tr,
                subtitle: AudioPlayerTranslationConstants.useLessDataImageSub.tr,
                keyName: 'enableImageOptimization',
                defaultValue: false,
                isThreeLine: true,
              ),
            ],
          ),
        ),
    );
  }
}
