import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';

import '../audio_player_app.dart';
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
    if(Hive.box(AppHiveConstants.settings).get(AppHiveConstants.userId) != null || AppFlavour.appInUse == AppInUse.e) {
      return const MusicPlayerRootPage();
    } else {
      return const WelcomePreferencePage();
    }
  }

  static final Map<String, Widget Function(BuildContext)> routes = {
    MusicPlayerRouteConstants.root: (context) => initialFunction(),
    MusicPlayerRouteConstants.home: (context) => const AudioPlayerApp(),
    MusicPlayerRouteConstants.pref: (context) => const WelcomePreferencePage(),
    MusicPlayerRouteConstants.setting: (context) => const MusicPlayerSettingsPage(),
    // MusicPlayerRouteConstants.player: (context) => MediaPlayerPage(),
    MusicPlayerRouteConstants.nowPlaying: (context) => const NowPlayingPage(),
    MusicPlayerRouteConstants.recent: (context) => const RecentlyPlayedPage(),
    // MusicPlayerRouteConstants.downloads: (context) => const Downloads(),
    MusicPlayerRouteConstants.stats: (context) => const StatsPage(),
  };
}
