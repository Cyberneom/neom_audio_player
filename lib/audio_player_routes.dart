import 'package:sint/sint.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/ui/deferred_loader.dart';

import 'ui/drawer/recently_played/recently_played_page.dart' deferred as recentlyPlayed;
import 'ui/drawer/settings/audio_player_settings_page.dart' deferred as audioSettings;
import 'ui/player/audio_player_page.dart' deferred as audioPlayer;
import 'ui/player/miniplayer.dart' deferred as miniPlayer;
import 'utils/constants/audio_player_route_constants.dart';

/// Module-owned [SintPage] route table for `neom_audio_player`.
///
/// Spread this list into your host app's `app_routes.dart` to wire every
/// page exposed by the module (full player, home feed, library, drawer
/// settings, web layout, etc.) without manually re-declaring each route:
///
/// ```dart
/// final List<SintPage> appPages = [
///   ...AudioPlayerRoutes.routes,
///   // ...other module routes
/// ];
/// ```
///
/// Route name constants live in `AudioPlayerRouteConstants` (re-exported
/// from this module's barrel) so you can navigate via
/// `Sint.toNamed(AudioPlayerRouteConstants.audioPlayer)` from anywhere.
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
      page: () => DeferredLoader(audioPlayer.loadLibrary, () => audioPlayer.AudioPlayerPage()),
      transition: Transition.leftToRight,
    ),
    SintPage(
      name: AppRouteConstants.audioPlayerMini,
      page: () => DeferredLoader(miniPlayer.loadLibrary, () => miniPlayer.MiniPlayer()),
      transition: Transition.leftToRight,
    ),
    SintPage(
      name: AudioPlayerRouteConstants.setting,
      page: () => DeferredLoader(audioSettings.loadLibrary, () => audioSettings.AudioPlayerSettingsPage()),
      transition: Transition.leftToRight,
    ),
    SintPage(
      name: AudioPlayerRouteConstants.recent,
      page: () => DeferredLoader(recentlyPlayed.loadLibrary, () => recentlyPlayed.RecentlyPlayedPage()),
      transition: Transition.leftToRight,
    ),
    // NOTE: `welcomePref` and `stats` routes have moved to
    // `neom_audio_platform`'s `AudioPlatformRoutes` because the underlying
    // pages depend on platform controllers (home + listening stats).
  ];

}
