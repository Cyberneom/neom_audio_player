import 'dart:collection';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

import '../../domain/models/lrc_entry.dart';
import '../../domain/models/lyrics_cache_entry.dart';
import '../../domain/models/media_lyrics.dart';
import '../../domain/use_cases/lyrics_service.dart';
import '../../ui/player/lyrics/lyrics.dart';
import '../../utils/enums/lyrics_source.dart';
import '../../utils/enums/lyrics_type.dart';
import '../../utils/helpers/lrc_parser.dart';
import '../../utils/helpers/spotify_lyrics_helper.dart';

/// Concrete [LyricsService] implementation with multi-source fallback,
/// Hive-based caching, and O(log n) time-synced lookups via [SplayTreeMap].
///
/// Fallback cascade:
/// 1. Hive cache (if not expired)
/// 2. Spotify synced lyrics (LRC format preferred)
/// 3. Musixmatch (web scraping)
/// 4. Google (web scraping fallback)
class LyricsController extends SintController implements LyricsService {

  static const String _boxName = 'lyrics_cache';
  static const int _maxCacheEntries = 200;

  Box? _box;

  /// Parsed LRC entries for the current track.
  List<LrcEntry> _entries = const [];

  /// Maps timestamp (ms) → entry index for O(log n) lookup.
  SplayTreeMap<int, int> _timestampIndex = SplayTreeMap<int, int>();

  @override
  void onInit() {
    super.onInit();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      _box = await Hive.openBox(_boxName);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_audio_player', operation: 'LyricsController._initHive');
    }
  }

  // ─── LyricsService ────────────────────────────────────────────────────

  @override
  bool get isSynced => _entries.isNotEmpty;

  @override
  List<LrcEntry> get currentEntries => _entries;

  @override
  Future<MediaLyrics> fetchLyrics({
    required String mediaId,
    required String title,
    required String artist,
  }) async {
    // 1. Check cache
    final cached = _getCached(mediaId);
    if (cached != null) {
      AppConfig.logger.i('Lyrics cache hit for $mediaId');
      _parseAndIndex(cached.lyrics);
      return MediaLyrics(
        mediaId: mediaId,
        lyrics: cached.lyrics,
        source: cached.source,
        type: cached.type,
      );
    }

    AppConfig.logger.i('Fetching lyrics for "$title" by "$artist"');

    // 2. Spotify (synced preferred)
    MediaLyrics result = await SpotifyLyricsHelper.fetchLyrics(
      title: title,
      artist: artist,
    );
    if (result.lyrics.isNotEmpty) {
      result.mediaId = mediaId;
      _parseAndIndex(result.lyrics);
      await _putCache(mediaId, result);
      return result;
    }

    // 3. Musixmatch
    result = await Lyrics.getMusixMatchLyrics(title: title, artist: artist);
    if (result.lyrics.isNotEmpty) {
      result.mediaId = mediaId;
      _parseAndIndex(result.lyrics);
      await _putCache(mediaId, result);
      return result;
    }

    // 4. Google
    result = await Lyrics.getGoogleLyrics(title: title, artist: artist);
    if (result.lyrics.isNotEmpty) {
      result.mediaId = mediaId;
      _parseAndIndex(result.lyrics);
      await _putCache(mediaId, result);
      return result;
    }

    // No lyrics found
    _entries = const [];
    _timestampIndex = SplayTreeMap<int, int>();
    return MediaLyrics(mediaId: mediaId);
  }

  @override
  List<LrcEntry> parseLrcEntries(String rawLrc) {
    return parseLrc(rawLrc);
  }

  @override
  SplayTreeMap<int, int> buildTimestampIndex(List<LrcEntry> entries) {
    final index = SplayTreeMap<int, int>();
    for (int i = 0; i < entries.length; i++) {
      index[entries[i].timestampMs] = i;
    }
    return index;
  }

  @override
  int getActiveLineIndex(Duration position) {
    if (_entries.isEmpty || _timestampIndex.isEmpty) return -1;

    final posMs = position.inMilliseconds;
    final floorKey = _timestampIndex.lastKeyBefore(posMs + 1);
    if (floorKey == null) return -1;

    return _timestampIndex[floorKey] ?? -1;
  }

  @override
  Future<void> clearCache(String mediaId) async {
    await _box?.delete(mediaId);
  }

  @override
  Future<void> clearAllCache() async {
    await _box?.clear();
  }

  // ─── Internal helpers ─────────────────────────────────────────────────

  void _parseAndIndex(String rawLyrics) {
    _entries = parseLrc(rawLyrics);
    _timestampIndex = buildTimestampIndex(_entries);
  }

  LyricsCacheEntry? _getCached(String mediaId) {
    try {
      final raw = _box?.get(mediaId);
      if (raw == null) return null;
      final entry = LyricsCacheEntry.fromJSON(
        Map<String, dynamic>.from(json.decode(raw as String) as Map),
      );
      if (entry.isExpired) {
        _box?.delete(mediaId);
        return null;
      }
      return entry;
    } catch (_) {
      return null;
    }
  }

  Future<void> _putCache(String mediaId, MediaLyrics lyrics) async {
    try {
      // Enforce cache size limit
      if ((_box?.length ?? 0) >= _maxCacheEntries) {
        final firstKey = _box?.keys.first;
        if (firstKey != null) await _box?.delete(firstKey);
      }

      final entry = LyricsCacheEntry(
        mediaId: mediaId,
        lyrics: lyrics.lyrics,
        source: lyrics.source,
        type: lyrics.type,
      );
      await _box?.put(mediaId, json.encode(entry.toJSON()));
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_audio_player', operation: 'LyricsController._putCache');
    }
  }

}
