import 'package:flutter/material.dart';

/// Abstract service for extracting dominant colors from artwork images.
///
/// Implementations provide in-memory caching, coalesced concurrent requests,
/// and integration with the player controller for dynamic theme coloring.
abstract class ArtworkColorService {

  /// Extracts the dominant color from an artwork image URL.
  ///
  /// Returns a cached result if available; otherwise fetches asynchronously.
  /// Falls back to [fallback] on any failure.
  Future<Color> extractColor({
    required String cacheKey,
    required String? imageUrl,
    Color? fallback,
  });

  /// Returns a cached color if available, otherwise the brand fallback.
  Color cachedOrFallback(String? cacheKey);

  /// The currently active dominant color for the playing track.
  Color get currentColor;

  /// Clears the in-memory color cache.
  void clearCache();

}
