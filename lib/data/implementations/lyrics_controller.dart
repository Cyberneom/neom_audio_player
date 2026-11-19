import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

import '../../domain/models/lrc_entry.dart';
import '../../domain/models/lyrics_cache_entry.dart';
import '../../domain/models/media_lyrics.dart';
import '../../domain/use_cases/lyrics_service.dart';
import '../../ui/player/lyrics/lyrics.dart';
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
  static const int maxCachedLyricsChars = 256 * 1024;
  static final RegExp _controlOrBidi = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060\u2066-\u2069\uFEFF]',
  );
  static final RegExp _unsafeInlineControls = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060\u2066-\u2069\uFEFF]',
  );
  static final RegExp _gemmaThoughtBlock = RegExp(
    r'<(?:(?:\|channel>|\|turn>)thought[\s\S]*?(?:<(?:channel|turn)\|>|$)|think>[\s\S]*?</think>)',
    caseSensitive: false,
  );
  static final RegExp _internalControlTags = RegExp(
    r'<\|/?(?:turn|channel)\|?>?|<\|eot\|>|\[MEMORY_RECALL\]|<memory_recall>[\s\S]*?</memory_recall>|<auto_memory>[\s\S]*?</auto_memory>|<system_context>[\s\S]*?</system_context>|\[BIOCHIP:[^\]]*\]',
    caseSensitive: false,
  );
  static final RegExp _contentCloseTag = RegExp(
    r'</\s*content\s*>',
    caseSensitive: false,
  );

  Box? _box;
  Future<Box?>? _openingBox;

  static bool isSafeMediaId(String raw) {
    if (raw.isEmpty || raw.length > 128 || _controlOrBidi.hasMatch(raw)) {
      return false;
    }
    final clean = raw.trim();
    if (clean != raw ||
        clean == '.' ||
        clean == '..' ||
        clean.contains('..') ||
        clean.contains('/') ||
        clean.contains(r'\') ||
        clean.contains(':')) {
      return false;
    }
    final lower = clean.toLowerCase();
    if (lower == '__proto__' ||
        lower == 'constructor' ||
        lower == 'prototype' ||
        (lower.startsWith('__') && lower.endsWith('__'))) {
      return false;
    }
    return true;
  }

  static String sanitizeLyricsText(
    String raw, {
    int maxChars = maxCachedLyricsChars,
  }) {
    if (raw.isEmpty || maxChars <= 0) return '';
    final cleaned = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_gemmaThoughtBlock, '')
        .replaceAll(_internalControlTags, '')
        .replaceAll(_contentCloseTag, '[content_end]')
        .replaceAll(_unsafeInlineControls, '')
        .trim();
    if (cleaned.length <= maxChars) return cleaned;
    var end = maxChars;
    final cu = cleaned.codeUnitAt(end - 1);
    if (cu >= 0xD800 && cu <= 0xDBFF) end -= 1;
    return end <= 0 ? '' : cleaned.substring(0, end);
  }

  static String _sanitizeQueryField(String raw, {int maxChars = 200}) {
    if (raw.isEmpty || maxChars <= 0) return '';
    final cleaned = raw
        .replaceAll(_gemmaThoughtBlock, '')
        .replaceAll(_internalControlTags, '')
        .replaceAll(_contentCloseTag, '')
        .replaceAll(_controlOrBidi, '')
        .trim();
    if (cleaned.length <= maxChars) return cleaned;
    var end = maxChars;
    final cu = cleaned.codeUnitAt(end - 1);
    if (cu >= 0xD800 && cu <= 0xDBFF) end -= 1;
    return end <= 0 ? '' : cleaned.substring(0, end);
  }

  /// Parsed LRC entries for the current track.
  List<LrcEntry> _entries = const [];

  /// Maps timestamp (ms) → entry index for O(log n) lookup.
  SplayTreeMap<int, int> _timestampIndex = SplayTreeMap<int, int>();

  @override
  void onInit() {
    super.onInit();
    _initHive();
  }

  Future<Box?> _initHive() async {
    if (_box != null && _box!.isOpen) return _box;
    if (_openingBox != null) return _openingBox!;
    final completer = Completer<Box?>();
    _openingBox = completer.future;
    try {
      Box? opened;
      if (Hive.isBoxOpen(_boxName)) {
        opened = Hive.box(_boxName);
      } else {
        Future<Box> tryOpen() {
          final c = Completer<Box>();
          runZonedGuarded(() async {
            try {
              final b = await Hive.openBox(_boxName);
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
          opened = await tryOpen();
        } catch (_) {
          try {
            await Hive.deleteBoxFromDisk(_boxName);
          } catch (_) {}
          opened = await tryOpen();
        }
      }
      _box = opened;
      completer.complete(opened);
      return opened;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_audio_player', operation: 'LyricsController._initHive');
      completer.complete(null);
      return null;
    } finally {
      _openingBox = null;
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
    final safeId = isSafeMediaId(mediaId) ? mediaId : '';
    final cleanTitle = _sanitizeQueryField(title);
    final cleanArtist = _sanitizeQueryField(artist);

    // 1. Check cache
    if (safeId.isNotEmpty) {
      await _initHive();
      final cached = _getCached(safeId);
      if (cached != null) {
        final safeCachedLyrics = sanitizeLyricsText(cached.lyrics);
        if (safeCachedLyrics.isNotEmpty) {
          AppConfig.logger.i('Lyrics cache hit for $safeId');
          _parseAndIndex(safeCachedLyrics);
          return MediaLyrics(
            mediaId: safeId,
            lyrics: safeCachedLyrics,
            source: cached.source,
            type: cached.type,
          );
        }
      }
    }

    AppConfig.logger.i('Fetching lyrics for "$cleanTitle" by "$cleanArtist"');

    // 2. Spotify (synced preferred)
    MediaLyrics result = await SpotifyLyricsHelper.fetchLyrics(
      title: cleanTitle,
      artist: cleanArtist,
    );
    result.lyrics = sanitizeLyricsText(result.lyrics);
    if (result.lyrics.isNotEmpty) {
      result.mediaId = safeId;
      _parseAndIndex(result.lyrics);
      if (safeId.isNotEmpty) await _putCache(safeId, result);
      return result;
    }

    // 3. Musixmatch
    result = await Lyrics.getMusixMatchLyrics(
      title: cleanTitle,
      artist: cleanArtist,
    );
    result.lyrics = sanitizeLyricsText(result.lyrics);
    if (result.lyrics.isNotEmpty) {
      result.mediaId = safeId;
      _parseAndIndex(result.lyrics);
      if (safeId.isNotEmpty) await _putCache(safeId, result);
      return result;
    }

    // 4. Google
    result = await Lyrics.getGoogleLyrics(
      title: cleanTitle,
      artist: cleanArtist,
    );
    result.lyrics = sanitizeLyricsText(result.lyrics);
    if (result.lyrics.isNotEmpty) {
      result.mediaId = safeId;
      _parseAndIndex(result.lyrics);
      if (safeId.isNotEmpty) await _putCache(safeId, result);
      return result;
    }

    // No lyrics found
    _entries = const [];
    _timestampIndex = SplayTreeMap<int, int>();
    return MediaLyrics(mediaId: safeId);
  }

  @override
  List<LrcEntry> parseLrcEntries(String rawLrc) {
    return parseLrc(sanitizeLyricsText(rawLrc));
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
    if (!isSafeMediaId(mediaId)) return;
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
    if (!isSafeMediaId(mediaId)) return null;
    try {
      final raw = _box?.get(mediaId);
      if (raw is! String || raw.isEmpty || raw.length > maxCachedLyricsChars) {
        return null;
      }
      final decoded = json.decode(raw);
      if (decoded is! Map) return null;
      final map = <String, dynamic>{};
      for (final entry in decoded.entries) {
        final k = entry.key?.toString() ?? '';
        final lower = k.toLowerCase();
        if (lower == '__proto__' ||
            lower == 'constructor' ||
            lower == 'prototype' ||
            (lower.startsWith('__') && lower.endsWith('__'))) {
          continue;
        }
        map[k] = entry.value;
      }
      final entry = LyricsCacheEntry.fromJSON(map);
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
    if (!isSafeMediaId(mediaId)) return;
    try {
      final cleanLyrics = sanitizeLyricsText(lyrics.lyrics);
      if (cleanLyrics.isEmpty) return;
      // Enforce cache size limit
      if ((_box?.length ?? 0) >= _maxCacheEntries) {
        final firstKey = _box?.keys.first;
        if (firstKey != null) await _box?.delete(firstKey);
      }

      final entry = LyricsCacheEntry(
        mediaId: mediaId,
        lyrics: cleanLyrics,
        source: lyrics.source,
        type: lyrics.type,
      );
      final encoded = json.encode(entry.toJSON());
      if (encoded.length > maxCachedLyricsChars) return;
      await _box?.put(mediaId, encoded);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_audio_player', operation: 'LyricsController._putCache');
    }
  }

}
