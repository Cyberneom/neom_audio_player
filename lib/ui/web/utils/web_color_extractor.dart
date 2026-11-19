import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';

/// Extracts a dominant color from an artwork URL and caches it in memory.
///
/// Used by the web layout to drive ambient gradients in the bottom player,
/// the full-screen now playing view and the queue panel.
///
/// The cache is module-scoped (no Hive persistence) to keep the helper free
/// of side effects and easy to reason about.
class WebColorExtractor {
  WebColorExtractor._();

  static const int maxCacheEntries = 512;
  static final RegExp _unsafeKeyOrUrlChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _encodedTraversalOrBidi = RegExp(
    r'%(?:00|2e|2f|5c|25|c2%[89][0-9a-f]|e2%80%(?:8[b-f]|a[8-e])|e2%81%a[0-9]|d8%9c|ef%bb%bf)',
    caseSensitive: false,
  );
  static final RegExp _idnDotHomoglyphs = RegExp(r'[\u3002\uFF0E\uFF61]');
  static final RegExp _reservedDunderKey = RegExp(r'^__.*__$');
  static final RegExp _safeRasterDataImage = RegExp(
    r'^data:image/(?:png|jpe?g|webp|gif|bmp|avif)(?:;|,)',
    caseSensitive: false,
  );
  static final RegExp _svgExt = RegExp(
    r'\.svgz?(?:$|[?#])',
    caseSensitive: false,
  );
  static final RegExp _nonStandardIpv4Literal = RegExp(
    r'^(?:\d+|0x[0-9a-f]+|0[0-7]+)(?:\.(?:\d+|0x[0-9a-f]+|0[0-7]+)){0,3}$',
    caseSensitive: false,
  );

  static const Duration _extractTimeout = Duration(seconds: 6);
  static const int _quantizeSizePx = 64;

  static final Map<String, Color> _cache = <String, Color>{};
  static final Map<String, Future<Color>> _inFlight = <String, Future<Color>>{};

  static bool isSafeCacheKey(String? rawKey) {
    if (rawKey == null ||
        rawKey.isEmpty ||
        rawKey.length > 512 ||
        _unsafeKeyOrUrlChars.hasMatch(rawKey) ||
        _encodedTraversalOrBidi.hasMatch(rawKey)) {
      return false;
    }
    final clean = rawKey.trim();
    final lower = clean.toLowerCase();
    if (clean.isEmpty ||
        clean == '.' ||
        clean == '..' ||
        clean.contains('..') ||
        lower == '__proto__' ||
        lower == 'constructor' ||
        lower == 'prototype' ||
        _reservedDunderKey.hasMatch(lower)) {
      return false;
    }
    return true;
  }

