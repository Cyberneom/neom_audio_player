import 'package:get/get.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_music_player/neom_music_player_app.dart';

class MusicPlayerRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.musicPlayerHome,
        page: () => NeomMusicPlayerApp(),
        transition: Transition.zoom,
    ),
  ];

}
