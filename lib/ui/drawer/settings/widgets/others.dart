import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';

import '../../../../utils/constants/app_hive_constants.dart';
import '../../../../utils/constants/player_translation_constants.dart';
import 'hive_box_switch_tile.dart';

class OthersPage extends StatefulWidget {
  const OthersPage({super.key});

  @override
  State<OthersPage> createState() => _OthersPageState();
}

class _OthersPageState extends State<OthersPage> {

  final Box settingsBox = Hive.box(AppHiveConstants.settings);
  final ValueNotifier<bool> includeOrExclude = ValueNotifier<bool>(
    Hive.box(AppHiveConstants.settings).get('includeOrExclude', defaultValue: false) as bool,
  );

  List includedExcludedPaths = Hive.box(AppHiveConstants.settings).get('includedExcludedPaths', defaultValue: []) as List;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColor.main50,
        appBar: AppBarChild(title: PlayerTranslationConstants.others.tr,),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(10.0),
          children: [
            // HiveBoxSwitchTile(
            //   title: Text(PlayerTranslationConstants.liveSearch.tr,),
            //   subtitle: Text(PlayerTranslationConstants.liveSearchSub.tr,),
            //   keyName: 'liveSearch',
            //   isThreeLine: false,
            //   defaultValue: true,
            // ),
            ///DOWNLOAD FEATURE IN PROGRESS
            // BoxSwitchTile(
            //   title: Text(PlayerTranslationConstants.useDown.tr,),
            //   subtitle: Text(PlayerTranslationConstants.useDownSub.tr,),
            //   keyName: 'useDown',
            //   isThreeLine: true,
            //   defaultValue: true,
            // ),
            HiveBoxSwitchTile(
              title: PlayerTranslationConstants.getLyricsOnline.tr,
              subtitle: PlayerTranslationConstants.getLyricsOnlineSub.tr,
              keyName: 'getLyricsOnline',
              isThreeLine: true,
              defaultValue: true,
            ),
            HiveBoxSwitchTile(
              title: PlayerTranslationConstants.stopOnClose.tr,
              subtitle: PlayerTranslationConstants.stopOnCloseSub.tr,
              isThreeLine: true,
              keyName: 'stopForegroundService',
              defaultValue: false,
            ),
            ///DEPRECATED
            // const HiveBoxSwitchTile(
            //   title: Text('Remove Service from foreground when paused'),
            //   subtitle: Text("If turned on, you can slide notification when paused to stop the service. "
            //       "But Service can also be stopped by android to release memory. "
            //       "If you don't want android to stop service while paused, turn it off\nDefault: On\n",
            //   ),
            //   isThreeLine: true,
            //   keyName: 'stopServiceOnPause',
            //   defaultValue: false,
            // ),
            ///VERITY TO PLAY LOCAL FILES
            // ListTile(
            //   title: Text(PlayerTranslationConstants.includeExcludeFolder.tr,),
            //   subtitle: Text(PlayerTranslationConstants.includeExcludeFolderSub.tr,),
            //   dense: true,
            //   onTap: () {
            //     final GlobalKey<AnimatedListState> listKey =
            //     GlobalKey<AnimatedListState>();
            //     showModalBottomSheet(
            //       isDismissible: true,
            //       backgroundColor: AppColor.main75,
            //       context: context,
            //       builder: (BuildContext context) {
            //         return BottomGradientContainer(
            //           borderRadius: BorderRadius.circular(
            //             20.0,
            //           ),
            //           child: AnimatedList(
            //             physics: const BouncingScrollPhysics(),
            //             shrinkWrap: true,
            //             padding: const EdgeInsets.symmetric(vertical: 10),
            //             key: listKey,
            //             initialItemCount: includedExcludedPaths.length + 2,
            //             itemBuilder: (cntxt, idx, animation) {
            //               if (idx == 0) {
            //                 return ValueListenableBuilder(
            //                   valueListenable: includeOrExclude,
            //                   builder: (
            //                       BuildContext context,
            //                       bool value,
            //                       Widget? widget,
            //                       ) {
            //                     return Column(
            //                       crossAxisAlignment: CrossAxisAlignment.start,
            //                       children: [
            //                         Row(
            //                           children: <Widget>[
            //                             ChoiceChip(
            //                               label: Text(
            //                                 PlayerTranslationConstants.excluded.tr,
            //                               ),
            //                               selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            //                               labelStyle: TextStyle(
            //                                 color: !value
            //                                     ? Theme.of(context).colorScheme.secondary
            //                                     : Theme.of(context).textTheme.bodyLarge!.color,
            //                                 fontWeight: !value
            //                                     ? FontWeight.w600 : FontWeight.normal,
            //                               ),
            //                               selected: !value,
            //                               onSelected: (bool selected) {
            //                                 includeOrExclude.value = !selected;
            //                                 settingsBox.put(
            //                                   'includeOrExclude',
            //                                   !selected,
            //                                 );
            //                               },
            //                             ),
            //                             AppTheme.widthSpace5,
            //                             ChoiceChip(
            //                               label: Text(
            //                                 PlayerTranslationConstants.included.tr,
            //                               ),
            //                               selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            //                               labelStyle: TextStyle(
            //                                 color: value
            //                                     ? Theme.of(context).colorScheme.secondary
            //                                     : Theme.of(context).textTheme.bodyLarge!.color,
            //                                 fontWeight: value
            //                                     ? FontWeight.w600 : FontWeight.normal,
            //                               ),
            //                               selected: value,
            //                               onSelected: (bool selected) {
            //                                 includeOrExclude.value = selected;
            //                                 settingsBox.put(
            //                                   'includeOrExclude',
            //                                   selected,
            //                                 );
            //                               },
            //                             ),
            //                           ],
            //                         ),
            //                         Padding(
            //                           padding: const EdgeInsets.only(left: 5.0, top: 5.0, bottom: 10.0,),
            //                           child: Text(value
            //                                 ? PlayerTranslationConstants.includedDetails.tr
            //                                 : PlayerTranslationConstants.excludedDetails.tr,
            //                             textAlign: TextAlign.start,
            //                           ),
            //                         ),
            //                       ],
            //                     );
            //                   },
            //                 );
            //               }
            //               if (idx == 1) {
            //                 return ListTile(
            //                   title: Text(
            //                     PlayerTranslationConstants.addNew.tr,
            //                   ),
            //                   leading: const Icon(
            //                     CupertinoIcons.add,
            //                   ),
            //                   onTap: () async {
            //                     final String temp = await Picker.selectFolder(
            //                       context: context,
            //                     );
            //                     if (temp.trim() != '' &&
            //                         !includedExcludedPaths.contains(temp)) {
            //                       includedExcludedPaths.add(temp);
            //                       Hive.box(AppHiveConstants.settings).put('includedExcludedPaths', includedExcludedPaths,);
            //                       listKey.currentState!.insertItem(includedExcludedPaths.length,);
            //                     } else {
            //                       if (temp.trim() == '') {
            //                         Navigator.pop(context);
            //                       }
            //                       AppUtilities.showSnackBar(message: temp.trim() == ''
            //                           ? 'No folder selected' : 'Already added',);
            //                     }
            //                   },
            //                 );
            //               }
            //
            //               return SizeTransition(
            //                 sizeFactor: animation,
            //                 child: ListTile(
            //                   leading: const Icon(
            //                     CupertinoIcons.folder,
            //                   ),
            //                   title: Text(
            //                     includedExcludedPaths[idx - 2].toString(),
            //                   ),
            //                   trailing: IconButton(
            //                     icon: const Icon(
            //                       CupertinoIcons.clear,
            //                       size: 15.0,
            //                     ),
            //                     tooltip: 'Remove',
            //                     onPressed: () {
            //                       includedExcludedPaths.removeAt(idx - 2);
            //                       Hive.box(AppHiveConstants.settings).put('includedExcludedPaths', includedExcludedPaths,);
            //                       listKey.currentState!.removeItem(idx, (context, animation) => Container(),);
            //                     },
            //                   ),
            //                 ),
            //               );
            //             },
            //           ),
            //         );
            //       },
            //     );
            //   },
            // ),
            // ListTile(
            //   title: Text(
            //     PlayerTranslationConstants.minAudioLen.tr,
            //   ),
            //   subtitle: Text(
            //     PlayerTranslationConstants.minAudioLenSub.tr,
            //   ),
            //   dense: true,
            //   onTap: () {
            //     showTextInputDialog(
            //       context: context,
            //       title: PlayerTranslationConstants.minAudioAlert.tr,
            //       initialText: (Hive.box(AppHiveConstants.settings).get('minDuration', defaultValue: 30) as int)
            //           .toString(),
            //       keyboardType: TextInputType.number,
            //       onSubmitted: (String value, BuildContext context) {
            //         if (value.trim() == '') value = '0';
            //         Hive.box(AppHiveConstants.settings).put('minDuration', int.parse(value));
            //         Navigator.pop(context);
            //       },
            //     );
            //   },
            // ),
            ListTile(
              title: Text(PlayerTranslationConstants.clearCache.tr,),
              subtitle: Text(PlayerTranslationConstants.clearCacheSub.tr,),
              trailing: SizedBox(
                height: 70.0,
                width: 70.0,
                child: Center(
                  child: FutureBuilder(
                    future: File(Hive.box(AppHiveConstants.cache).path!).length(),
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<int> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Text(
                          '${((snapshot.data ?? 0) / (1024 * 1024)).toStringAsFixed(2)} MB',
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              dense: true,
              isThreeLine: true,
              onTap: () async {
                Hive.box(AppHiveConstants.cache).clear();
                setState(
                  () {},
                );
              },
            ),
          ],
        ),
        ),
    );
  }
}