  static bool isSafeWebArtworkUrl(String? rawUrl) {
    if (rawUrl == null ||
        _unsafeKeyOrUrlChars.hasMatch(rawUrl) ||
        _idnDotHomoglyphs.hasMatch(rawUrl) ||
        _encodedTraversalOrBidi.hasMatch(rawUrl)) {
      return false;
    }
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty || trimmed.length > 4096) return false;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('javascript:') ||
        lower.startsWith('vbscript:') ||
        lower.startsWith('file:')) {
      return false;
    }
    if (lower.startsWith('data:')) {
      return _safeRasterDataImage.hasMatch(trimmed);
    }
    if (lower.startsWith('blob:')) {
      return !lower.startsWith('blob:null/') && !trimmed.contains(r'\');
    }
    if (trimmed.contains(r'\') || _svgExt.hasMatch(trimmed)) {
      return false;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.host.isEmpty ||
        uri.pathSegments.any((s) => s == '..') ||
        _svgExt.hasMatch(uri.path)) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') return false;
    var host = uri.host.toLowerCase().trim();
    if (host.startsWith('[') && host.endsWith(']')) {
      host = host.substring(1, host.length - 1);
    }
    while (host.endsWith('.')) {
      host = host.substring(0, host.length - 1);
    }
    if (host.isEmpty ||
        host.contains('%') ||
        host == 'null' ||
        host == 'localhost' ||
        host == '0.0.0.0' ||
        host == '255.255.255.255' ||
        host == '::1' ||
        host == '::' ||
        host == 'metadata' ||
        host == 'instance-data' ||
        host == 'metadata.goog' ||
        host.endsWith('.metadata.goog') ||
        host == 'metadata.google.internal' ||
        host.endsWith('.metadata.google.internal') ||
        host == 'metadata.azure.com' ||
        host.endsWith('.metadata.azure.com') ||
        host == 'metadata.azure.internal' ||
        host.endsWith('.metadata.azure.internal') ||
        host.endsWith('.local') ||
        host.endsWith('.internal') ||
        host.endsWith('.localhost') ||
        host.endsWith('.lan') ||
        host.endsWith('.corp') ||
        host.endsWith('.home.arpa') ||
        host.endsWith('.ts.net') ||
        host.endsWith('.onion') ||
        host.endsWith('.invalid') ||
        (!host.contains(':') && !host.contains('.'))) {
      return false;
    }
    final parts = host.split('.');
    final isCanonicalDottedDecimal =
        parts.length == 4 &&
        parts.every((p) {
          if (p.isEmpty || (p.length > 1 && p.startsWith('0'))) return false;
          final v = int.tryParse(p);
          return v != null && v >= 0 && v <= 255;
        });
    if (isCanonicalDottedDecimal) {
      final a = int.parse(parts[0]);
      final b = int.parse(parts[1]);
      if (a == 0 ||
          a == 10 ||
          a == 127 ||
          (a == 100 && b >= 64 && b <= 127) ||
          (a == 169 && b == 254) ||
          (a == 172 && b >= 16 && b <= 31) ||
          (a == 192 && b == 168) ||
          a >= 224) {
        return false;
      }
    } else if (_nonStandardIpv4Literal.hasMatch(host)) {
      return false;
    }
    if (host.contains(':')) {
      if (host.startsWith('fe80:') ||
          host.startsWith('fc') ||
          host.startsWith('fd') ||
          host.startsWith('ff') ||
          host.startsWith('::ffff:')) {
        return false;
      }
    }
    return true;
  }

  /// Returns a cached color if available, otherwise the brand fallback.
  /// Use [extract] to populate the cache asynchronously.
  static Color cachedOrFallback(String? key) {
    if (!isSafeCacheKey(key)) return AppColor.getMain();
    final cleanKey = key!.trim();
    final hit = _cache.remove(cleanKey);
    if (hit != null) {
      _cache[cleanKey] = hit;
      return hit;
    }
    return AppColor.getMain();
  }

  /// Resolves the dominant color for [imageUrl] and stores it under [cacheKey].
  ///
  /// Returns the brand fallback on any failure (CORS, decode errors, etc.).
  /// Safe to call repeatedly: concurrent calls for the same key are coalesced.
  static Future<Color> extract({
    required String cacheKey,
    required String? imageUrl,
  }) async {
    if (!isSafeCacheKey(cacheKey)) return AppColor.getMain();
    final cleanKey = cacheKey.trim();
    final cached = _cache.remove(cleanKey);
    if (cached != null) {
      _cache[cleanKey] = cached;
      return cached;
    }
    if (!isSafeWebArtworkUrl(imageUrl)) return AppColor.getMain();
    final existing = _inFlight[cleanKey];
    if (existing != null) return existing;
    if (_inFlight.length >= 64) {
      return AppColor.getMain();
    }

    final future = () async {
      try {
        final scheme = await ColorScheme.fromImageProvider(
          provider: ResizeImage.resizeIfNeeded(
            _quantizeSizePx,
            _quantizeSizePx,
            NetworkImage(imageUrl!.trim()),
          ),
          brightness: Brightness.dark,
        ).timeout(_extractTimeout);
        final color = _selectSchemeColor(scheme, AppColor.getMain());
        if (_cache.length >= maxCacheEntries && !_cache.containsKey(cleanKey)) {
          _cache.remove(_cache.keys.first);
        }
        _cache[cleanKey] = color;
        return color;
      } catch (_) {
        return AppColor.getMain();
      } finally {
        _inFlight.remove(cleanKey);
      }
    }();
    _inFlight[cleanKey] = future;
    return future;
  }

  /// Ensures sufficient contrast when using an extracted accent as foreground
  /// text/icon color over dark player surfaces (`#121212` / `#181818`).
  static Color ensureReadableOnDark(Color color, {double minLightness = 0.56}) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.lightness >= minLightness) return color;
    return hsl
        .withLightness(minLightness.clamp(0.0, 1.0))
        .withSaturation(hsl.saturation < 0.25 ? 0.35 : hsl.saturation)
        .toColor();
  }

  static Color _selectSchemeColor(ColorScheme scheme, Color fallback) {
    final candidates = <Color>[
      scheme.primary,
      scheme.primaryContainer,
      scheme.secondary,
      scheme.surface,
    ];
    for (final candidate in candidates) {
      final hsl = HSLColor.fromColor(candidate);
      if (candidate.a > 0 &&
          hsl.saturation >= 0.14 &&
          hsl.lightness >= 0.24 &&
          hsl.lightness <= 0.85) {
        return candidate;
      }
    }
    return scheme.primary.a > 0 ? scheme.primary : fallback;
  }

  /// Clears the cache. Intended for tests or memory pressure callbacks.
  static void clear() {
    _cache.clear();
    _inFlight.clear();
  }
}
