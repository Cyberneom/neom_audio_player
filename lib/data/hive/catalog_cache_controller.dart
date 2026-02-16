import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

/// Controller for managing catalog offline cache using Hive.
/// Caches public itemlists, releases, and media items for offline access.
class CatalogCacheController {
  static final CatalogCacheController _instance = CatalogCacheController._internal();
  factory CatalogCacheController() => _instance;
  CatalogCacheController._internal();

  Box? _catalogBox;

  // Cache limits
  static const int _maxCachedItemlists = 100;
  static const int _maxCachedMediaItems = 500;
  static const int _cacheExpirationHours = 72; // 3 days

  // Key constants
  static const String _publicItemlistsKey = 'public_itemlists';
  static const String _releaseItemlistsKey = 'release_itemlists';
  static const String _mediaItemsKey = 'media_items';
  static const String _lastUpdateKey = 'catalog_last_update';
  static const String _cacheVersionKey = 'catalog_cache_version';
  static const int _currentCacheVersion = 1;

  Future<Box> _getBox() async {
    _catalogBox ??= await Hive.openBox('${AppHiveBox.player.name}_catalog');
    return _catalogBox!;
  }

  // ==================== PUBLIC ITEMLISTS CACHE ====================

  /// Cache public itemlists (playlists).
  Future<void> cachePublicItemlists(Map<String, Itemlist> itemlists) async {
    try {
      final box = await _getBox();

      // Limit cached itemlists
      final entries = itemlists.entries.take(_maxCachedItemlists);
      final toCache = <String, dynamic>{};

      for (final entry in entries) {
        toCache[entry.key] = entry.value.toJSON();
      }

      await box.put(_publicItemlistsKey, jsonEncode(toCache));
      await _updateTimestamp();

      AppConfig.logger.d('Cached ${toCache.length} public itemlists');
    } catch (e) {
      AppConfig.logger.e('Error caching public itemlists: $e');
    }
  }

  /// Get cached public itemlists.
  Future<Map<String, Itemlist>> getCachedPublicItemlists() async {
    try {
      final box = await _getBox();

      if (!await _isCacheValid()) {
        return {};
      }

      final json = box.get(_publicItemlistsKey) as String?;
      if (json == null) return {};

      final Map<String, dynamic> data = jsonDecode(json);
      final Map<String, Itemlist> result = {};

      for (final entry in data.entries) {
        result[entry.key] = Itemlist.fromJSON(entry.value as Map<String, dynamic>);
      }

      return result;
    } catch (e) {
      AppConfig.logger.e('Error getting cached public itemlists: $e');
      return {};
    }
  }

  // ==================== RELEASE ITEMLISTS CACHE ====================

  /// Cache release itemlists.
  Future<void> cacheReleaseItemlists(Map<String, Itemlist> itemlists) async {
    try {
      final box = await _getBox();

      final entries = itemlists.entries.take(_maxCachedItemlists);
      final toCache = <String, dynamic>{};

      for (final entry in entries) {
        toCache[entry.key] = entry.value.toJSON();
      }

      await box.put(_releaseItemlistsKey, jsonEncode(toCache));
      await _updateTimestamp();

      AppConfig.logger.d('Cached ${toCache.length} release itemlists');
    } catch (e) {
      AppConfig.logger.e('Error caching release itemlists: $e');
    }
  }

  /// Get cached release itemlists.
  Future<Map<String, Itemlist>> getCachedReleaseItemlists() async {
    try {
      final box = await _getBox();

      if (!await _isCacheValid()) {
        return {};
      }

      final json = box.get(_releaseItemlistsKey) as String?;
      if (json == null) return {};

      final Map<String, dynamic> data = jsonDecode(json);
      final Map<String, Itemlist> result = {};

      for (final entry in data.entries) {
        result[entry.key] = Itemlist.fromJSON(entry.value as Map<String, dynamic>);
      }

      return result;
    } catch (e) {
      AppConfig.logger.e('Error getting cached release itemlists: $e');
      return {};
    }
  }

  // ==================== MEDIA ITEMS CACHE ====================

  /// Cache global media items.
  Future<void> cacheMediaItems(Map<String, AppMediaItem> mediaItems) async {
    try {
      final box = await _getBox();

      final entries = mediaItems.entries.take(_maxCachedMediaItems);
      final toCache = <String, dynamic>{};

      for (final entry in entries) {
        toCache[entry.key] = entry.value.toJSON();
      }

      await box.put(_mediaItemsKey, jsonEncode(toCache));
      await _updateTimestamp();

      AppConfig.logger.d('Cached ${toCache.length} media items');
    } catch (e) {
      AppConfig.logger.e('Error caching media items: $e');
    }
  }

  /// Get cached media items.
  Future<Map<String, AppMediaItem>> getCachedMediaItems() async {
    try {
      final box = await _getBox();

      if (!await _isCacheValid()) {
        return {};
      }

      final json = box.get(_mediaItemsKey) as String?;
      if (json == null) return {};

      final Map<String, dynamic> data = jsonDecode(json);
      final Map<String, AppMediaItem> result = {};

      for (final entry in data.entries) {
        result[entry.key] = AppMediaItem.fromJSON(entry.value as Map<String, dynamic>);
      }

      return result;
    } catch (e) {
      AppConfig.logger.e('Error getting cached media items: $e');
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
      final version = box.get(_cacheVersionKey) as int?;
      if (version != _currentCacheVersion) {
        AppConfig.logger.d('Cache version mismatch, invalidating');
        return false;
      }

      // Check expiration
      final lastUpdate = box.get(_lastUpdateKey) as int?;
      if (lastUpdate == null) return false;

      final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
      final maxAge = _cacheExpirationHours * 60 * 60 * 1000;

      if (cacheAge > maxAge) {
        AppConfig.logger.d('Cache expired');
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update cache timestamp.
  Future<void> _updateTimestamp() async {
    try {
      final box = await _getBox();
      await box.put(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      await box.put(_cacheVersionKey, _currentCacheVersion);
    } catch (e) {
      AppConfig.logger.e('Error updating cache timestamp: $e');
    }
  }

  /// Get cache age in human readable format.
  Future<String> getCacheAge() async {
    try {
      final box = await _getBox();
      final lastUpdate = box.get(_lastUpdateKey) as int?;

      if (lastUpdate == null) return 'Never updated';

      final age = DateTime.now().millisecondsSinceEpoch - lastUpdate;
      final hours = (age / (1000 * 60 * 60)).floor();
      final minutes = ((age / (1000 * 60)) % 60).floor();

      if (hours > 0) {
        return '${hours}h ${minutes}m ago';
      }
      return '${minutes}m ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Clear all catalog cache.
  Future<void> clearCache() async {
    try {
      final box = await _getBox();
      await box.clear();
      AppConfig.logger.d('Cleared catalog cache');
    } catch (e) {
      AppConfig.logger.e('Error clearing catalog cache: $e');
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
    } catch (e) {
      return {
        'publicItemlists': 0,
        'releaseItemlists': 0,
        'mediaItems': 0,
      };
    }
  }
}
