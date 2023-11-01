import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'drawer/downloads/downloads.dart';
import 'drawer/library/now_playing_page.dart';
import 'drawer/library/recently_played.dart';
import 'drawer/library/stats.dart';
import 'drawer/settings/widgets/music_player_settings_page.dart';
import 'music_player_root_page.dart';
import 'player/media_player_page.dart';
import 'welcome_preference_page.dart';
import '../utils/constants/app_hive_constants.dart';
import '../utils/constants/music_player_route_constants.dart';

class MusicPlayerRoutes {

  static Widget initialFunction() {
    return Hive.box(AppHiveConstants.settings).get('userId') != null ? MusicPlayerRootPage() : WelcomePreferencePage();
  }

  static final Map<String, Widget Function(BuildContext)> routes = {
    MusicPlayerRouteConstants.root: (context) => initialFunction(),
    MusicPlayerRouteConstants.pref: (context) => const WelcomePreferencePage(),
    MusicPlayerRouteConstants.setting: (context) => const MusicPlayerSettingsPage(),
    MusicPlayerRouteConstants.player: (context) => MediaPlayerPage(),
    MusicPlayerRouteConstants.nowPlaying: (context) => NowPlayingPage(),
    MusicPlayerRouteConstants.recent: (context) => RecentlyPlayed(),
    MusicPlayerRouteConstants.downloads: (context) => const Downloads(),
    MusicPlayerRouteConstants.stats: (context) => const Stats(),
  };
}
