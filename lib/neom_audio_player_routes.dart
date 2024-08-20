import 'package:get/get.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'neom_audio_player_app.dart';
import 'ui/player/media_player_page.dart';
import 'ui/player/miniplayer.dart';

class NeomAudioPlayerRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.musicPlayerHome,
        page: () => const NeomAudioPlayerApp(),
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