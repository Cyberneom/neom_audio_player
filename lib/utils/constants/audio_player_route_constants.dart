/// Route name constants shared by both `neom_audio_player` and
/// `neom_audio_platform`. Routes that point at pages still living in this
/// package are wired in [AudioPlayerRoutes]; routes that point at pages
/// owned by the platform layer are wired in `AudioPlatformRoutes`.
class AudioPlayerRouteConstants {

  // Player-owned routes
  static const String root = '/audioplayer';
  static const String media = '/audioplayer/media';
  static const String recent = '/audioplayer/recent';
  static const String setting = '/audioplayer/setting';
  static const String nowPlaying = '/audioplayer/nowPlaying';
  static const String downloads = '/audioplayer/downloads';

  // Platform-owned routes (pages live in `neom_audio_platform`).
  static const String home = '/audioplayer/home';
  static const String welcomePref = '/audioplayer/welcomePreferences';
  static const String stats = '/audioplayer/stats';
  static const String playlistPlayer = '/audioplayer/playlistPlayer';
  static const String search = '/audioplayer/search';
  static const String publicDomain = '/audioplayer/publicDomain';

}
