import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_media_player/utils/constants/player_translation_constants.dart';

import '../../../utils/constants/audio_player_constants.dart';
import '../../../utils/constants/audio_player_route_constants.dart';
import '../../../utils/constants/countrycodes.dart';

class WelcomePreferencePage extends StatefulWidget {
  const WelcomePreferencePage({super.key});

  @override
  WelcomePreferencePageState createState() => WelcomePreferencePageState();
}

class WelcomePreferencePageState extends State<WelcomePreferencePage> {

  UserController userController = Get.find<UserController>();
  List preferredLanguage = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.preferredLanguage, defaultValue: ['Español'])?.toList() as List;
  String region = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.region, defaultValue: 'México') as String;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColor.main50,
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 15),
                    child: TextButton(
                      onPressed: () {
                        Hive.box(AppHiveBox.settings.name).put(AppHiveConstants.userId, userController.user.id,);
                        Navigator.popAndPushNamed(context, AudioPlayerRouteConstants.root,);
                      },
                      child: Text(
                        PlayerTranslationConstants.skip.tr,
                        style: TextStyle(color: Colors.grey.withOpacity(0.9),),
                      ),
                    ),
                  ),
                  AppTheme.heightSpace10,
                  Container(
                    padding: const EdgeInsets.only(right: 45),
                    alignment: Alignment.topRight,
                      child: Image(
                        image: AssetImage(AppFlavour.getIconPath(),),
                        height: MediaQuery.of(context).size.width/4,
                        width: MediaQuery.of(context).size.width/4,
                        fit: BoxFit.fitWidth,
                      ),
                  ),
                  AppTheme.heightSpace20,
                  SingleChildScrollView(
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
                                  fontSize: 46,
                                  height: 1.0,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text:
                                        PlayerTranslationConstants.aboard.tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 52,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '!\n',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 54,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: PlayerTranslationConstants.tryOurMusicPlayer.tr,
                                    style: const TextStyle(
                                      height: 1.5,
                                      fontWeight: FontWeight.w300,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 5.0,),
                                  title: Text(PlayerTranslationConstants.langQue.tr,),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10,),
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
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(preferredLanguage.isEmpty
                                            ? 'None' : preferredLanguage.join(', '),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                  dense: true,
                                  onTap: () {
                                    showModalBottomSheet(
                                      backgroundColor: AppColor.getMain(),
                                      context: context,
                                      builder: (BuildContext context) {
                                        final List checked = List.from(preferredLanguage);
                                        return StatefulBuilder(
                                          builder: (BuildContext context, StateSetter setStt,) {
                                            return Column(
                                                children: [
                                                  Expanded(
                                                    child: ListView.builder(
                                                      physics: const BouncingScrollPhysics(),
                                                      shrinkWrap: true,
                                                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10,),
                                                      itemCount: AudioPlayerConstants.musicLanguages.length,
                                                      itemBuilder: (context, idx) {
                                                        return CheckboxListTile(
                                                          activeColor: Theme.of(context,).colorScheme.secondary,
                                                          value: checked.contains(AudioPlayerConstants.musicLanguages[idx],),
                                                          title: Text(AudioPlayerConstants.musicLanguages[idx],),
                                                          onChanged: (bool? value,) {
                                                            value! ? checked.add(AudioPlayerConstants.musicLanguages[idx],)
                                                                : checked.remove(AudioPlayerConstants.musicLanguages[idx],);
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
                                                        onPressed: () => Navigator.pop(context,),
                                                        child: Text(PlayerTranslationConstants.cancel.tr,),
                                                      ),
                                                      TextButton(
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: Theme.of(context,).colorScheme.secondary,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            preferredLanguage = checked;
                                                            Hive.box(AppHiveBox.settings.name,).put(AppHiveConstants.preferredLanguage, checked,);
                                                            Navigator.pop(context,);
                                                          });
                                                          if (preferredLanguage.isEmpty) {
                                                            AppUtilities.showSnackBar(
                                                              message: PlayerTranslationConstants.noLangSelected.tr,
                                                            );
                                                          }
                                                        },
                                                        child: Text(
                                                          PlayerTranslationConstants.ok.tr.toUpperCase(),
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
                                AppTheme.heightSpace20,
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 5.0,),
                                  title: Text(PlayerTranslationConstants.countryQue.tr,),
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
                                        ),
                                      ],
                                    ),
                                    child: Center(child: Text(region, textAlign: TextAlign.end,),),
                                  ),
                                  dense: true,
                                  onTap: () {
                                    showModalBottomSheet(
                                      isDismissible: true,
                                      backgroundColor: AppColor.getMain(),
                                      context: context,
                                      builder: (BuildContext context) {
                                        const Map<String, String> codes = CountryCodes.localChartCodes;
                                        final List<String> countries = codes.keys.toList();
                                        return ListView.builder(
                                            physics: const BouncingScrollPhysics(),
                                            shrinkWrap: true,
                                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10,),
                                            itemCount: countries.length,
                                            itemBuilder: (context, idx) {
                                              return ListTileTheme(
                                                selectedColor: Theme.of(context).colorScheme.secondary,
                                                child: ListTile(
                                                  contentPadding: const EdgeInsets.only(left: 25.0, right: 25.0,),
                                                  title: Text(countries[idx],),
                                                  trailing: region == countries[idx] ? const Icon(Icons.check_rounded,) : const SizedBox.shrink(),
                                                  selected: region == countries[idx],
                                                  onTap: () {
                                                    region = countries[idx];
                                                    Hive.box(AppHiveBox.settings.name).put(AppHiveConstants.region, region,);
                                                    Navigator.pop(context,);
                                                    setState(() {});
                                                  },
                                                ),
                                              );
                                            },

                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 20.0,),
                                GestureDetector(
                                  onTap: () {
                                    Hive.box(AppHiveBox.settings.name).put(AppHiveConstants.userId, userController.user.id,);
                                    Navigator.popAndPushNamed(context, AudioPlayerRouteConstants.root,);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 10.0,),
                                    height: 55.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Theme.of(context).colorScheme.secondary,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 5.0,
                                          offset: Offset(0.0, 3.0),
                                        ),
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
                ],
              ),
            ],
          ),
        ),
    );
  }
}
