import 'dart:collection';

import '../models/lrc_entry.dart';
import '../models/media_lyrics.dart';

/// Abstract service for lyrics resolution, caching, and time-synced playback.
///
/// Implementations should provide multi-source fallback (cache → Spotify →
/// Musixmatch → Google), Hive-based caching, and efficient O(log n) lookup
/// of the active line via [SplayTreeMap].
abstract class LyricsService {

  /// Resolves lyrics for a media item, checking cache first.
  Future<MediaLyrics> fetchLyrics({
    required String mediaId,
    required String title,
    required String artist,
  });

  /// Parses LRC-formatted lyrics into timestamped entries.
  List<LrcEntry> parseLrcEntries(String rawLrc);

  /// Builds a [SplayTreeMap] from parsed entries for O(log n) lookup.
  SplayTreeMap<int, int> buildTimestampIndex(List<LrcEntry> entries);

  /// Returns the index of the active lyric line for a given playback position.
  int getActiveLineIndex(Duration position);

  /// Whether the current lyrics are time-synced (LRC format).
  bool get isSynced;

  /// The currently parsed LRC entries (empty if plain text).
  List<LrcEntry> get currentEntries;

  /// Clears the in-memory lyrics cache for the given media item.
  Future<void> clearCache(String mediaId);

  /// Clears all cached lyrics.
  Future<void> clearAllCache();

}
