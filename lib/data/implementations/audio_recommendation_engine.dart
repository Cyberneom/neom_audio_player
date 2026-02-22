import 'dart:math';

import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

import '../../utils/enums/radio_seed_type.dart';
import '../hive/catalog_cache_controller.dart';

/// Client-side recommendation engine using content-based filtering
/// on AppReleaseItem metadata (categories, owner, language, duration).
class AudioRecommendationEngine {

  final _releaseFirestore = AppReleaseItemFirestore();
  final _catalogCache = CatalogCacheController();
  final _random = Random();

  // High-energy categories (used as proxy for mood filtering)
  static const _highEnergyCategories = ['rock', 'electronic', 'dance', 'hip-hop', 'metal', 'punk', 'edm'];
  static const _lowEnergyCategories = ['ambient', 'classical', 'jazz', 'acoustic', 'chill', 'lo-fi', 'meditation'];

  /// Recommend songs similar to a given song
  Future<List<AppReleaseItem>> recommendFromSong(
    String songId, {
    int count = 20,
    RadioMood? mood,
  }) async {
    try {
      // 1. Get the seed song
      final seedSong = await _releaseFirestore.retrieve(songId);
      if (seedSong.id.isEmpty) return [];

      final results = <String, AppReleaseItem>{};

      // 2. Get songs from same categories
      for (final category in seedSong.categories.take(3)) {
        final byCategory = await _releaseFirestore.retrieveByCategory(category, limit: 30);
        results.addAll(byCategory);
      }

      // 3. Get songs from same artist
      if (seedSong.ownerEmail.isNotEmpty) {
        final byOwner = await _releaseFirestore.retrieveByOwner(seedSong.ownerEmail, limit: 15);
        results.addAll(byOwner);
      }

      // 4. Remove the seed song itself
      results.remove(songId);

      // 5. Score and sort by similarity
      final scored = results.values.map((item) {
        return _ScoredItem(item, _calculateSimilarity(seedSong, item));
      }).toList();
      scored.sort((a, b) => b.score.compareTo(a.score));

      // 6. Apply mood filter and return top N
      final filtered = _applyMoodFilter(scored.map((s) => s.item).toList(), mood);
      return filtered.take(count).toList();
    } catch (e) {
      AppConfig.logger.e('Error in recommendFromSong: $e');
      return [];
    }
  }

