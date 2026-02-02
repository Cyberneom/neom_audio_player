import 'package:sint/sint.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import 'ui/drawer/recently_played/recently_played_page.dart';
import 'ui/drawer/settings/audio_player_settings_page.dart';
import 'ui/drawer/stats/stats_page.dart';
import 'ui/home/widgets/welcome_preference_page.dart';
import 'ui/player/audio_player_page.dart';
import 'ui/player/miniplayer.dart';
import 'utils/constants/audio_player_route_constants.dart';

class AudioPlayerRoutes {

  static final List<SintPage<dynamic>> routes = [
    ///UNCOMMENT THIS IN ORDER TO ENABLE AUDIO PLAYER HOME PAGE
    // SintPage(
    //     name: AppRouteConstants.audioPlayer,
    //     page: () => const AudioPlayerRootPage(),
    //     transition: Transition.rightToLeftWithFade,
    // ),
    SintPage(
      name: AppRouteConstants.audioPlayerMedia,
      page: () => const AudioPlayerPage(),
      transition: Transition.leftToRight,
    ),
    SintPage(
      name: AppRouteConstants.audioPlayerMini,
      page: () => const MiniPlayer(),
      transition: Transition.leftToRight,
    ),
    SintPage(
      name: AudioPlayerRouteConstants.welcomePref,
      page: () => const WelcomePreferencePage(),
      transition: Transition.leftToRight,
    ),
    SintPage(
      name: AudioPlayerRouteConstants.setting,
      page: () => const AudioPlayerSettingsPage(),
      transition: Transition.leftToRight,
    ),
    SintPage(
      name: AudioPlayerRouteConstants.recent,
      page: () => const RecentlyPlayedPage(),
      transition: Transition.leftToRight,
    ),
    SintPage(
      name: AudioPlayerRouteConstants.stats,
      page: () => const StatsPage(),
      transition: Transition.leftToRight,
    ),
  ];

}
