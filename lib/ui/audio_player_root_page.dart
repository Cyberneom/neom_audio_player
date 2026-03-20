import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web/audio_player_web_layout.dart';

import 'drawer/audio_player_drawer.dart';
import 'home/audio_player_home_page.dart';
import 'player/miniplayer.dart';
import 'player/miniplayer_controller.dart';
import 'widgets/audio_player_bottom_app_bar.dart';

class AudioPlayerRootPage extends StatefulWidget {
  final Widget? secondaryPage;

  /// Optional navigation sidebar builder for web (e.g. Home's LeftSidebar).
  final Widget Function({required bool expanded})? navigationSidebar;

  const AudioPlayerRootPage({super.key, this.secondaryPage, this.navigationSidebar});


  @override
  AudioPlayerRootPageState createState() => AudioPlayerRootPageState();
}

class AudioPlayerRootPageState extends State<AudioPlayerRootPage> {

  final PageController pageController = PageController();
  bool hasItems = false;
  bool isLoading = false;
  int currentIndex = 0;


  @override
  void initState() {
    super.initState();
    if (Sint.isRegistered<MiniPlayerController>()) {
      Sint.find<MiniPlayerController>().setIsTimeline(false);
    } else {
      Sint.put(MiniPlayerController()).setIsTimeline(false);
    }
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return AudioPlayerWebLayout(
        secondaryPage: widget.secondaryPage,
        navigationSidebar: widget.navigationSidebar,
      );
    }

    return Scaffold(
      backgroundColor: AppFlavour.getBackgroundColor(),
      drawer: AppConfig.instance.isGuestMode ? null : const AudioPlayerDrawer(),
      body: isLoading ? const AppCircularProgressIndicator() :
        Stack(
          children: [
            PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: pageController,
                children: [AudioPlayerHomePage(), if(widget.secondaryPage != null) widget.secondaryPage!]
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
          child: AudioPlayerBottomAppBar(
            backgroundColor: AppColor.surfaceElevated,
            color: Colors.white54,
            selectedColor: AppColor.white80,
            notchedShape: const CircularNotchedRectangle(),
            onTabSelected:(int index) => selectPageView(index, context: context),
            items: [
              MusicPlayerBottomAppBarItem(iconData: Icons.play_circle_fill, text: AppFlavour.getAudioPlayerHomeTitle(),),
              if(widget.secondaryPage != null) MusicPlayerBottomAppBarItem(iconData: Icons.library_music, text: AppTranslationConstants.playlists.tr,),
            ],
          ),
        ),
    );
  }

  void selectPageView(int index, {required BuildContext context}) async {
    AppConfig.logger.t("Changing page view to index: $index");

    if(index > 0) {
      AuthGuard.protect(context, () {
        try {

          if(pageController.hasClients) {
            pageController.jumpToPage(index);
            currentIndex = index;
          }

        } catch (e, st) {
          NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'selectPageView');
        }
        setState(() {});
      });
    }
  }

}
