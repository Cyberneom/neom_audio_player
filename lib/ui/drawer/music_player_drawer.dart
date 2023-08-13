import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/implementations/app_drawer_controller.dart';
import 'package:neom_commons/core/ui/widgets/custom_widgets.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_music_player/ui/drawer/library/liked.dart';
import 'package:neom_music_player/ui/drawer/local_music/downed_songs.dart';
import 'package:neom_music_player/ui/drawer/settings/widgets/music_player_settings_page.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/music_player_route_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:neom_music_player/utils/enums/music_player_drawer_menu.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

class MusicPlayerDrawer extends StatelessWidget {
  MusicPlayerDrawer({Key? key}) : super(key: key);


  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);

  List sectionsToShow = ['Home', 'Spotify', 'YouTube'];
  final PersistentTabController _controller = PersistentTabController();

  void callback() {
    sectionsToShow = ['Home', 'Spotify', 'YouTube'];
    onItemTapped(0);
  }

  void onItemTapped(int index) {
    _selectedIndex.value = index;
    _controller.jumpToTab(
      index,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppDrawerController>(
    id: AppPageIdConstants.appDrawer,
    init: AppDrawerController(),
    builder: (_) {
      return Drawer(
        child: Container(
          color: AppColor.drawer,
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      Obx(()=>_menuHeader(context, _)),
                      const Divider(),
                      drawerRowOption(MusicPlayerDrawerMenu.nowPlaying,  const Icon(Icons.queue_music_rounded,), context),
                      drawerRowOption(MusicPlayerDrawerMenu.playlists, const Icon(Icons.playlist_play_rounded,), context),
                      drawerRowOption(MusicPlayerDrawerMenu.lastSession, const Icon(Icons.history_rounded), context),
                      drawerRowOption(MusicPlayerDrawerMenu.favorites, const Icon(Icons.favorite_rounded), context),
                      drawerRowOption(MusicPlayerDrawerMenu.myMusic, const Icon(MdiIcons.folderMusic,), context),
                      drawerRowOption(MusicPlayerDrawerMenu.stats, const Icon(Icons.download_done_rounded,), context),
                      drawerRowOption(MusicPlayerDrawerMenu.downloads, const Icon(Icons.download_done_rounded,), context),
                      drawerRowOption(MusicPlayerDrawerMenu.settings, const Icon(Icons.playlist_play_rounded,), context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },);
  }

  Widget _menuHeader(BuildContext context, AppDrawerController _) {
    if (_.user.id.isEmpty) {
      return customInkWell(
        context: context,
        onPressed: () {
          Get.offAllNamed(AppRouteConstants.login);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, minHeight: 100),
          child: Center(
            child: Text(
              PlayerTranslationConstants.loginToContinue.tr,
              style: AppTheme.primaryTitleText,
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListTile(
              onTap: () {
                Get.toNamed(AppRouteConstants.profile);
              },
              leading: IconButton(
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: ()=> Get.offAllNamed(AppRouteConstants.home),),
              title: Row(
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        child: Container(
                          height: 56,
                          width: 56,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(28),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(_.appProfile.photoUrl.isNotEmpty
                                  ? _.appProfile.photoUrl : AppFlavour.getNoImageUrl(),),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        onTap: ()=> Get.toNamed(AppRouteConstants.profile),
                      ),
                      Text(
                        _.appProfile.name.length > AppConstants.maxArtistNameLength
                            ? '${_.appProfile.name.substring(0,AppConstants.maxArtistNameLength)}...' : _.appProfile.name,
                        style: AppTheme.primaryTitleText,
                        overflow: TextOverflow.fade,
                      ),
                    ],
                  ),
                ],),
            ),
          ],
        ),
      );
    }
  }

  ListTile drawerRowOption(MusicPlayerDrawerMenu selectedMenu, Icon icon, BuildContext context, {bool isEnabled = true}) {
    return ListTile(
      onTap: () {
        if(isEnabled) {
          switch(selectedMenu) {
            case MusicPlayerDrawerMenu.nowPlaying:
              Navigator.pushNamed(context, MusicPlayerRouteConstants.nowPlaying);
            case MusicPlayerDrawerMenu.lastSession:
              Navigator.pushNamed(context, '/recent');
            case MusicPlayerDrawerMenu.favorites:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LikedSongs(
                    playlistName: AppHiveConstants.favoriteSongs,
                    showName: PlayerTranslationConstants.favSongs.tr,
                  ),
                ),
              );
            case MusicPlayerDrawerMenu.myMusic:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DownloadedSongs(showPlaylists: true,),
                ),
              );
            case MusicPlayerDrawerMenu.downloads:
              Navigator.pushNamed(context, MusicPlayerRouteConstants.downloads);
            case MusicPlayerDrawerMenu.playlists:
              Navigator.pushNamed(context, MusicPlayerRouteConstants.playlists);
            case MusicPlayerDrawerMenu.stats:
              Navigator.pushNamed(context, MusicPlayerRouteConstants.stats);
            case MusicPlayerDrawerMenu.settings:
              final idx =
              sectionsToShow.indexOf(MusicPlayerRouteConstants.setting);
              if (idx != -1) {
                if (_selectedIndex.value != idx) {
                  onItemTapped(idx);
                }
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MusicPlayerSettingsPage(callback: callback),
                  ),
                );
              }
            default:
              break;
          }
        }
      },
      leading: Container(
          padding: const EdgeInsets.only(top: 5),
          child: icon,
      ),
      title: customText(
        selectedMenu.name.tr.capitalize!,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 20,
          color: isEnabled ? AppColor.lightGrey : AppColor.secondary,
        ), context: context,
      ),
    );
  }

}
