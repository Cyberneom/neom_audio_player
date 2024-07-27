
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../utils/constants/player_translation_constants.dart';
import '../utils/music_player_utilities.dart';
import 'drawer/music_player_drawer.dart';
import 'player/miniplayer.dart';
import 'widgets/music_player_bottom_app_bar.dart';

class MusicPlayerRootPage extends StatefulWidget {
  const MusicPlayerRootPage({super.key});

  @override
  MusicPlayerRootPageState createState() => MusicPlayerRootPageState();
}

class MusicPlayerRootPageState extends State<MusicPlayerRootPage> {

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
        drawer: const MusicPlayerDrawer(),
        body: isLoading ? const AppCircularProgressIndicator() :
        Stack(
          children: [
            PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: pageController,
                children: MusicPlayerUtilities.getMusicPlayerPages()
            ),
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
            selectedColor: Colors.white.withOpacity(0.9),
            notchedShape: const CircularNotchedRectangle(),
            onTabSelected:(int index) => selectPageView(index, context: context),
            items: [
              MusicPlayerBottomAppBarItem(iconData: Icons.play_circle_fill, text: AppFlavour.getMusicPlayerHomeTitle(),),
              MusicPlayerBottomAppBarItem(iconData: Icons.library_music, text: PlayerTranslationConstants.playlists.tr,),
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
