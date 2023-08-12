import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/ui/widgets/copy_clipboard.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/utils/helpers/github.dart';
import 'package:neom_music_player/utils/helpers/update.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String? appVersion;

  @override
  void initState() {
    main();
    super.initState();
  }

  Future<void> main() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    setState(
      () {},
    );
  }

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
            PlayerTranslationConstants.about.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    10.0,
                    10.0,
                    10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          PlayerTranslationConstants.version.tr,
                        ),
                        subtitle: Text(
                          PlayerTranslationConstants.versionSub.tr,
                        ),
                        onTap: () {
                          ShowSnackBar().showSnackBar(
                            context,
                            PlayerTranslationConstants.checkingUpdate.tr,
                            noAction: true,
                          );

                          GitHub.getLatestVersion().then(
                            (String latestVersion) async {
                              if (compareVersion(
                                latestVersion,
                                appVersion!,
                              )) {
                                List? abis = await Hive.box('settings')
                                    .get('supportedAbis') as List?;

                                if (abis == null) {
                                  final DeviceInfoPlugin deviceInfo =
                                      DeviceInfoPlugin();
                                  final AndroidDeviceInfo androidDeviceInfo =
                                      await deviceInfo.androidInfo;
                                  abis = androidDeviceInfo.supportedAbis;
                                  await Hive.box('settings')
                                      .put('supportedAbis', abis);
                                }
                                ShowSnackBar().showSnackBar(
                                  context,
                                  PlayerTranslationConstants.updateAvailable.tr,
                                  duration: const Duration(seconds: 15),
                                  action: SnackBarAction(
                                    textColor:
                                        Theme.of(context).colorScheme.secondary,
                                    label: PlayerTranslationConstants.update.tr,
                                    onPressed: () {
                                      Navigator.pop(context);
                                      launchUrl(
                                        Uri.parse(
                                          'https://sangwan5688.github.io/download/',
                                        ),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                  ),
                                );
                              } else {
                                ShowSnackBar().showSnackBar(
                                  context,
                                  PlayerTranslationConstants.latest.tr,
                                );
                              }
                            },
                          );
                        },
                        trailing: Text(
                          'v$appVersion',
                          style: const TextStyle(fontSize: 12),
                        ),
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          PlayerTranslationConstants.shareApp.tr,
                        ),
                        subtitle: Text(
                          PlayerTranslationConstants.shareAppSub.tr,
                        ),
                        onTap: () {
                          Share.share('${PlayerTranslationConstants.shareAppText.tr}:'
                              ' https://sangwan5688.github.io/',
                          );
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          PlayerTranslationConstants.likedWork.tr,
                        ),
                        subtitle: Text(
                          PlayerTranslationConstants.buyCoffee.tr,
                        ),
                        dense: true,
                        onTap: () {
                          launchUrl(
                            Uri.parse(
                              'https://www.buymeacoffee.com/ankitsangwan',
                            ),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      ListTile(
                        title: Text(
                          PlayerTranslationConstants.donateGpay.tr,
                        ),
                        subtitle: Text(
                          PlayerTranslationConstants.donateGpaySub.tr,
                        ),
                        dense: true,
                        isThreeLine: true,
                        onTap: () {
                          const String upiUrl =
                              'upi://pay?pa=ankit.sangwan.5688@oksbi&pn=BlackHole';
                          launchUrl(
                            Uri.parse(upiUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        onLongPress: () {
                          copyToClipboard(
                            context: context,
                            text: 'ankit.sangwan.5688@oksbi',
                            displayText: PlayerTranslationConstants.upiCopied.tr,
                          );
                        },
                        trailing: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor:Colors.white,
                          ),
                          onPressed: () {
                            copyToClipboard(
                              context: context,
                              text: 'ankit.sangwan.5688@oksbi',
                              displayText: PlayerTranslationConstants.upiCopied.tr,
                            );
                          },
                          child: Text(
                            PlayerTranslationConstants.copy.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          PlayerTranslationConstants.contactUs.tr,
                        ),
                        subtitle: Text(
                          PlayerTranslationConstants.contactUsSub.tr,
                        ),
                        dense: true,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SizedBox(
                                height: 100,
                                child: GradientContainer(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              MdiIcons.gmail,
                                            ),
                                            iconSize: 40,
                                            tooltip: PlayerTranslationConstants.gmail.tr,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launchUrl(
                                                Uri.parse(
                                                  'https://mail.google.com/mail/?extsrc=mailto&url=mailto%3A%3Fto%3Dblackholeyoucantescape%40gmail.com%26subject%3DRegarding%2520Mobile%2520App',
                                                ),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                          ),
                                          Text(
                                            PlayerTranslationConstants.gmail.tr,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              MdiIcons.telegram,
                                            ),
                                            iconSize: 40,
                                            tooltip: PlayerTranslationConstants.tg.tr,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launchUrl(
                                                Uri.parse(
                                                  'https://t.me/joinchat/fHDC1AWnOhw0ZmI9',
                                                ),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                          ),
                                          Text(
                                            PlayerTranslationConstants.tg.tr,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              MdiIcons.instagram,
                                            ),
                                            iconSize: 40,
                                            tooltip: PlayerTranslationConstants.insta.tr,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launchUrl(
                                                Uri.parse(
                                                  'https://instagram.com/sangwan5688',
                                                ),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                          ),
                                          Text(
                                            PlayerTranslationConstants.insta.tr,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      ListTile(
                        title: Text(
                          PlayerTranslationConstants.joinTg.tr,
                        ),
                        subtitle: Text(
                          PlayerTranslationConstants.joinTgSub.tr,
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SizedBox(
                                height: 100,
                                child: GradientContainer(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              MdiIcons.telegram,
                                            ),
                                            iconSize: 40,
                                            tooltip: PlayerTranslationConstants.tgGp.tr,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launchUrl(
                                                Uri.parse(
                                                  'https://t.me/joinchat/fHDC1AWnOhw0ZmI9',
                                                ),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                          ),
                                          Text(
                                            PlayerTranslationConstants.tgGp.tr,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              MdiIcons.telegram,
                                            ),
                                            iconSize: 40,
                                            tooltip: PlayerTranslationConstants.tgCh.tr,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launchUrl(
                                                Uri.parse(
                                                  'https://t.me/blackhole_official',
                                                ),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                          ),
                                          Text(
                                            PlayerTranslationConstants.tgCh.tr,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          PlayerTranslationConstants.moreInfo.tr,
                        ),
                        dense: true,
                        onTap: () {
                          Navigator.pushNamed(context, '/about');
                        },
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 30, 5, 20),
                      child: Center(
                        child: Text(
                          PlayerTranslationConstants.madeBy.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
