import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import '../../../widgets/box_switch_tile.dart';
import '../../../widgets/gradient_containers.dart';
import '../../../../utils/constants/app_hive_constants.dart';
import '../../../../utils/constants/player_translation_constants.dart';

class MusicPlayerInterfacePage extends StatefulWidget {
  final Function? callback;
  const MusicPlayerInterfacePage({this.callback});

  @override
  State<MusicPlayerInterfacePage> createState() => _MusicPlayerInterfacePageState();
}

class _MusicPlayerInterfacePageState extends State<MusicPlayerInterfacePage> {
  final Box settingsBox = Hive.box(AppHiveConstants.settings);
  List blacklistedHomeSections = Hive.box(AppHiveConstants.settings)
      .get('blacklistedHomeSections', defaultValue: []) as List;
  List miniButtonsOrder = Hive.box(AppHiveConstants.settings).get(
    'miniButtonsOrder',
    defaultValue: ['Like', 'Previous', 'Play/Pause', 'Next', 'Download'],
  ) as List;
  List preferredMiniButtons = Hive.box(AppHiveConstants.settings).get(
    'preferredMiniButtons',
    defaultValue: ['Like', 'Play/Pause', 'Next'],
  )?.toList() as List;
  List<int> preferredCompactNotificationButtons = Hive.box(AppHiveConstants.settings).get(
    'preferredCompactNotificationButtons',
    defaultValue: [1, 2, 3],
  ) as List<int>;
  List sectionsToShow = Hive.box(AppHiveConstants.settings).get(
    'sectionsToShow',
    defaultValue: ['Home', 'Top Charts', 'YouTube', 'Library'],
  ) as List;
  final List sectionsAvailableToShow = Hive.box(AppHiveConstants.settings).get(
    'sectionsAvailableToShow',
    defaultValue: ['Top Charts', 'YouTube', 'Library', 'Settings'],
  ) as List;

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
            PlayerTranslationConstants.ui.tr,
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
          padding: const EdgeInsets.all(10.0),
          physics: const BouncingScrollPhysics(),
          children: [
            ListTile(
              title: Text(
                PlayerTranslationConstants.miniButtons.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.miniButtonsSub.tr,
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
                          backgroundColor: AppColor.main75,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              15.0,
                            ),
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
                                setStt(
                                  () {},
                                );
                              },
                              header: Center(
                                child: Text(
                                  PlayerTranslationConstants.changeOrder.tr,
                                ),
                              ),
                              children: order.map((e) {
                                return Row(
                                  key: Key(e),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ReorderableDragStartListener(
                                      index: order.indexOf(e),
                                      child: const Icon(
                                        Icons.drag_handle_rounded,
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        child: CheckboxListTile(
                                          dense: true,
                                          contentPadding: const EdgeInsets.only(
                                            left: 16.0,
                                          ),
                                          activeColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          checkColor: Theme.of(
                                                    context,
                                                  ).colorScheme.secondary ==
                                                  Colors.white
                                              ? Colors.black
                                              : null,
                                          value: checked.contains(e),
                                          title: Text(e),
                                          onChanged: (bool? value) {
                                            setStt(
                                              () {
                                                value!
                                                    ? checked.add(e)
                                                    : checked.remove(e);
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
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[700],
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
                                foregroundColor:
                                    Theme.of(context).colorScheme.secondary ==
                                            Colors.white
                                        ? Colors.black
                                        : null,
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
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
                                    Hive.box(AppHiveConstants.settings).put(
                                      'preferredMiniButtons',
                                      preferredMiniButtons,
                                    );
                                    Hive.box(AppHiveConstants.settings).put(
                                      'miniButtonsOrder',
                                      order,
                                    );
                                  },
                                );
                              },
                              child: Text(
                                PlayerTranslationConstants.ok.tr,
                              ),
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
              title: Text(
                PlayerTranslationConstants.compactNotificationButtons.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.compactNotificationButtonsSub.tr,
              ),
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
                              padding: const EdgeInsets.fromLTRB(
                                0,
                                10,
                                0,
                                10,
                              ),
                              children: [
                                Center(
                                  child: Text(
                                    PlayerTranslationConstants.compactNotificationButtonsHeader.tr,
                                  ),
                                ),
                                ...buttons.map((value) {
                                  return CheckboxListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.only(
                                      left: 16.0,
                                    ),
                                    activeColor:
                                        Theme.of(context).colorScheme.secondary,
                                    checkColor: Theme.of(
                                              context,
                                            ).colorScheme.secondary ==
                                            Colors.white
                                        ? Colors.black
                                        : null,
                                    value: checked.contains(
                                      value['index'] as int,
                                    ),
                                    title: Text(
                                      value['name'] as String,
                                    ),
                                    onChanged: (bool? isChecked) {
                                      setStt(
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
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[700],
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
                                foregroundColor:
                                    Theme.of(context).colorScheme.secondary ==
                                            Colors.white
                                        ? Colors.black
                                        : null,
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                              ),
                              onPressed: () {
                                setState(
                                  () {
                                    while (checked.length > 3) {
                                      checked.remove(
                                        checked.first,
                                      );
                                    }
                                    preferredCompactNotificationButtons =
                                        checked.toList()..sort();
                                    Navigator.pop(context);
                                    Hive.box(AppHiveConstants.settings).put(
                                      'preferredCompactNotificationButtons',
                                      preferredCompactNotificationButtons,
                                    );
                                  },
                                );
                              },
                              child: Text(
                                PlayerTranslationConstants.ok.tr,
                              ),
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
            BoxSwitchTile(
              title: Text(
                PlayerTranslationConstants.showPlaylists.tr,
              ),
              keyName: 'showPlaylist',
              defaultValue: true,
            ),
            BoxSwitchTile(
              title: Text(
                PlayerTranslationConstants.showLast.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.showLastSub.tr,
              ),
              keyName: 'showRecent',
              defaultValue: true,
            ),
            BoxSwitchTile(
              title: Text(
                PlayerTranslationConstants.enableGesture.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.enableGestureSub.tr,
              ),
              keyName: 'enableGesture',
              defaultValue: true,
              isThreeLine: true,
            ),
            BoxSwitchTile(
              title: Text(
                PlayerTranslationConstants.useLessDataImage.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.useLessDataImageSub.tr,
              ),
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
