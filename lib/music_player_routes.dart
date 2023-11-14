import 'package:get/get.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'neom_music_player_app.dart';
import 'ui/player/media_player_page.dart';
import 'ui/player/miniplayer.dart';

class MusicPlayerRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.musicPlayerHome,
        page: () => const NeomMusicPlayerApp(),
        transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.musicPlayerMedia,
      page: () => const MediaPlayerPage(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: AppRouteConstants.musicPlayerMini,
      page: () => const MiniPlayer(),
      transition: Transition.leftToRight,
    ),
  ];

}
