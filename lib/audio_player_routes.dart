import 'package:get/get.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'audio_player_app.dart';
import 'ui/player/media_player_page.dart';
import 'ui/player/miniplayer.dart';

class AudioPlayerRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.musicPlayerHome,
        page: () => const AudioPlayerApp(),
        transition: Transition.rightToLeftWithFade,
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
