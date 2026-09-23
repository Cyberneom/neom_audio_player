/// Web implementation — the browser manages its own HTTP cache and there are
/// no whole-file song downloads to measure or evict.
class AudioCacheStore {
  AudioCacheStore._();

  static const int defaultMaxBytes = 500 * 1024 * 1024;

  static Future<int> sizeBytes() async => 0;

  static Future<int> clear() async => 0;

  static Future<int> enforceLimit({int maxBytes = defaultMaxBytes}) async => 0;

  static Future<void> markPlayed(Object file) async {}
}
