import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/neom_error_logger.dart';

/// Controller for managing catalog offline cache using Hive.
/// Caches public itemlists, releases, and media items for offline access.
class CatalogCacheController {
  static final CatalogCacheController _instance = CatalogCacheController._internal();
  factory CatalogCacheController() => _instance;
  CatalogCacheController._internal();

  Box? _catalogBox;
  Future<Box>? _openingBox;

  // Cache limits
  static const int _maxCachedItemlists = 100;
  static const int _maxCachedMediaItems = 500;
  static const int _cacheExpirationHours = 72; // 3 days
  static const int maxCatalogJsonChars = 4 * 1024 * 1024;
  static final RegExp _controlOrBidi = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060\u2066-\u2069\uFEFF]',
  );

  // Key constants
  static const String _publicItemlistsKey = 'public_itemlists';
  static const String _releaseItemlistsKey = 'release_itemlists';
  static const String _mediaItemsKey = 'media_items';
  static const String _lastUpdateKey = 'catalog_last_update';
  static const String _cacheVersionKey = 'catalog_cache_version';
  static const int _currentCacheVersion = 1;

  @visibleForTesting
  void resetForTesting() {
    _catalogBox = null;
    _openingBox = null;
  }

  static bool isSafeCacheEntryKey(String raw) {
    if (raw.isEmpty || raw.length > 256 || _controlOrBidi.hasMatch(raw)) {
      return false;
    }
    final clean = raw.trim();
    if (clean != raw) return false;
    final lower = clean.toLowerCase();
    if (lower == '__proto__' ||
        lower == 'constructor' ||
        lower == 'prototype' ||
        (lower.startsWith('__') && lower.endsWith('__'))) {
      return false;
    }
    return true;
  }

  static int? _readSafeInt(Object? raw) {
    if (raw is int && raw.toDouble().isFinite) return raw;
    if (raw is num && raw.isFinite) return raw.toInt();
    return null;
  }

  Future<Box> _getBox() async {
    if (_catalogBox != null && _catalogBox!.isOpen) return _catalogBox!;
    if (_openingBox != null) return _openingBox!;
    final boxName = '${AppHiveBox.player.name}_catalog';
    final completer = Completer<Box>();
    _openingBox = completer.future;
    try {
      final box = await _openBoxResilient(boxName);
      _catalogBox = box;
      completer.complete(box);
      return box;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _openingBox = null;
    }
  }

  Future<Box> _openBoxResilient(String boxName) async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    Future<Box> tryOpen() {
      final c = Completer<Box>();
      runZonedGuarded(() async {
        try {
          final b = await Hive.openBox(boxName);
          if (!c.isCompleted) c.complete(b);
        } catch (e, st) {
          if (!c.isCompleted) c.completeError(e, st);
        }
      }, (e, st) {
        if (!c.isCompleted) c.completeError(e, st);
      });
      return c.future;
    }

    try {
      return await tryOpen();
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (_) {}
      return tryOpen();
    }
  }

  // ==================== PUBLIC ITEMLISTS CACHE ====================

  /// Cache public itemlists (playlists).
  Future<void> cachePublicItemlists(Map<String, Itemlist> itemlists) async {
    try {
      final box = await _getBox();

      // Limit cached itemlists
      final toCache = <String, dynamic>{};

      for (final entry in itemlists.entries) {
        if (toCache.length >= _maxCachedItemlists) break;
        if (!isSafeCacheEntryKey(entry.key)) continue;
        toCache[entry.key] = entry.value.toJSON();
      }

      final encoded = jsonEncode(toCache);
      if (encoded.length > maxCatalogJsonChars) return;
      await box.put(_publicItemlistsKey, encoded);
      await _updateTimestamp();

      AppConfig.logger.d('Cached ${toCache.length} public itemlists');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'cachePublicItemlists');
    }
  }

  /// Get cached public itemlists.
  Future<Map<String, Itemlist>> getCachedPublicItemlists() async {
    try {
      final box = await _getBox();

      if (!await _isCacheValid()) {
        return {};
      }

      final rawJson = box.get(_publicItemlistsKey);
      if (rawJson is! String ||
          rawJson.isEmpty ||
          rawJson.length > maxCatalogJsonChars) {
        return {};
      }

      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return {};
      final Map<String, Itemlist> result = {};

      for (final entry in decoded.entries) {
        if (result.length >= _maxCachedItemlists) break;
        final key = entry.key?.toString() ?? '';
        if (!isSafeCacheEntryKey(key) || entry.value is! Map) continue;
        try {
          result[key] = Itemlist.fromJSON(
            Map<String, dynamic>.from(entry.value as Map),
          );
        } catch (_) {}
      }

      return result;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'getCachedPublicItemlists');
      return {};
    }
  }

  // ==================== RELEASE ITEMLISTS CACHE ====================

  /// Cache release itemlists.
  Future<void> cacheReleaseItemlists(Map<String, Itemlist> itemlists) async {
    try {
      final box = await _getBox();

      final toCache = <String, dynamic>{};

      for (final entry in itemlists.entries) {
        if (toCache.length >= _maxCachedItemlists) break;
        if (!isSafeCacheEntryKey(entry.key)) continue;
        toCache[entry.key] = entry.value.toJSON();
      }

      final encoded = jsonEncode(toCache);
      if (encoded.length > maxCatalogJsonChars) return;
      await box.put(_releaseItemlistsKey, encoded);
      await _updateTimestamp();

      AppConfig.logger.d('Cached ${toCache.length} release itemlists');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'cacheReleaseItemlists');
    }
  }

  /// Get cached release itemlists.
  Future<Map<String, Itemlist>> getCachedReleaseItemlists() async {
    try {
      final box = await _getBox();

      if (!await _isCacheValid()) {
        return {};
      }

      final rawJson = box.get(_releaseItemlistsKey);
      if (rawJson is! String ||
          rawJson.isEmpty ||
          rawJson.length > maxCatalogJsonChars) {
        return {};
      }

      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return {};
      final Map<String, Itemlist> result = {};

      for (final entry in decoded.entries) {
        if (result.length >= _maxCachedItemlists) break;
        final key = entry.key?.toString() ?? '';
        if (!isSafeCacheEntryKey(key) || entry.value is! Map) continue;
        try {
          result[key] = Itemlist.fromJSON(
            Map<String, dynamic>.from(entry.value as Map),
          );
        } catch (_) {}
      }

      return result;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'getCachedReleaseItemlists');
      return {};
    }
  }

  // ==================== MEDIA ITEMS CACHE ====================

  /// Cache global media items.
  Future<void> cacheMediaItems(Map<String, AppMediaItem> mediaItems) async {
    try {
      final box = await _getBox();

      final toCache = <String, dynamic>{};

      for (final entry in mediaItems.entries) {
        if (toCache.length >= _maxCachedMediaItems) break;
        if (!isSafeCacheEntryKey(entry.key)) continue;
        toCache[entry.key] = entry.value.toJSON();
      }

      final encoded = jsonEncode(toCache);
      if (encoded.length > maxCatalogJsonChars) return;
      await box.put(_mediaItemsKey, encoded);
      await _updateTimestamp();

      AppConfig.logger.d('Cached ${toCache.length} media items');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'cacheMediaItems');
    }
  }

  /// Get cached media items.
  Future<Map<String, AppMediaItem>> getCachedMediaItems() async {
    try {
      final box = await _getBox();

      if (!await _isCacheValid()) {
        return {};
      }

      final rawJson = box.get(_mediaItemsKey);
      if (rawJson is! String ||
          rawJson.isEmpty ||
          rawJson.length > maxCatalogJsonChars) {
        return {};
      }

      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return {};
      final Map<String, AppMediaItem> result = {};

      for (final entry in decoded.entries) {
        if (result.length >= _maxCachedMediaItems) break;
        final key = entry.key?.toString() ?? '';
        if (!isSafeCacheEntryKey(key) || entry.value is! Map) continue;
        try {
          result[key] = AppMediaItem.fromJSON(
            Map<String, dynamic>.from(entry.value as Map),
          );
        } catch (_) {}
      }

      return result;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'getCachedMediaItems');
      return {};
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Check if we're online.
  Future<bool> isOnline() async {
    final connectivity = await Connectivity().checkConnectivity();
    return !connectivity.contains(ConnectivityResult.none);
  }

  /// Check if cache is valid (not expired).
  Future<bool> _isCacheValid() async {
    try {
      final box = await _getBox();

      // Check cache version
      final version = _readSafeInt(box.get(_cacheVersionKey));
      if (version != _currentCacheVersion) {
        AppConfig.logger.d('Cache version mismatch, invalidating');
        return false;
      }

      // Check expiration
      final lastUpdate = _readSafeInt(box.get(_lastUpdateKey));
      if (lastUpdate == null || lastUpdate <= 0) return false;

      final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
      final maxAge = _cacheExpirationHours * 60 * 60 * 1000;

      if (cacheAge < 0 || cacheAge > maxAge) {
        AppConfig.logger.d('Cache expired or clock skewed');
        return false;
      }

      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: '_isCacheValid');
      return false;
    }
  }

  /// Update cache timestamp.
  Future<void> _updateTimestamp() async {
    try {
      final box = await _getBox();
      await box.put(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      await box.put(_cacheVersionKey, _currentCacheVersion);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'updateTimestamp');
    }
  }

  /// Get cache age in human readable format.
  Future<String> getCacheAge() async {
    try {
      final box = await _getBox();
      final lastUpdate = _readSafeInt(box.get(_lastUpdateKey));

      if (lastUpdate == null || lastUpdate <= 0) return 'Never updated';

      final rawAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
      final age = rawAge < 0 ? 0 : rawAge;
      final hours = (age / (1000 * 60 * 60)).floor();
      final minutes = ((age / (1000 * 60)) % 60).floor();

      if (hours > 0) {
        return '${hours}h ${minutes}m ago';
      }
      return '${minutes}m ago';
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'getCacheAge');
      return 'Unknown';
    }
  }

  /// Clear all catalog cache.
  Future<void> clearCache() async {
    try {
      final box = await _getBox();
      await box.clear();
      AppConfig.logger.d('Cleared catalog cache');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'clearCache');
    }
  }

  /// Get cache statistics.
  Future<Map<String, int>> getCacheStats() async {
    try {
      final publicItemlists = await getCachedPublicItemlists();
      final releaseItemlists = await getCachedReleaseItemlists();
      final mediaItems = await getCachedMediaItems();

      return {
        'publicItemlists': publicItemlists.length,
        'releaseItemlists': releaseItemlists.length,
        'mediaItems': mediaItems.length,
      };
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'getCacheStats');
      return {
        'publicItemlists': 0,
        'releaseItemlists': 0,
        'mediaItems': 0,
      };
    }
  }
}
