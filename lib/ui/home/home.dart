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

import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/ui/spotify/spotify_top_page.dart';
import 'package:neom_music_player/ui/widgets/bottom_nav_bar.dart';
import 'package:neom_music_player/ui/widgets/drawer.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/miniplayer.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/music_player_route_constants.dart';
import 'package:neom_music_player/utils/helpers/route_handler.dart';
import 'package:neom_music_player/ui/music_player_routes.dart';
import 'package:neom_music_player/ui/Home/home_screen.dart';
import 'package:neom_music_player/ui/Player/audioplayer.dart';
import 'package:neom_music_player/ui/drawer/settings/new_settings_page.dart';
import 'package:neom_music_player/ui/spotify/spotify_top_page.dart' as top_screen;
import 'package:neom_music_player/ui/YouTube/youtube_home.dart';
import 'package:neom_music_player/ui/drawer/music_player_drawer.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  String name =
      Hive.box(AppHiveConstants.settings).get('name', defaultValue: 'Guest') as String;
  bool checkUpdate =
      Hive.box(AppHiveConstants.settings).get('checkUpdate', defaultValue: false) as bool;
  bool autoBackup =
      Hive.box(AppHiveConstants.settings).get('autoBackup', defaultValue: false) as bool;
  List sectionsToShow = Hive.box(AppHiveConstants.settings).get('sectionsToShow',
    defaultValue: ['Home', 'Top Charts', 'YouTube'],
  ) as List;
  DateTime? backButtonPressTime;
  final bool useDense = false;

  void callback() {
    sectionsToShow = Hive.box(AppHiveConstants.settings).get(
      'sectionsToShow',
      defaultValue: ['Home', 'Top Charts', 'YouTube'],
    ) as List;
    onItemTapped(0);
    setState(() {});
  }

  void onItemTapped(int index) {
    _selectedIndex.value = index;
    _controller.jumpToTab(
      index,
    );
  }

  // Future<bool> handleWillPop(BuildContext? context) async {
  //   if (context == null) return false;
  //   final now = DateTime.now();
  //   final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
  //       backButtonPressTime == null ||
  //           now.difference(backButtonPressTime!) > const Duration(seconds: 3);

  //   if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
  //     backButtonPressTime = now;
  //     ShowSnackBar().showSnackBar(
  //       context,
  //       PlayerTranslationConstants.exitConfirm.tr,
  //       duration: const Duration(seconds: 2),
  //       noAction: true,
  //     );
  //     return false;
  //   }
  //   return true;
  // }

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
    final bool rotated = MediaQuery.of(context).size.height < screenWidth;
    return GradientContainer(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColor.main75,
        drawer: MusicPlayerDrawer(),
        body: Row(
          children: [
            if (rotated)
              SafeArea(
                child: ValueListenableBuilder(
                  valueListenable: _selectedIndex,
                  builder:
                      (BuildContext context, int indexValue, Widget? child) {
                    return NavigationRail(
                      minWidth: 70.0,
                      groupAlignment: 0.0,
                      backgroundColor:
                          // Colors.transparent,
                          Theme.of(context).cardColor,
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
                      unselectedLabelTextStyle: TextStyle(
                        color: Theme.of(context).iconTheme.color,
                      ),
                      selectedIconTheme: Theme.of(context).iconTheme.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                      unselectedIconTheme: Theme.of(context).iconTheme,
                      useIndicator: screenWidth < 1050,
                      indicatorColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.2),
                      leading: homeDrawer(
                        context: context,
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                      ),
                      destinations: sectionsToShow.map((e) {
                        switch (e) {
                          case 'Home':
                            return NavigationRailDestination(
                              icon: const Icon(Icons.home_rounded),
                              label: Text(PlayerTranslationConstants.home.tr),
                            );
                          case 'Top Charts':
                            return NavigationRailDestination(
                              icon: const Icon(Icons.trending_up_rounded),
                              label: Text(
                                PlayerTranslationConstants.topCharts.tr,
                              ),
                            );
                          case 'YouTube':
                            return NavigationRailDestination(
                              icon: const Icon(MdiIcons.youtube),
                              label:
                                  Text(PlayerTranslationConstants.youTube.tr),
                            );
                          default:
                            return NavigationRailDestination(
                              icon: const Icon(Icons.settings_rounded),
                              label: Text(
                                PlayerTranslationConstants.settings.tr,
                              ),
                            );
                        }
                      }).toList(),
                    );
                  },
                ),
              ),
            Expanded(
              child: PersistentTabView.custom(
                context,
                controller: _controller,
                itemCount: sectionsToShow.length,
                navBarHeight: (rotated ? 55 : 55 + 70) + (useDense ? 0 : 15),
                // confineInSafeArea: false,
                onItemTapped: onItemTapped,
                routeAndNavigatorSettings:
                    CustomWidgetRouteAndNavigatorSettings(
                  routes: MusicPlayerRoutes.namedRoutes,
                  onGenerateRoute: (RouteSettings settings) {
                    if (settings.name == MusicPlayerRouteConstants.player) {
                      return PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => const PlayScreen(),
                      );
                    }
                    return HandleRoute.handleRoute(settings.name);
                  },
                ),
                customWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MiniPlayer(),
                    if (!rotated)
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
                              backgroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.9),
                              onTap: (index) {
                                onItemTapped(index);
                              },
                              items: _navBarItems(context),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                screens: sectionsToShow.map((e) {
                  switch (e) {
                    case 'Home':
                      return const SafeArea(child: HomeScreen());
                    case 'Top Charts':
                      return SafeArea(
                        child: SpotifyTopPage(
                          pageController: _pageController,
                        ),
                      );
                    case 'YouTube':
                      return const SafeArea(child: YouTube());
                    default:
                      return NewSettingsPage(callback: callback);
                  }
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CustomBottomNavBarItem> _navBarItems(BuildContext context) {
    return sectionsToShow.map((section) {
      switch (section) {
        case 'Home':
          return CustomBottomNavBarItem(
            icon: const Icon(Icons.home_rounded),
            title: Text(PlayerTranslationConstants.home.tr),
            selectedColor: Theme.of(context).colorScheme.secondary,
          );
        case 'Top Charts':
          return CustomBottomNavBarItem(
            icon: const Icon(Icons.trending_up_rounded),
            title: Text(PlayerTranslationConstants.topCharts.tr),
            selectedColor: Theme.of(context).colorScheme.secondary,
          );
        case 'YouTube':
          return CustomBottomNavBarItem(
            icon: const Icon(MdiIcons.youtube),
            title: Text(PlayerTranslationConstants.youTube.tr),
            selectedColor: Theme.of(context).colorScheme.secondary,
          );
        default:
          return CustomBottomNavBarItem(
            icon: const Icon(Icons.settings_rounded),
            title: Text(PlayerTranslationConstants.settings.tr),
            selectedColor: Theme.of(context).colorScheme.secondary,
          );
      }
    }).toList();
  }
}
