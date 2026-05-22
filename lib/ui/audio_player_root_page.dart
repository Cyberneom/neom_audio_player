import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web/audio_player_web_layout.dart';

import 'drawer/audio_player_drawer.dart';
import 'player/miniplayer.dart';
import 'player/miniplayer_controller.dart';
import 'widgets/audio_player_bottom_app_bar.dart';

class AudioPlayerRootPage extends StatefulWidget {
  final Widget? secondaryPage;

  /// Optional navigation sidebar builder for web (e.g. Home's LeftSidebar).
  final Widget Function({required bool expanded})? navigationSidebar;

  /// Builds the mobile home page (recommendations + shelves). Provided by
  /// `neom_audio_platform`'s `AudioPlayerHomePage`. When `null`, a
  /// placeholder card explains how to plug it in.
  final WidgetBuilder? homeBuilder;

  /// Web-only builders forwarded to [AudioPlayerWebLayout]. See its docs.
  final Widget Function(BuildContext, void Function(Itemlist))?
      webMainFeedBuilder;
  final Widget Function(BuildContext, void Function(Itemlist))?
      webSearchFeedBuilder;
  final Widget Function(BuildContext, VoidCallback,
      void Function(Itemlist), bool)? webSidebarLibraryBuilder;
  final Widget Function(BuildContext, Itemlist, VoidCallback)?
      webPlaylistDetailBuilder;
  final Widget Function(BuildContext, VoidCallback, VoidCallback)?
      webJamSessionPanelBuilder;

  const AudioPlayerRootPage({
    super.key,
    this.secondaryPage,
    this.navigationSidebar,
    this.homeBuilder,
    this.webMainFeedBuilder,
    this.webSearchFeedBuilder,
    this.webSidebarLibraryBuilder,
    this.webPlaylistDetailBuilder,
    this.webJamSessionPanelBuilder,
  });


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
        mainFeedBuilder: widget.webMainFeedBuilder,
        searchFeedBuilder: widget.webSearchFeedBuilder,
        sidebarLibraryBuilder: widget.webSidebarLibraryBuilder,
        playlistDetailBuilder: widget.webPlaylistDetailBuilder,
        jamSessionPanelBuilder: widget.webJamSessionPanelBuilder,
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
                children: [
                  widget.homeBuilder?.call(context) ?? const _HomePlaceholder(),
                  if(widget.secondaryPage != null) widget.secondaryPage!,
                ],
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

/// Fallback shown when [AudioPlayerRootPage] was created without a
/// `homeBuilder`. Tells the developer how to wire `neom_audio_platform`'s
/// `AudioPlayerHomePage` in.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColor.appBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.extension_rounded, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text(
              'Home feed not connected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Add `neom_audio_platform` and pass `homeBuilder: (_) => AudioPlayerHomePage()` to `AudioPlayerRootPage` to enable the mobile home feed.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
