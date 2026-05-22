import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sint/sint.dart';

import '../../domain/use_cases/artwork_color_service.dart';

/// Concrete [ArtworkColorService] that extracts dominant colors from artwork
/// images using [PaletteGenerator] and caches them in memory.
///
/// Concurrent requests for the same key are coalesced to avoid duplicate work.
/// The [currentColor] reactive observable can be used with [Obx] to rebuild
/// UI when the playing track changes.
class ArtworkColorController extends SintController
    implements ArtworkColorService {

  static const int _maxCacheSize = 100;

  final Map<String, Color> _cache = <String, Color>{};
  final Set<String> _inFlight = <String>{};

  /// Reactive observable for the currently playing track's dominant color.
  final Rx<Color> _currentColor = AppColor.getMain().obs;

  @override
  Color get currentColor => _currentColor.value;

  /// Reactive accessor for use with [Obx].
  Rx<Color> get currentColorRx => _currentColor;

  @override
  Color cachedOrFallback(String? cacheKey) {
    if (cacheKey == null || cacheKey.isEmpty) return AppColor.getMain();
    return _cache[cacheKey] ?? AppColor.getMain();
  }

  @override
  Future<Color> extractColor({
    required String cacheKey,
    required String? imageUrl,
    Color? fallback,
  }) async {
    final fb = fallback ?? AppColor.getMain();

    if (cacheKey.isEmpty) return fb;
    final cached = _cache[cacheKey];
    if (cached != null) {
      _currentColor.value = cached;
      return cached;
    }
    if (imageUrl == null || imageUrl.isEmpty) return fb;
    if (_inFlight.contains(cacheKey)) return fb;

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
          ?? fb;

      _enforceCacheLimit();
      _cache[cacheKey] = color;
      _currentColor.value = color;
      return color;
    } catch (_) {
      return fb;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  @override
  void clearCache() {
    _cache.clear();
    _inFlight.clear();
    _currentColor.value = AppColor.getMain();
  }

  void _enforceCacheLimit() {
    if (_cache.length >= _maxCacheSize) {
      final keysToRemove = _cache.keys.take(_cache.length - _maxCacheSize + 10).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
    }
  }

}
