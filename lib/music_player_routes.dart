import 'package:get/get.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'neom_music_player_app.dart';

class MusicPlayerRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.musicPlayerHome,
        page: () => const NeomMusicPlayerApp(),
        transition: Transition.zoom,
    ),
  ];

}
