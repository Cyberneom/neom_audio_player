
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_itemlists/itemlists/ui/itemlist_page.dart';
import '../domain/entities/custom_bottom_nav_bar_item.dart';
import 'drawer/music_player_drawer.dart';
import 'home/music_player_home_page.dart';
import 'home/widgets/bottom_nav_bar.dart';
import 'music_player_routes.dart';
import 'player/media_player_page.dart';
import 'player/miniplayer.dart';
import 'spotify/spotify_top_page.dart';
import 'widgets/gradient_containers.dart';
import '../utils/constants/music_player_route_constants.dart';
import '../utils/constants/player_translation_constants.dart';
import '../utils/helpers/route_handler.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

class MusicPlayerRootPage extends StatefulWidget {
  @override
  _MusicPlayerRootPageState createState() => _MusicPlayerRootPageState();
}

class _MusicPlayerRootPageState extends State<MusicPlayerRootPage> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  List<String> shortSectionsToShow = ['Music', 'Playlists',];
  List<String> sectionsToShow = ['Music', 'Playlists', 'Spotify'];
  DateTime? backButtonPressTime;
  final bool useDense = false;

  ///DEPRECATED
  // void callback() {
  //   List<String> shortSectionsToShow = ['Music', 'Playlists',];
  //   List<String> sectionsToShow = ['Music', 'Playlists', 'Spotify'];
  //   onItemTapped(0);
  //   setState(() {});
  // }

  void onItemTapped(int index) {
    _selectedIndex.value = index;
    _controller.jumpToTab(
      index,
    );
  }

  final PageController _pageController = PageController();
  final PersistentTabController _controller = PersistentTabController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isRotated = MediaQuery.of(context).size.height < screenWidth;

    List<String> sections = AppFlavour.appInUse != AppInUse.g || Platform.isIOS ? shortSectionsToShow : sectionsToShow;
    return GradientContainer(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: MusicPlayerDrawer(),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: Row(
          children: [
            if (isRotated) getRotatedDrawer(sections),
            Expanded(
              child: PersistentTabView.custom(
                context,
                controller: _controller,
                itemCount: sections.length,
                navBarHeight: (isRotated ? 55 : 55 + 70) + (useDense ? 0 : 15),
                // confineInSafeArea: false,
                onItemTapped: onItemTapped,
                routeAndNavigatorSettings: CustomWidgetRouteAndNavigatorSettings(
                  routes: MusicPlayerRoutes.routes,
                  onGenerateRoute: (RouteSettings settings) {
                    if (settings.name == MusicPlayerRouteConstants.player) {
                      return PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => MediaPlayerPage(),
                      );
                    }
                    return HandleRoute.handleRoute(settings.name);
                  },
                ),
                customWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MiniPlayer(),
                    if (!isRotated)
                      ValueListenableBuilder(
                        valueListenable: _selectedIndex,
                        builder: (
                            BuildContext context,
                            int indexValue,
                            Widget? child,
                            ) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            height: 60,
                            child: CustomBottomNavBar(
                              currentIndex: indexValue,
                              backgroundColor: AppColor.main75,
                              onTap: (index) {
                                onItemTapped(index);
                              },
                              items: _navBarItems(context, sections),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                screens: sections.map((e) {
                  switch (e) {
                    case 'Home':
                      return const SafeArea(child: MusicPlayerHomePage());
                    case 'Playlists':
                      return const SafeArea(child: ItemlistPage());
                    case 'Spotify':
                      return SafeArea(
                        child: SpotifyTopPage(pageController: _pageController,
                        ),
                      );
                    // case 'YouTube':
                    //   return const SafeArea(child: YouTube());
                    default:
                      return const SafeArea(child: MusicPlayerHomePage());
                  }
                }).toList(),
              ),
            ),
          ],
        ),),
      ),
    );
  }

  Widget getRotatedDrawer(List<String> sections) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: ValueListenableBuilder(
        valueListenable: _selectedIndex,
        builder:
            (BuildContext context, int indexValue, Widget? child) {
          return NavigationRail(
            minWidth: 70.0,
            groupAlignment: 0.0,
            backgroundColor: Theme.of(context).cardColor,
            selectedIndex: indexValue,
            onDestinationSelected: (int index) {
              onItemTapped(index);
            },
            labelType: screenWidth > 1050
                ? NavigationRailLabelType.selected
                : NavigationRailLabelType.none,
            selectedLabelTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: TextStyle(color: Theme.of(context).iconTheme.color,),
            selectedIconTheme: Theme.of(context).iconTheme.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
            unselectedIconTheme: Theme.of(context).iconTheme,
            useIndicator: screenWidth < 1050,
            indicatorColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            leading: homeDrawer(
              context: context,
              padding: const EdgeInsets.symmetric(vertical: 5.0),
            ),
            destinations: sections.map((e) {
              switch (e) {
                case 'Home':
                  return NavigationRailDestination(
                    icon: const Icon(Icons.home_rounded),
                    label: Text(PlayerTranslationConstants.home.tr),
                  );
                case 'Playlists':
                  return NavigationRailDestination(
                    icon: const Icon(Icons.home_rounded),
                    label: Text(PlayerTranslationConstants.home.tr),
                  );
                case 'Spotify':
                  return NavigationRailDestination(
                    icon: const Icon(Icons.trending_up_rounded),
                    label: Text(
                      PlayerTranslationConstants.spotifyTopCharts.tr,
                    ),
                  );
                case 'YouTube':
                  return NavigationRailDestination(
                    icon: Icon(MdiIcons.youtube),
                    label:
                    Text(PlayerTranslationConstants.youTube.tr),
                  );
                default:
                  return NavigationRailDestination(
                    icon: const Icon(Icons.home_rounded),
                    label: Text(PlayerTranslationConstants.home.tr),
                  );
              }
            }).toList(),
          );
        },
      ),
    );
  }

  List<CustomBottomNavBarItem> _navBarItems(BuildContext context, List<String> sections) {
    return sections.map((section) {
      switch (section) {
        case 'Music':
          return CustomBottomNavBarItem(
            icon: const Icon(Icons.play_circle_fill),
            title: Text(PlayerTranslationConstants.music.tr),
            selectedColor: Theme.of(context).colorScheme.secondary,
          );
        case 'Playlists':
          return CustomBottomNavBarItem(
            icon: const Icon(Icons.library_music),
            title: Text(PlayerTranslationConstants.playlists.capitalizeFirst),
            selectedColor: Theme.of(context).colorScheme.secondary,
          );
        case 'Spotify':
          return CustomBottomNavBarItem(
            icon: Icon(MdiIcons.spotify),
            title: Text(PlayerTranslationConstants.topCharts.tr),
            selectedColor: Theme.of(context).colorScheme.secondary,
          );
        default:
          return CustomBottomNavBarItem(
            icon: const Icon(Icons.play_circle_fill),
            title: Text(PlayerTranslationConstants.music.tr),
            selectedColor: Theme.of(context).colorScheme.secondary,
          );
      }
    }).toList();
  }
}
