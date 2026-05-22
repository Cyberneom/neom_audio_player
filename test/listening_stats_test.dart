// Tests for `LrcEntry`, `ListeningStats`, `ArtistStat`, `SongStat`,
// `GenreStat`, `DailyActivity`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/domain/models/listening_stats.dart';
import 'package:neom_audio_player/domain/models/lrc_entry.dart';

void main() {
  group('LrcEntry', () {
    test('timestampMs convierte Duration a milliseconds', () {
      const entry = LrcEntry(
        timestamp: Duration(seconds: 5, milliseconds: 250),
        text: 'Hello',
      );
      expect(entry.timestampMs, 5250);
    });

    test('texto vacío permitido (stamp-only line)', () {
      const entry = LrcEntry(timestamp: Duration.zero, text: '');
      expect(entry.text, '');
    });
  });

  group('ListeningStats — defaults & empty', () {
    test('factory empty crea instance vacío con lastUpdated=now()', () {
      final stats = ListeningStats.empty();
      expect(stats.totalListeningTimeMs, 0);
      expect(stats.totalSongsPlayed, 0);
      expect(stats.topArtists, isEmpty);
      expect(stats.lastUpdated.year, greaterThanOrEqualTo(2024));
    });

    test('formattedTotalTime: 0 → "0m"', () {
      final stats = ListeningStats.empty();
      expect(stats.formattedTotalTime, '0m');
    });

    test('formattedTotalTime: 30 minutos → "30m"', () {
      final stats = ListeningStats(
        totalListeningTimeMs: 30 * 60 * 1000,
        lastUpdated: DateTime(2026),
      );
      expect(stats.formattedTotalTime, '30m');
    });

    test('formattedTotalTime: 1h 30m → "1h 30m"', () {
      final stats = ListeningStats(
        totalListeningTimeMs: (60 + 30) * 60 * 1000,
        lastUpdated: DateTime(2026),
      );
      expect(stats.formattedTotalTime, '1h 30m');
    });

    test('formattedTotalTime: 2h 0m → "2h 0m"', () {
      final stats = ListeningStats(
        totalListeningTimeMs: 2 * 60 * 60 * 1000,
        lastUpdated: DateTime(2026),
      );
      expect(stats.formattedTotalTime, '2h 0m');
    });

    test('formattedTodayTime usa todayListeningTimeMs', () {
      final stats = ListeningStats(
        todayListeningTimeMs: 45 * 60 * 1000,
        lastUpdated: DateTime(2026),
      );
      expect(stats.formattedTodayTime, '45m');
    });
  });

  group('ListeningStats.copyWith', () {
    test('cambia solo el campo especificado', () {
      final original = ListeningStats(
        totalSongsPlayed: 100,
        currentStreak: 5,
        lastUpdated: DateTime(2026, 1, 1),
      );
      final copy = original.copyWith(currentStreak: 10);
      expect(copy.totalSongsPlayed, 100);
      expect(copy.currentStreak, 10);
    });
  });

  group('ListeningStats — round-trip JSON', () {
    test('preserva todos los campos básicos', () {
      final original = ListeningStats(
        totalListeningTimeMs: 1000000,
        todayListeningTimeMs: 50000,
        weekListeningTimeMs: 500000,
        totalSongsPlayed: 500,
        uniqueSongsPlayed: 200,
        currentStreak: 10, longestStreak: 30,
        listeningByHour: const {0: 100, 12: 5000},
        listeningByDay: const {1: 1000, 5: 8000},
        lastUpdated: DateTime(2026, 1, 15),
        avgSessionLengthMs: 180000,
        favoriteListeningTime: 'evening',
        estimatedYearlyWrappedSongs: 5000,
      );
      final restored = ListeningStats.fromJson(original.toJson());
      expect(restored.totalListeningTimeMs, 1000000);
      expect(restored.totalSongsPlayed, 500);
      expect(restored.currentStreak, 10);
      expect(restored.listeningByHour[0], 100);
      expect(restored.listeningByHour[12], 5000);
      expect(restored.listeningByDay[1], 1000);
      expect(restored.favoriteListeningTime, 'evening');
      expect(restored.estimatedYearlyWrappedSongs, 5000);
    });

    test('fromJson sin campos usa defaults', () {
      final stats = ListeningStats.fromJson({});
      expect(stats.totalListeningTimeMs, 0);
      expect(stats.topArtists, isEmpty);
      expect(stats.listeningByHour, isEmpty);
    });
  });

  group('ArtistStat', () {
    test('round-trip JSON', () {
      const original = ArtistStat(
        artistId: 'a1',
        artistName: 'Alice',
        imageUrl: 'https://x/a.jpg',
        playCount: 100,
        listeningTimeMs: 5000000,
        rank: 1,
      );
      final restored = ArtistStat.fromJson(original.toJson());
      expect(restored.artistId, 'a1');
      expect(restored.artistName, 'Alice');
      expect(restored.playCount, 100);
      expect(restored.rank, 1);
    });
  });

  group('SongStat', () {
    test('round-trip JSON con lastPlayedAt', () {
      final original = SongStat(
        songId: 's1',
        songTitle: 'Song',
        artistName: 'Alice',
        playCount: 50,
        listeningTimeMs: 100000,
        lastPlayedAt: DateTime(2026, 1, 15),
        rank: 5,
      );
      final restored = SongStat.fromJson(original.toJson());
      expect(restored.songId, 's1');
      expect(restored.songTitle, 'Song');
      expect(restored.artistName, 'Alice');
      expect(restored.lastPlayedAt!.year, 2026);
    });

    test('lastPlayedAt null se preserva', () {
      const original = SongStat(
        songId: 's1', songTitle: 'X', artistName: 'A',
        playCount: 1, listeningTimeMs: 0,
        // lastPlayedAt null
      );
      final restored = SongStat.fromJson(original.toJson());
      expect(restored.lastPlayedAt, isNull);
    });
  });

  group('GenreStat', () {
    test('round-trip JSON', () {
      const original = GenreStat(
        genre: 'Rock',
        playCount: 200,
        listeningTimeMs: 5000000,
        percentage: 0.35,
        rank: 1,
      );
      final restored = GenreStat.fromJson(original.toJson());
      expect(restored.genre, 'Rock');
      expect(restored.percentage, 0.35);
    });
  });

  group('DailyActivity', () {
    test('defaults: listeningTimeMs=0, songsPlayed=0', () {
      final activity = DailyActivity(date: DateTime(2026, 1, 1));
      expect(activity.listeningTimeMs, 0);
      expect(activity.songsPlayed, 0);
      expect(activity.topArtistIds, isEmpty);
    });

    test('round-trip JSON', () {
      final original = DailyActivity(
        date: DateTime(2026, 1, 15),
        listeningTimeMs: 3600000,
        songsPlayed: 25,
        topArtistIds: const ['a1', 'a2', 'a3'],
      );
      final restored = DailyActivity.fromJson(original.toJson());
      expect(restored.date.year, 2026);
      expect(restored.listeningTimeMs, 3600000);
      expect(restored.songsPlayed, 25);
      expect(restored.topArtistIds, ['a1', 'a2', 'a3']);
    });
  });
}
