/// Pure helpers for the per-user audio quality swap.
///
/// Tracks are stored server-side with a quality suffix in their URL
/// (`song_96.mp3` for the baseline 96 kbps variant). When the user picks a
/// preferred quality in settings, the handler rewrites `_96.` to the
/// preferred bitrate (`_320.`) at source-build time. If that variant was
/// never generated server-side, playback 404s — the recovery flow then sets
/// `extras['noQualitySwap']` on the item and retries the original file.
class AudioQualitySwap {

  /// Extras flag that disables the quality rewrite for a media item.
  static const String noSwapFlag = 'noQualitySwap';

  static const String _baselineSuffix = '_96.';

  /// Applies the preferred-quality rewrite to [url].
  ///
  /// Returns [url] unchanged when no preferred quality is configured, the
  /// URL carries no baseline `_96.` suffix, or the preference is malformed.
  static String apply(String url, String preferredQuality) {
    if (preferredQuality.isEmpty || !url.contains(_baselineSuffix)) {
      return url;
    }
    final kbps = preferredQuality.replaceAll(' kbps', '').trim();
    if (kbps.isEmpty || int.tryParse(kbps) == null) return url;
    return url.replaceAll(_baselineSuffix, '_$kbps.');
  }

  /// True when [apply] would actually rewrite [url] — meaning a playback
  /// failure may be caused by a swapped variant that does not exist
  /// server-side, and bypassing the swap is a meaningful retry.
  static bool wouldSwap(String url, String preferredQuality) =>
      apply(url, preferredQuality) != url;
}
