import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/domain/use_cases/ext_storage_provider.dart';
import 'package:neom_music_player/ui/widgets/box_switch_tile.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:neom_music_player/utils/helpers/picker.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final Box settingsBox = Hive.box(AppHiveConstants.settings);
  String downloadPath = Hive.box(AppHiveConstants.settings).get('downloadPath', defaultValue: '/storage/emulated/0/Music') as String;
  String downloadQuality = Hive.box(AppHiveConstants.settings).get('downloadQuality', defaultValue: '320 kbps') as String;
  // String ytDownloadQuality = Hive.box(AppHiveConstants.settings).get('ytDownloadQuality', defaultValue: 'High') as String;
  int downFilename = Hive.box(AppHiveConstants.settings).get('downFilename', defaultValue: 0) as int;

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
            PlayerTranslationConstants.down.tr,
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
              title: Text(PlayerTranslationConstants.downQuality.tr,),
              subtitle: Text(PlayerTranslationConstants.downQualitySub.tr,),
              onTap: () {},
              trailing: DropdownButton(
                value: downloadQuality,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(
                      () {
                        downloadQuality = newValue;
                        Hive.box(AppHiveConstants.settings).put('downloadQuality', newValue);
                      },
                    );
                  }
                },
                items: <String>['96 kbps', '160 kbps', '320 kbps']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value,),
                  );
                }).toList(),
              ),
              dense: true,
            ),
            // ListTile(
            //   title: Text(PlayerTranslationConstants.ytDownQuality.tr,),
            //   subtitle: Text(PlayerTranslationConstants.ytDownQualitySub.tr,),
            //   onTap: () {},
            //   trailing: DropdownButton(
            //     value: ytDownloadQuality,
            //     style: TextStyle(
            //       fontSize: 12,
            //       color: Theme.of(context).textTheme.bodyLarge!.color,
            //     ),
            //     underline: const SizedBox(),
            //     onChanged: (String? newValue) {
            //       if (newValue != null) {
            //         setState(
            //           () {
            //             ytDownloadQuality = newValue;
            //             Hive.box(AppHiveConstants.settings).put('ytDownloadQuality', newValue);
            //           },
            //         );
            //       }
            //     },
            //     items: <String>['Low', 'High']
            //         .map<DropdownMenuItem<String>>((String value) {
            //       return DropdownMenuItem<String>(
            //         value: value,
            //         child: Text(
            //           value,
            //         ),
            //       );
            //     }).toList(),
            //   ),
            //   dense: true,
            // ),
            ListTile(
              title: Text(
                PlayerTranslationConstants.downLocation.tr,
              ),
              subtitle: Text(downloadPath),
              trailing: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  downloadPath = await ExtStorageProvider.getExtStorage(
                        dirName: 'Music',
                        writeAccess: true,
                      ) ??
                      '/storage/emulated/0/Music';
                  Hive.box(AppHiveConstants.settings).put('downloadPath', downloadPath);
                  setState(
                    () {},
                  );
                },
                child: Text(
                  PlayerTranslationConstants.reset.tr,
                ),
              ),
              onTap: () async {
                final String temp = await Picker.selectFolder(
                  context: context,
                  message: PlayerTranslationConstants.selectDownLocation.tr,
                );
                if (temp.trim() != '') {
                  downloadPath = temp;
                  Hive.box(AppHiveConstants.settings).put('downloadPath', temp);
                  setState(
                    () {},
                  );
                } else {
                  ShowSnackBar().showSnackBar(
                    context,
                    PlayerTranslationConstants.noFolderSelected.tr,
                  );
                }
              },
              dense: true,
            ),
            ListTile(
              title: Text(
                PlayerTranslationConstants.downFilename.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.downFilenameSub.tr,
              ),
              dense: true,
              onTap: () {
                showModalBottomSheet(
                  isDismissible: true,
                  backgroundColor: AppColor.main75,
                  context: context,
                  builder: (BuildContext context) {
                    return BottomGradientContainer(
                      borderRadius: BorderRadius.circular(
                        20.0,
                      ),
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
                          CheckboxListTile(
                            activeColor: Theme.of(context).colorScheme.secondary,
                            title: Text(
                              '${PlayerTranslationConstants.title.tr} - ${PlayerTranslationConstants.artist.tr}',
                            ),
                            value: downFilename == 0,
                            selected: downFilename == 0,
                            onChanged: (bool? val) {
                              if (val ?? false) {
                                downFilename = 0;
                                settingsBox.put('downFilename', 0);
                                Navigator.pop(context);
                              }
                            },
                          ),
                          CheckboxListTile(
                            activeColor: Theme.of(context).colorScheme.secondary,
                            title: Text(
                              '${PlayerTranslationConstants.artist.tr} - ${PlayerTranslationConstants.title.tr}',
                            ),
                            value: downFilename == 1,
                            selected: downFilename == 1,
                            onChanged: (val) {
                              if (val ?? false) {
                                downFilename = 1;
                                settingsBox.put('downFilename', 1);
                                Navigator.pop(context);
                              }
                            },
                          ),
                          CheckboxListTile(
                            activeColor: Theme.of(context).colorScheme.secondary,
                            title: Text(PlayerTranslationConstants.title.tr,),
                            value: downFilename == 2,
                            selected: downFilename == 2,
                            onChanged: (val) {
                              if (val ?? false) {
                                downFilename = 2;
                                settingsBox.put('downFilename', 2);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            BoxSwitchTile(
              title: Text(
                PlayerTranslationConstants.createAlbumFold.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.createAlbumFoldSub.tr,
              ),
              keyName: 'createDownloadFolder',
              isThreeLine: true,
              defaultValue: false,
            ),
            BoxSwitchTile(
              title: Text(
                PlayerTranslationConstants.createYtFold.tr,
              ),
              subtitle: Text(
                PlayerTranslationConstants.createYtFoldSub.tr,
              ),
              keyName: 'createYoutubeFolder',
              isThreeLine: true,
              defaultValue: false,
            ),
          ],
        ),
      ),
    );
  }
}
