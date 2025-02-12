import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/implementations/app_drawer_controller.dart';
import 'package:neom_commons/core/ui/widgets/custom_widgets.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';
import 'package:neom_commons/core/utils/enums/verification_level.dart';
import '../../../utils/constants/audio_player_route_constants.dart';
import '../../../utils/enums/audio_player_drawer_menu.dart';
import '../library/playlist_player_page.dart';
import '../player/miniplayer_controller.dart';


class AudioPlayerDrawer extends StatelessWidget {

  const AudioPlayerDrawer({super.key});

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
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      _menuHeader(context, _),
                      const Divider(),
                      // drawerRowOption(AudioPlayerDrawerMenu.nowPlaying,  const Icon(Icons.queue_music_rounded,), context),
                      drawerRowOption(AudioPlayerDrawerMenu.lastSession, const Icon(Icons.history_rounded), context),
                      drawerRowOption(AudioPlayerDrawerMenu.favorites, const Icon(Icons.favorite_rounded), context),
                      drawerRowOption(AudioPlayerDrawerMenu.stats, const Icon(Icons.download_done_rounded,), context),
                      // drawerRowOption(MusicPlayerDrawerMenu.myMusic, const Icon(MdiIcons.folderMusic,), context),
                      // drawerRowOption(MusicPlayerDrawerMenu.downloads, const Icon(Icons.download_done_rounded,), context),
                      drawerRowOption(AudioPlayerDrawerMenu.settings, const Icon(Icons.playlist_play_rounded,), context),
                      if(AppFlavour.appInUse == AppInUse.e && _.user.userRole != UserRole.subscriber)
                      Column(
                        children: [
                          const Divider(),
                          Text(AppTranslationConstants.professionals.tr,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              fontSize: 20,
                              color: AppColor.lightGrey,
                              fontWeight: FontWeight.bold
                            ), ),
                          const Divider(),
                          drawerRowOption(AudioPlayerDrawerMenu.podcastUpload, const Icon(Icons.podcasts), context),
                          if(AppFlavour.appInUse == AppInUse.e)
                            drawerRowOption(AudioPlayerDrawerMenu.audiobookUpload, const Icon(Icons.multitrack_audio), context),
                        ],
                      ),
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
                  onPressed: () {
                    Get.find<MiniPlayerController>().setIsTimeline(true);
                    Get.offAllNamed(AppRouteConstants.home);
                  },
              ),
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
                      Text(_.appProfile.name.length > AppConstants.maxArtistNameLength
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

  ListTile drawerRowOption(AudioPlayerDrawerMenu selectedMenu, Icon icon, BuildContext context, {bool isEnabled = true}) {
    return ListTile(
      onTap: () {
        if(isEnabled) {
          switch(selectedMenu) {
            // case AudioPlayerDrawerMenu.nowPlaying:
            //   Navigator.pushNamed(context, AudioPlayerRouteConstants.nowPlaying);
            case AudioPlayerDrawerMenu.lastSession:
              Navigator.pushNamed(context, AudioPlayerRouteConstants.recent);
            case AudioPlayerDrawerMenu.favorites:
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => PlaylistPlayerPage(
                    alternativeName: AppTranslationConstants.favoriteItems.tr,
                  ),
                ),
              );
            case AudioPlayerDrawerMenu.downloads:
              Navigator.pushNamed(context, AudioPlayerRouteConstants.downloads);
            case AudioPlayerDrawerMenu.playlists:
              Get.toNamed(AppRouteConstants.lists);
            case AudioPlayerDrawerMenu.stats:
              Navigator.pushNamed(context, AudioPlayerRouteConstants.stats);
            case AudioPlayerDrawerMenu.settings:
              Navigator.pushNamed(context, AudioPlayerRouteConstants.setting);
            default:
              break;
          }
        }
      },
      leading: Padding(
        padding: const EdgeInsets.only(top: 5),
          child: icon,
      ),
      title: customText(
        selectedMenu.name.tr.capitalize,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 20,
          color: isEnabled ? AppColor.lightGrey : AppColor.secondary,
        ), context: context,
      ),
    );
  }

}
