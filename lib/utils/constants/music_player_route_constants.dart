
import 'package:neom_itemlists/itemlists/ui/itemlist_page.dart';

import '../../ui/home/music_player_home_page.dart';

class MusicPlayerRouteConstants {

  static final eMusicPlayerPages = [const MusicPlayerHomePage(), const ItemlistPage()];
  static final gMusicPlayerPages = [const MusicPlayerHomePage(), const ItemlistPage()];
  static final cMusicPlayerPages = [const MusicPlayerHomePage(), const ItemlistPage()];

  static const String root = '/';
  static const String home = '/home';
  static const String media = '/media';
  static const String mini = '/mini';
  static const String recent = '/recent';
  static const String pref = '/pref';
  static const String setting = '/setting';
  static const String playlists = '/playlists';
  static const String nowPlaying = '/nowPlaying';
  static const String downloads = '/downloads';
  static const String stats = '/stats';

}
