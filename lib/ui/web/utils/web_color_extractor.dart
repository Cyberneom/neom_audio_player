import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:palette_generator/palette_generator.dart';

/// Extracts a dominant color from an artwork URL and caches it in memory.
///
/// Used by the web layout to drive ambient gradients in the bottom player,
/// the full-screen now playing view and the queue panel.
///
/// The cache is module-scoped (no Hive persistence) to keep the helper free
/// of side effects and easy to reason about.
class WebColorExtractor {
  WebColorExtractor._();

  static final Map<String, Color> _cache = <String, Color>{};
  static final Set<String> _inFlight = <String>{};

  /// Returns a cached color if available, otherwise the brand fallback.
  /// Use [extract] to populate the cache asynchronously.
  static Color cachedOrFallback(String? key) {
    if (key == null || key.isEmpty) return AppColor.getMain();
    return _cache[key] ?? AppColor.getMain();
  }

  /// Resolves the dominant color for [imageUrl] and stores it under [cacheKey].
  ///
  /// Returns the brand fallback on any failure (CORS, decode errors, etc.).
  /// Safe to call repeatedly: concurrent calls for the same key are coalesced.
  static Future<Color> extract({
    required String cacheKey,
    required String? imageUrl,
  }) async {
    if (cacheKey.isEmpty) return AppColor.getMain();
    final cached = _cache[cacheKey];
    if (cached != null) return cached;
    if (imageUrl == null || imageUrl.isEmpty) return AppColor.getMain();
    if (_inFlight.contains(cacheKey)) return AppColor.getMain();

    _inFlight.add(cacheKey);
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(80, 80),
        maximumColorCount: 8,
      );
      final color = palette.vibrantColor?.color
          ?? palette.dominantColor?.color
          ?? palette.mutedColor?.color
          ?? AppColor.getMain();
      _cache[cacheKey] = color;
      return color;
    } catch (_) {
      return AppColor.getMain();
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  /// Clears the cache. Intended for tests or memory pressure callbacks.
  static void clear() {
    _cache.clear();
    _inFlight.clear();
  }
}
