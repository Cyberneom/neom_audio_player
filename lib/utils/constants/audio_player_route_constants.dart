
import 'package:neom_itemlists/itemlists/ui/itemlist_page.dart';

import '../../ui/home/audio_player_home_page.dart';

class AudioPlayerRouteConstants {

  static final audioPlayerPages = [const AudioPlayerHomePage(), const ItemlistPage()];

  static const String root = '/audioplayer';
  static const String home = '/audioplayer/home';
  static const String media = '/audioplayer/media';
  // static const String mini = '/audioplayer/mini';
  static const String recent = '/audioplayer/recent';
  static const String welcomePref = '/audioplayer/welcomePreferences';
  static const String setting = '/audioplayer/setting';
  // static const String playlists = '/audioplayer/playlists';
  static const String nowPlaying = '/audioplayer/nowPlaying';
  static const String downloads = '/audioplayer/downloads';
  static const String stats = '/audioplayer/stats';

}