  /// Recommend songs from a specific artist and similar artists
  Future<List<AppReleaseItem>> recommendFromArtist(
    String artistOwnerEmail, {
    int count = 20,
    RadioMood? mood,
  }) async {
    try {
      final results = <String, AppReleaseItem>{};

      // 1. Get songs from this artist
      final artistSongs = await _releaseFirestore.retrieveByOwner(artistOwnerEmail, limit: 30);
      results.addAll(artistSongs);

      // 2. Find common categories from artist's songs
      final categoryCount = <String, int>{};
      for (final song in artistSongs.values) {
        for (final cat in song.categories) {
          categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
        }
      }

      // 3. Get songs from top categories (similar artists)
      final topCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in topCategories.take(3)) {
        final byCategory = await _releaseFirestore.retrieveByCategory(entry.key, limit: 20);
        results.addAll(byCategory);
      }

      // 4. Shuffle to mix artist and similar songs
      final items = results.values.toList()..shuffle(_random);

      // 5. Apply mood filter
      return _applyMoodFilter(items, mood).take(count).toList();
    } catch (e) {
      AppConfig.logger.e('Error in recommendFromArtist: $e');
      return [];
    }
  }

  /// Recommend songs from a specific genre
  Future<List<AppReleaseItem>> recommendFromGenre(
    String genre, {
    int count = 20,
    RadioMood? mood,
  }) async {
    try {
      final byCategory = await _releaseFirestore.retrieveByCategory(genre, limit: count * 2);
      final items = byCategory.values.toList()..shuffle(_random);
      return _applyMoodFilter(items, mood).take(count).toList();
    } catch (e) {
      AppConfig.logger.e('Error in recommendFromGenre: $e');
      return [];
    }
  }

  /// Generate a personal mix based on user's listening history and favorites
  Future<List<AppReleaseItem>> personalMix({
    int count = 20,
    RadioMood? mood,
  }) async {
    try {
      // 1. Get recently played from Hive
      final recentIds = await _getRecentlyPlayedIds();
      final favoriteIds = await _getFavoriteIds();

      // 2. Extract most common categories and artists from history
      final allIds = {...recentIds, ...favoriteIds};
      final knownItems = <AppReleaseItem>[];

      if (allIds.isNotEmpty) {
        final fetched = await _releaseFirestore.retrieveFromList(allIds.take(30).toList());
        knownItems.addAll(fetched.values);
      }

      final categoryCount = <String, int>{};
      final ownerCount = <String, int>{};
      for (final item in knownItems) {
        for (final cat in item.categories) {
          categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
        }
        if (item.ownerEmail.isNotEmpty) {
          ownerCount[item.ownerEmail] = (ownerCount[item.ownerEmail] ?? 0) + 1;
        }
      }

      // 3. Query by top categories
      final results = <String, AppReleaseItem>{};
      final topCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in topCategories.take(3)) {
        final byCategory = await _releaseFirestore.retrieveByCategory(entry.key, limit: 20);
        results.addAll(byCategory);
      }

      // 4. Query by top artists
      final topOwners = ownerCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in topOwners.take(2)) {
        final byOwner = await _releaseFirestore.retrieveByOwner(entry.key, limit: 10);
        results.addAll(byOwner);
      }

      // 5. Exclude already listened and sort by popularity
      for (final id in allIds) {
        results.remove(id);
      }

      final items = results.values.toList();
      items.sort((a, b) => (b.likedProfiles?.length ?? 0).compareTo(a.likedProfiles?.length ?? 0));

      return _applyMoodFilter(items, mood).take(count).toList();
    } catch (e) {
      AppConfig.logger.e('Error in personalMix: $e');
      return _fallbackFromCache(count, mood);
    }
  }

  /// Discovery queue: songs the user has NOT listened to before
  Future<List<AppReleaseItem>> discoveryQueue({
    int count = 20,
    RadioMood? mood,
  }) async {
    try {
      // 1. Get all listened/favorite IDs
      final recentIds = await _getRecentlyPlayedIds();
      final favoriteIds = await _getFavoriteIds();
      final excludeIds = {...recentIds, ...favoriteIds};

      // 2. Get cached catalog
      final cachedMedia = await _catalogCache.getCachedMediaItems();

      // 3. Filter out already listened items
      final unheard = <AppMediaItem>[];
      for (final item in cachedMedia.values) {
        if (!excludeIds.contains(item.id)) {
          unheard.add(item);
        }
      }

      // 4. If enough unheard items in cache, use those
      if (unheard.length >= count) {
        unheard.shuffle(_random);
        // Convert AppMediaItem back to AppReleaseItem IDs and fetch
        final ids = unheard.take(count * 2).map((e) => e.id).toList();
        final releases = await _releaseFirestore.retrieveFromList(ids);
        final items = releases.values.toList()..shuffle(_random);
        return _applyMoodFilter(items, mood).take(count).toList();
      }

      // 5. Fallback: fetch all and filter
      final all = await _releaseFirestore.retrieveAll();
      for (final id in excludeIds) {
        all.remove(id);
      }

      final items = all.values.toList();
      // Sort by popularity (most liked first) then shuffle top results
      items.sort((a, b) => (b.likedProfiles?.length ?? 0).compareTo(a.likedProfiles?.length ?? 0));
      final topItems = items.take(count * 3).toList()..shuffle(_random);

      return _applyMoodFilter(topItems, mood).take(count).toList();
    } catch (e) {
      AppConfig.logger.e('Error in discoveryQueue: $e');
      return _fallbackFromCache(count, mood);
    }
  }

  /// Shuffle and return user's liked/favorite songs
  Future<List<AppReleaseItem>> fromLikedSongs({
    int count = 20,
    RadioMood? mood,
  }) async {
    try {
      final favoriteIds = await _getFavoriteIds();
      if (favoriteIds.isEmpty) return [];

      final releases = await _releaseFirestore.retrieveFromList(favoriteIds.take(50).toList());
      final items = releases.values.toList()..shuffle(_random);

      return _applyMoodFilter(items, mood).take(count).toList();
    } catch (e) {
      AppConfig.logger.e('Error in fromLikedSongs: $e');
      return [];
    }
  }

  // ============ Similarity Scoring ============

  /// Calculate similarity score between two AppReleaseItems (0.0 - 1.0)
  double _calculateSimilarity(AppReleaseItem a, AppReleaseItem b) {
    double score = 0.0;

    // Category overlap (weight: 0.4)
    if (a.categories.isNotEmpty && b.categories.isNotEmpty) {
      final setA = a.categories.toSet();
      final setB = b.categories.toSet();
      final intersection = setA.intersection(setB).length;
      final union = setA.union(setB).length;
      if (union > 0) {
        score += 0.4 * (intersection / union);
      }
    }

    // Same artist (weight: 0.3)
    if (a.ownerEmail.isNotEmpty && a.ownerEmail == b.ownerEmail) {
      score += 0.3;
    }

    // Same language (weight: 0.15)
    if (a.language != null && a.language == b.language && a.language!.isNotEmpty) {
      score += 0.15;
    }

    // Similar duration (weight: 0.15)
    if (a.duration > 0 && b.duration > 0) {
      final durationDiff = (a.duration - b.duration).abs();
      final maxDuration = max(a.duration, b.duration);
      final durationSimilarity = 1.0 - (durationDiff / maxDuration);
      score += 0.15 * durationSimilarity;
    }

    return score.clamp(0.0, 1.0);
  }

  // ============ Mood Filtering ============

  /// Filter items by mood energy level
  List<AppReleaseItem> _applyMoodFilter(List<AppReleaseItem> items, RadioMood? mood) {
    if (mood == null) return items;

    final targetEnergy = mood.energyLevel;

    return items.where((item) {
      final itemEnergy = _estimateEnergy(item);
      // Allow items within 0.3 energy band of target
      return (itemEnergy - targetEnergy).abs() <= 0.3;
    }).toList();
  }

  /// Estimate energy level of a song based on metadata (0.0 = low, 1.0 = high)
  double _estimateEnergy(AppReleaseItem item) {
    double energy = 0.5; // Default: mid-energy

    // Category-based energy
    final lowerCategories = item.categories.map((c) => c.toLowerCase()).toList();
    for (final cat in lowerCategories) {
      if (_highEnergyCategories.contains(cat)) {
        energy += 0.2;
      }
      if (_lowEnergyCategories.contains(cat)) {
        energy -= 0.2;
      }
    }

    // Duration-based energy heuristic
    if (item.duration > 0) {
      if (item.duration < 180) {
        energy += 0.1; // Short tracks tend to be more energetic
      } else if (item.duration > 300) {
        energy -= 0.1; // Long tracks tend to be more relaxed
      }
    }

    return energy.clamp(0.0, 1.0);
  }

  // ============ Hive Helpers ============

  /// Get IDs of recently played songs from Hive
  Future<Set<String>> _getRecentlyPlayedIds() async {
    try {
      final playerBox = await AppHiveController().getBox(AppHiveBox.player.name);
      final List recentList = playerBox.get(AppHiveConstants.recentSongs, defaultValue: [])?.toList() as List? ?? [];
      return recentList
          .where((item) => item is Map && item['id'] != null)
          .map<String>((item) => item['id'].toString())
          .toSet();
    } catch (e) {
      AppConfig.logger.e('Error getting recently played: $e');
      return {};
    }
  }

  /// Get IDs of favorite/liked songs from Hive
  Future<Set<String>> _getFavoriteIds() async {
    try {
      final favBox = await AppHiveController().getBox(AppHiveBox.favoriteItems.name);
      return favBox.keys.cast<String>().toSet();
    } catch (e) {
      AppConfig.logger.e('Error getting favorites: $e');
      return {};
    }
  }

  /// Fallback: return random items from cached catalog
  Future<List<AppReleaseItem>> _fallbackFromCache(int count, RadioMood? mood) async {
    try {
      final cached = await _catalogCache.getCachedMediaItems();
      if (cached.isEmpty) return [];

      final ids = cached.keys.take(count * 2).toList();
      final releases = await _releaseFirestore.retrieveFromList(ids);
      final items = releases.values.toList()..shuffle(_random);
      return _applyMoodFilter(items, mood).take(count).toList();
    } catch (e) {
      return [];
    }
  }
}

/// Internal helper for scored sorting
class _ScoredItem {
  final AppReleaseItem item;
  final double score;
  _ScoredItem(this.item, this.score);
}
