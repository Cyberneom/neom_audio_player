/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/countrycodes.dart';
import 'package:neom_music_player/utils/constants/music_player_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';

class WelcomePreferencePage extends StatefulWidget {
  const WelcomePreferencePage({super.key});

  @override
  _WelcomePreferencePageState createState() => _WelcomePreferencePageState();
}

class _WelcomePreferencePageState extends State<WelcomePreferencePage> {


  List<bool> isSelected = [true, false];
  List preferredLanguage = Hive.box('settings')
      .get('preferredLanguage', defaultValue: ['Hindi'])?.toList() as List;
  String region =
      Hive.box(AppHiveConstants.settings).get('region', defaultValue: 'México') as String;
  bool useProxy =
      Hive.box(AppHiveConstants.settings).get('useProxy', defaultValue: false) as bool;

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: AppColor.main50,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: MediaQuery.of(context).size.width / 1.5,
                child: Image(
                  image: AssetImage(AppFlavour.getIconPath(),),
                  height: MediaQuery.of(context).size.height / 4,
                  width: MediaQuery.of(context).size.width / 4,
                  fit: BoxFit.fitWidth,
                ),
              ),
              // const GradientContainer(
              //   child: null,
              //   opacity: true,
              // ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          Navigator.popAndPushNamed(context, '/');
                        },
                        child: Text(
                          PlayerTranslationConstants.skip.tr,
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.15,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: '${PlayerTranslationConstants.welcome.tr}\n',
                                  style: TextStyle(
                                    fontSize: 46.sp,
                                    height: 1.0,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text:
                                          PlayerTranslationConstants.aboard.tr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 52.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '!\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 54.sp,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          PlayerTranslationConstants.tryOurMusicPlayer.tr,
                                      style: TextStyle(
                                        height: 1.5,
                                        fontWeight: FontWeight.w300,
                                        fontSize: 14.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.1,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 5.0,
                                    ),
                                    title: Text(
                                      PlayerTranslationConstants.langQue.tr,
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.only(
                                        top: 5,
                                        bottom: 5,
                                        left: 10,
                                        right: 10,
                                      ),
                                      height: 57.0,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: AppColor.bondiBlue75,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 5.0,
                                            offset: Offset(0.0, 3.0),
                                          )
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          preferredLanguage.isEmpty
                                              ? 'None'
                                              : preferredLanguage.join(', '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ),
                                    dense: true,
                                    onTap: () {
                                      showModalBottomSheet(
                                        backgroundColor: AppColor.main25,
                                        context: context,
                                        builder: (BuildContext context) {
                                          final List checked =
                                              List.from(preferredLanguage);
                                          return StatefulBuilder(
                                            builder: (
                                              BuildContext context,
                                              StateSetter setStt,
                                            ) {
                                              return BottomGradientContainer(
                                                borderRadius: BorderRadius.circular(20.0,),
                                                hasOpacity: true,
                                                child: Column(
                                                  children: [
                                                    Expanded(
                                                      child: ListView.builder(
                                                        physics: const BouncingScrollPhysics(),
                                                        shrinkWrap: true,
                                                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10,),
                                                        itemCount: MusicPlayerConstants.musicLanguages.length,
                                                        itemBuilder: (context, idx) {
                                                          return CheckboxListTile(
                                                            activeColor: Theme.of(context,).colorScheme.secondary,
                                                            value: checked.contains(MusicPlayerConstants.musicLanguages[idx],),
                                                            title: Text(MusicPlayerConstants.musicLanguages[idx],),
                                                            onChanged: (bool? value,) {
                                                              value! ? checked.add(MusicPlayerConstants.musicLanguages[idx],)
                                                                  : checked.remove(MusicPlayerConstants.musicLanguages[idx],);
                                                              setStt(() {});
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
                                                            foregroundColor: Theme.of(context,).colorScheme.secondary,
                                                          ),
                                                          onPressed: () {
                                                            Navigator.pop(context,);
                                                          },
                                                          child: Text(PlayerTranslationConstants.cancel.tr,),
                                                        ),
                                                        TextButton(
                                                          style: TextButton.styleFrom(
                                                            foregroundColor: Theme.of(context,).colorScheme.secondary,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              preferredLanguage = checked;
                                                              Navigator.pop(context,);
                                                              Hive.box('settings',).put('preferredLanguage', checked,);
                                                            });
                                                            if (preferredLanguage.isEmpty) {
                                                              ShowSnackBar().showSnackBar(context,
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
                                  const SizedBox(height: 20.0,),
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 5.0,
                                    ),
                                    title: Text(
                                      PlayerTranslationConstants.countryQue.tr,
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      height: 57.0,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10.0),
                                        color: AppColor.bondiBlue75,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 5.0,
                                            offset: Offset(0.0, 3.0),
                                          )
                                        ],
                                      ),
                                      child: Center(child: Text(region, textAlign: TextAlign.end,),),
                                    ),
                                    dense: true,
                                    onTap: () {
                                      showModalBottomSheet(
                                        isDismissible: true,
                                        backgroundColor: AppColor.main75,
                                        context: context,
                                        builder: (BuildContext context) {
                                          const Map<String, String> codes =
                                              CountryCodes.localChartCodes;
                                          final List<String> countries =
                                              codes.keys.toList();
                                          return BottomGradientContainer(
                                            borderRadius:
                                                BorderRadius.circular(20.0),
                                            child: ListView.builder(
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              shrinkWrap: true,
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                0,
                                                10,
                                                0,
                                                10,
                                              ),
                                              itemCount: countries.length,
                                              itemBuilder: (context, idx) {
                                                return ListTileTheme(
                                                  selectedColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                  child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.only(
                                                      left: 25.0,
                                                      right: 25.0,
                                                    ),
                                                    title: Text(
                                                      countries[idx],
                                                    ),
                                                    trailing: region ==
                                                            countries[idx]
                                                        ? const Icon(
                                                            Icons.check_rounded,
                                                          )
                                                        : const SizedBox(),
                                                    selected: region ==
                                                        countries[idx],
                                                    onTap: () {
                                                      region = countries[idx];
                                                      Hive.box(AppHiveConstants.settings).put(
                                                        'region',
                                                        region,
                                                      );
                                                      Navigator.pop(
                                                        context,
                                                      );
                                                      if (region != 'India') {
                                                        ShowSnackBar()
                                                            .showSnackBar(
                                                          context,
                                                          "PlayerTranslationConstants.useVpn.tr",
                                                          duration:
                                                              const Duration(
                                                            seconds: 10,
                                                          ),
                                                          action:
                                                              SnackBarAction(
                                                            textColor: Theme.of(
                                                              context,
                                                            )
                                                                .colorScheme
                                                                .secondary,
                                                            label: PlayerTranslationConstants.useProxy.tr,
                                                            onPressed: () {
                                                              Hive.box(
                                                                'settings',
                                                              ).put(
                                                                'useProxy',
                                                                true,
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      }
                                                      setState(() {});
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20.0,),
                                  GestureDetector(
                                    onTap: () {
                                      Hive.box(AppHiveConstants.settings).put('userId', "123456",);
                                      Navigator.popAndPushNamed(context, '/',);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 10.0,
                                      ),
                                      height: 55.0,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 5.0,
                                            offset: Offset(0.0, 3.0),
                                          )
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          PlayerTranslationConstants.finish.tr,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
