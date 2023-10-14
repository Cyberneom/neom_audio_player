/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:neom_music_player/ui/drawer/downloads/downloads.dart';
import 'package:neom_music_player/ui/drawer/library/now_playing_page.dart';
import 'package:neom_music_player/ui/drawer/library/recently_played.dart';
import 'package:neom_music_player/ui/drawer/library/stats.dart';
import 'package:neom_music_player/ui/drawer/settings/widgets/music_player_settings_page.dart';
import 'package:neom_music_player/ui/music_player_root_page.dart';
import 'package:neom_music_player/ui/player/media_player_page.dart';
import 'package:neom_music_player/ui/welcome_preference_page.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/music_player_route_constants.dart';

class MusicPlayerRoutes {

  static Widget initialFunction() {
    return Hive.box(AppHiveConstants.settings).get('userId') != null ? MusicPlayerRootPage() : WelcomePreferencePage();
  }

  static final Map<String, Widget Function(BuildContext)> routes = {
    MusicPlayerRouteConstants.root: (context) => initialFunction(),
    MusicPlayerRouteConstants.pref: (context) => const WelcomePreferencePage(),
    MusicPlayerRouteConstants.setting: (context) => const MusicPlayerSettingsPage(),
    MusicPlayerRouteConstants.player: (context) => MediaPlayerPage(),
    // MusicPlayerRouteConstants.playlists: (context) => PlaylistPage(),
    MusicPlayerRouteConstants.nowPlaying: (context) => NowPlayingPage(),
    MusicPlayerRouteConstants.recent: (context) => RecentlyPlayed(),
    MusicPlayerRouteConstants.downloads: (context) => const Downloads(),
    MusicPlayerRouteConstants.stats: (context) => const Stats(),
  };
}
