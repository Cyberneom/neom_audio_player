
class AppHiveConstants {

  static const hiveBoxes = [
    {name: settings, limit: false},
    {name: downloads, limit: false},
    {name: stats, limit: false},
    {name: favoriteSongs, limit: false},
    {name: cache, limit: true},
  ];

  static const String userId = 'userId';
  static const String name = 'name';
  static const String limit = 'limit';
  static const String settings = 'settings';
  static const String downloads = 'downloads';
  static const String stats = 'stats';
  static const String favoriteSongs = 'favoriteSongs';
  static const String cache = 'cache';
  static const String region = 'region';
  static const String preferredLanguage = 'preferredLanguage';
  static const String useProxy = 'useProxy';

  ///STATS
  static const String recentSongs = 'recentSongs';
  static const String mostPlayed = 'mostPlayed';
  static const String lastPlayed = 'lastPlayed';
  static const String playCount = 'playCount';
  static const String title = 'title';
  static const String artist = 'artist';
  static const String album = 'album';
  static const String id = 'id';

  static const String lastIndex = 'lastIndex';
  static const String lastPos = 'lastPos';
  static const String lastQueue = 'lastQueue';
  static const String resetOnSkip = 'resetOnSkip';

}
