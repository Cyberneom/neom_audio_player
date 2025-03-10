import 'package:flutter/material.dart';

import '../neom_audio_player_app.dart';
import '../utils/constants/audio_player_route_constants.dart';
import 'audio_player_root_page.dart';
import 'drawer/recently_played/recently_played_page.dart';
import 'drawer/settings/audio_player_settings_page.dart';
import 'drawer/stats/stats_page.dart';
import 'home/widgets/welcome_preference_page.dart';
import 'library/now_playing_page.dart';

class AudioPlayerRoutes {

  ///In the meantime we get more catalog and items "welcomePrefs" would be skipped"
  static Widget initialFunction() {
    return const AudioPlayerRootPage();
    // if(Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.userId) != null || AppFlavour.appInUse == AppInUse.e) {
    //   return const AudioPlayerRootPage();
    // } else {
    //   return const WelcomePreferencePage();
    // }
  }

  static final Map<String, Widget Function(BuildContext)> routes = {
    AudioPlayerRouteConstants.root: (context) => initialFunction(),
    AudioPlayerRouteConstants.home: (context) => const AudioPlayerRootPage(),
    AudioPlayerRouteConstants.pref: (context) => const WelcomePreferencePage(),
    AudioPlayerRouteConstants.setting: (context) => const AudioPlayerSettingsPage(),
    /// MusicPlayerRouteConstants.player: (context) => MediaPlayerPage(),
    ///DEPRECATED AudioPlayerRouteConstants.nowPlaying: (context) => const NowPlayingPage(),
    AudioPlayerRouteConstants.recent: (context) => const RecentlyPlayedPage(),
    /// MusicPlayerRouteConstants.downloads: (context) => const Downloads(),
    AudioPlayerRouteConstants.stats: (context) => const StatsPage(),
  };
}
