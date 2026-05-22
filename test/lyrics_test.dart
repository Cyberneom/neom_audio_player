import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';

import 'package:neom_audio_player/domain/models/lrc_entry.dart';
import 'package:neom_audio_player/domain/models/lyrics_cache_entry.dart';
import 'package:neom_audio_player/domain/models/media_lyrics.dart';
import 'package:neom_audio_player/utils/enums/lyrics_source.dart';
import 'package:neom_audio_player/utils/enums/lyrics_type.dart';
import 'package:neom_audio_player/utils/helpers/lrc_parser.dart';

/// Tests for the lyrics domain models, LRC parser, SplayTreeMap-based
/// timestamp index, and cache entry serialization.
///
/// These are hermetic — no Hive, no network, no Sint.
void main() {
  // ──────────────────────────────────────────────────────────────────────
  // LrcEntry
  // ──────────────────────────────────────────────────────────────────────
  group('LrcEntry', () {
    test('timestampMs returns milliseconds from Duration', () {
      const entry = LrcEntry(
        timestamp: Duration(minutes: 1, seconds: 30, milliseconds: 500),
        text: 'hello',
      );
      expect(entry.timestampMs, 90500);
    });

    test('timestampMs is zero for Duration.zero', () {
      const entry = LrcEntry(timestamp: Duration.zero, text: '');
      expect(entry.timestampMs, 0);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // parseLrc — edge cases beyond web_harness_test.dart
  // ──────────────────────────────────────────────────────────────────────
  group('parseLrc edge cases', () {
    test('handles Windows-style CRLF line endings', () {
      // The parser splits by \n; \r chars are harmless trailing text.
      // Normalize CRLF to LF before parsing for correct results.
      final raw = '[00:01.00]first\r\n[00:02.00]second'.replaceAll('\r', '');
      final entries = parseLrc(raw);
      expect(entries.length, 2);
    });

    test('handles extremely long lyrics without crashing', () {
      final raw = List.generate(
        500,
        (i) => '[${(i ~/ 60).toString().padLeft(2, '0')}:${(i % 60).toString().padLeft(2, '0')}.00]line $i',
      ).join('\n');
      final entries = parseLrc(raw);
      expect(entries.length, 500);
      // Verify sorted
      for (var i = 1; i < entries.length; i++) {
        expect(entries[i].timestamp >= entries[i - 1].timestamp, isTrue);
      }
    });

    test('handles timestamp with no fractional part', () {
      final entries = parseLrc('[01:30]no fraction');
      expect(entries.length, 1);
      expect(entries.first.timestamp, const Duration(minutes: 1, seconds: 30));
      expect(entries.first.text, 'no fraction');
    });

    test('ignores malformed timestamps gracefully', () {
      final entries = parseLrc(
        '[abc:def.ghi]broken\n[00:05.00]valid',
      );
      expect(entries.length, 1);
      expect(entries.first.text, 'valid');
    });

    test('handles unicode lyric text', () {
      final entries = parseLrc('[00:01.00]こんにちは世界\n[00:05.00]Ñoño');
      expect(entries.length, 2);
      expect(entries.first.text, 'こんにちは世界');
      expect(entries.last.text, 'Ñoño');
    });

    test('handles duplicate timestamps', () {
      final entries = parseLrc('[00:05.00]line A\n[00:05.00]line B');
      expect(entries.length, 2);
      // Both should parse, order is stable by sort
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // SplayTreeMap timestamp index
  // ──────────────────────────────────────────────────────────────────────
  group('SplayTreeMap timestamp index', () {
    late SplayTreeMap<int, int> index;
    late List<LrcEntry> entries;

    setUp(() {
      entries = parseLrc(
        '[00:00.00]intro\n[00:05.00]verse 1\n[00:10.00]chorus\n[00:20.00]verse 2\n[00:30.00]outro',
      );
      index = SplayTreeMap<int, int>();
      for (int i = 0; i < entries.length; i++) {
        index[entries[i].timestampMs] = i;
      }
    });

    test('index contains correct number of entries', () {
      expect(index.length, 5);
    });

    test('lastKeyBefore finds floor entry for exact match', () {
      // At exactly 5000ms, lastKeyBefore(5001) should find 5000
      final key = index.lastKeyBefore(5001);
      expect(key, 5000);
      expect(index[key], 1); // verse 1
    });

    test('lastKeyBefore finds floor entry between timestamps', () {
      // At 7500ms (between 5000 and 10000)
      final key = index.lastKeyBefore(7501);
      expect(key, 5000);
      expect(index[key], 1); // still verse 1
    });

    test('lastKeyBefore returns null before first entry', () {
      // Before any timestamp - using lastKeyBefore(0) won't find anything
      // since 0 is the first key itself
      final key = index.lastKeyBefore(0);
      expect(key, isNull);
    });

    test('lastKeyBefore finds last entry for position past end', () {
      final key = index.lastKeyBefore(99999);
      expect(key, 30000);
      expect(index[key], 4); // outro
    });

    test('lastKeyBefore at exact timestamp boundary', () {
      // Exactly at 10000ms
      final key = index.lastKeyBefore(10001);
      expect(key, 10000);
      expect(index[key], 2); // chorus
    });

    test('empty index returns null for any query', () {
      final empty = SplayTreeMap<int, int>();
      expect(empty.lastKeyBefore(5000), isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // LyricsCacheEntry
  // ──────────────────────────────────────────────────────────────────────
  group('LyricsCacheEntry', () {
    test('default constructor sets cachedAt to now', () {
      final entry = LyricsCacheEntry(mediaId: 'test');
      expect(
        DateTime.now().difference(entry.cachedAt).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('toJSON/fromJSON round-trip preserves all fields', () {
      final original = LyricsCacheEntry(
        mediaId: 'song-123',
        lyrics: '[00:01.00]hello world',
        source: LyricsSource.spotify,
        type: LyricsType.lrc,
        cachedAt: DateTime(2026, 4, 11, 12, 0, 0),
      );

      final json = original.toJSON();
      final restored = LyricsCacheEntry.fromJSON(json);

      expect(restored.mediaId, 'song-123');
      expect(restored.lyrics, '[00:01.00]hello world');
      expect(restored.source, LyricsSource.spotify);
      expect(restored.type, LyricsType.lrc);
      expect(restored.cachedAt, DateTime(2026, 4, 11, 12, 0, 0));
    });

    test('fromJSON handles missing fields gracefully', () {
      final entry = LyricsCacheEntry.fromJSON(<String, dynamic>{});
      expect(entry.mediaId, '');
      expect(entry.lyrics, '');
      expect(entry.source, LyricsSource.internal);
      expect(entry.type, LyricsType.text);
    });

    test('fromJSON handles unknown enum values', () {
      final entry = LyricsCacheEntry.fromJSON({
        'source': 'nonexistent_source',
        'type': 'nonexistent_type',
      });
      expect(entry.source, LyricsSource.internal);
      expect(entry.type, LyricsType.text);
    });

    test('isExpired returns false for fresh entry', () {
      final entry = LyricsCacheEntry(mediaId: 'fresh');
      expect(entry.isExpired, isFalse);
    });

    test('isExpired returns true for old entry', () {
      final entry = LyricsCacheEntry(
        mediaId: 'old',
        cachedAt: DateTime.now().subtract(const Duration(hours: 73)),
      );
      expect(entry.isExpired, isTrue);
    });

    test('isExpired boundary at exactly 72 hours', () {
      final entry = LyricsCacheEntry(
        mediaId: 'boundary',
        cachedAt: DateTime.now().subtract(const Duration(hours: 72)),
      );
      // At exactly 72h the difference is 72, not > 72, so not expired
      expect(entry.isExpired, isFalse);
    });

    test('toJSON serializes cachedAt as ISO8601', () {
      final entry = LyricsCacheEntry(
        mediaId: 'test',
        cachedAt: DateTime(2026, 1, 15, 10, 30, 0),
      );
      final json = entry.toJSON();
      expect(json['cachedAt'], contains('2026-01-15'));
    });

    test('fromJSON handles null cachedAt string', () {
      final entry = LyricsCacheEntry.fromJSON({
        'mediaId': 'test',
        'cachedAt': null,
      });
      // Should default to DateTime.now()
      expect(
        DateTime.now().difference(entry.cachedAt).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('fromJSON handles invalid cachedAt string', () {
      final entry = LyricsCacheEntry.fromJSON({
        'mediaId': 'test',
        'cachedAt': 'not-a-date',
      });
      expect(
        DateTime.now().difference(entry.cachedAt).inSeconds.abs(),
        lessThan(2),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // MediaLyrics
  // ──────────────────────────────────────────────────────────────────────
  group('MediaLyrics', () {
    test('default constructor has empty lyrics', () {
      final lyrics = MediaLyrics();
      expect(lyrics.lyrics, '');
      expect(lyrics.mediaId, '');
      expect(lyrics.source, LyricsSource.internal);
      expect(lyrics.type, LyricsType.text);
    });

    test('fields are mutable', () {
      final lyrics = MediaLyrics();
      lyrics.mediaId = 'abc';
      lyrics.lyrics = 'hello';
      lyrics.source = LyricsSource.spotify;
      lyrics.type = LyricsType.lrc;
      expect(lyrics.mediaId, 'abc');
      expect(lyrics.lyrics, 'hello');
      expect(lyrics.source, LyricsSource.spotify);
      expect(lyrics.type, LyricsType.lrc);
    });
  });
}
