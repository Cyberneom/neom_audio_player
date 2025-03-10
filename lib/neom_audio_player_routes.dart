import 'package:get/get.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'neom_audio_player_app.dart';
import 'ui/audio_player_root_page.dart';
import 'ui/player/media_player_page.dart';
import 'ui/player/miniplayer.dart';

class NeomAudioPlayerRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.audioPlayerHome,
        page: () => const AudioPlayerRootPage(),
        transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRouteConstants.audioPlayerMedia,
      page: () => const MediaPlayerPage(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: AppRouteConstants.audioPlayerMini,
      page: () => const MiniPlayer(),
      transition: Transition.leftToRight,
    ),
  ];

}
