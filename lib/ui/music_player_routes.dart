import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../neom_music_player_app.dart';
import '../utils/constants/app_hive_constants.dart';
import '../utils/constants/music_player_route_constants.dart';
import 'drawer/recently_played/recently_played_page.dart';
import 'drawer/settings/music_player_settings_page.dart';
import 'drawer/stats/stats_page.dart';
import 'home/widgets/welcome_preference_page.dart';
import 'library/now_playing_page.dart';
import 'music_player_root_page.dart';

class MusicPlayerAppRoutes {

  static Widget initialFunction() {
    return Hive.box(AppHiveConstants.settings).get('userId') != null ? const MusicPlayerRootPage() : const WelcomePreferencePage();
  }

  static final Map<String, Widget Function(BuildContext)> routes = {
    MusicPlayerRouteConstants.root: (context) => initialFunction(),
    MusicPlayerRouteConstants.home: (context) => const NeomMusicPlayerApp(),
    MusicPlayerRouteConstants.pref: (context) => const WelcomePreferencePage(),
    MusicPlayerRouteConstants.setting: (context) => const MusicPlayerSettingsPage(),
    // MusicPlayerRouteConstants.player: (context) => MediaPlayerPage(),
    MusicPlayerRouteConstants.nowPlaying: (context) => const NowPlayingPage(),
    MusicPlayerRouteConstants.recent: (context) => const RecentlyPlayedPage(),
    // MusicPlayerRouteConstants.downloads: (context) => const Downloads(),
    MusicPlayerRouteConstants.stats: (context) => const StatsPage(),
  };
}
