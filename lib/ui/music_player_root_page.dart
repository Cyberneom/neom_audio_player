
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';

import 'drawer/music_player_drawer.dart';
import '../utils/constants/player_translation_constants.dart';
import 'player/miniplayer.dart';
import 'widgets/music_player_bottom_app_bar.dart';

class MusicPlayerRootPage extends StatefulWidget {
  const MusicPlayerRootPage({super.key});

  @override
  _MusicPlayerRootPageState createState() => _MusicPlayerRootPageState();
}

class _MusicPlayerRootPageState extends State<MusicPlayerRootPage> {

  final PageController pageController = PageController();
  bool hasItems = false;
  bool isLoading = false;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColor.main50,
        drawer: MusicPlayerDrawer(),
        body: isLoading ? Container(
            decoration: AppTheme.appBoxDecoration,
            child: const Center(
                child: CircularProgressIndicator()
            )
        ) : Stack(
          children: [
            PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: pageController,
                children: AppFlavour.getMusicPlayerPages()
            ),
            if(AppFlavour.appInUse == AppInUse.g
                // || _.userController.user!.userRole == UserRole.superAdmin
            )
              Positioned(
                left: 0, right: 0,
                bottom: 0.1, // Adjust this value according to your BottomNavigationBar's height
                child: Container(
                    decoration: AppTheme.appBoxDecoration,
                    child: MiniPlayer()
                ),
              ),
          ],
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(canvasColor: Colors.grey[900]),
          child: MusicPlayerBottomAppBar(
            backgroundColor: AppColor.bottomNavigationBar,
            color: Colors.white54,
            selectedColor: Theme.of(context).colorScheme.secondary,
            notchedShape: const CircularNotchedRectangle(),
            iconSize: 20.0,
            onTabSelected:(int index) => selectPageView(index, context: context),
            items: [
              MusicPlayerBottomAppBarItem(iconData: Icons.play_circle_fill,
                text: PlayerTranslationConstants.music.tr,
              ),
              MusicPlayerBottomAppBarItem(
                iconData: Icons.library_music,
                text: PlayerTranslationConstants.playlists.capitalizeFirst,
                animation: hasItems ? null : Column(
                  children: [
                    SizedBox(
                      child: DefaultTextStyle(
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 6,
                        ),
                        child: AnimatedTextKit(
                          repeatForever: true,
                          animatedTexts: [
                            FlickerAnimatedText(AppFlavour.appInUse == AppInUse.g ? AppTranslationConstants.addItems.tr : ''),
                          ],
                          onTap: () {},
                        ),
                      ),
                    ),
                    AppTheme.widthSpace10,
                  ],),
              ),
            ],
          ),
        ),
    );
  }

  void selectPageView(int index, {BuildContext? context}) async {
    AppUtilities.logger.t("Changing page view to index: $index");

    try {
      if(pageController.hasClients) {
        pageController.jumpToPage(index);
        currentIndex = index;
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    setState(() {});
  }

}
