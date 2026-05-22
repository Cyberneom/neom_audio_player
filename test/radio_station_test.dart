// Tests for `RadioStation`, `RadioStationParams`, `RadioSeedType`, `RadioMood`.

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/domain/models/radio_station.dart';
import 'package:neom_audio_player/utils/enums/radio_seed_type.dart';

void main() {
  group('RadioSeedType', () {
    test('tiene 10 tipos de seeds', () {
      expect(RadioSeedType.values, hasLength(10));
    });

    test('cada tipo tiene displayName', () {
      for (final t in RadioSeedType.values) {
        expect(t.displayName, isNotEmpty);
        expect(t.value, isNotEmpty);
      }
    });

    test('value específicos', () {
      expect(RadioSeedType.song.value, 'song');
      expect(RadioSeedType.personalMix.value, 'personal_mix');
      expect(RadioSeedType.discovery.value, 'discovery');
    });
  });

  group('RadioMood', () {
    test('tiene 10 moods con energyLevel', () {
      expect(RadioMood.values, hasLength(10));
    });

    test('energyLevel en rango [0, 1]', () {
      for (final m in RadioMood.values) {
        expect(m.energyLevel, greaterThanOrEqualTo(0));
        expect(m.energyLevel, lessThanOrEqualTo(1));
      }
    });

    test('moods de alta energía: workout=0.9, party=0.85', () {
      expect(RadioMood.workout.energyLevel, 0.9);
      expect(RadioMood.party.energyLevel, 0.85);
      expect(RadioMood.energetic.energyLevel, 0.8);
    });

    test('moods de baja energía: sleep=0.1, relaxed=0.3', () {
      expect(RadioMood.sleep.energyLevel, 0.1);
      expect(RadioMood.relaxed.energyLevel, 0.3);
      expect(RadioMood.chill.energyLevel, 0.35);
    });
  });

  group('RadioStation — getters', () {
    RadioStation buildStation({
      List<MediaItem> queue = const [],
      int currentIndex = 0,
      bool autoRefresh = true,
      int minQueueSize = 5,
    }) =>
        RadioStation(
          id: 'r1', name: 'My Radio',
          seedType: RadioSeedType.song,
          seedValue: 'song-1',
          createdAt: DateTime(2026),
          queue: queue,
          currentIndex: currentIndex,
          autoRefresh: autoRefresh,
          minQueueSize: minQueueSize,
        );

    test('defaults razonables', () {
      final station = buildStation();
      expect(station.description, '');
      expect(station.imageUrl, '');
      expect(station.isPlaying, isFalse);
      expect(station.playCount, 0);
      expect(station.autoRefresh, isTrue);
      expect(station.minQueueSize, 5);
    });

    test('currentSong: null si queue vacío', () {
      final station = buildStation();
      expect(station.currentSong, isNull);
    });

    test('currentSong: retorna queue[currentIndex]', () {
      final items = [
        const MediaItem(id: 'm1', title: 'Song 1'),
        const MediaItem(id: 'm2', title: 'Song 2'),
      ];
      final station = buildStation(queue: items, currentIndex: 1);
      expect(station.currentSong?.id, 'm2');
    });

    test('currentSong: null si currentIndex fuera de rango', () {
      final items = [const MediaItem(id: 'm1', title: 'X')];
      final station = buildStation(queue: items, currentIndex: 5);
      expect(station.currentSong, isNull);
    });

    test('upcomingSongs: vacío si currentIndex es la última', () {
      final items = [const MediaItem(id: 'm1', title: 'X')];
      final station = buildStation(queue: items, currentIndex: 0);
      // upcomingSongs = sublist(currentIndex + 1) = sublist(1) = []
      expect(station.upcomingSongs, isEmpty);
    });

    test('upcomingSongs: retorna desde currentIndex + 1', () {
      final items = List.generate(5, (i) =>
          MediaItem(id: 'm$i', title: 'Song $i'));
      final station = buildStation(queue: items, currentIndex: 1);
      expect(station.upcomingSongs, hasLength(3));
      expect(station.upcomingSongs.first.id, 'm2');
    });
  });

  group('RadioStation.needsRefresh', () {
    test('autoRefresh=false → nunca needsRefresh', () {
      final items = List.generate(2, (i) =>
          MediaItem(id: 'm$i', title: 'X'));
      final station = RadioStation(
        id: 'r', name: 'X',
        seedType: RadioSeedType.song, seedValue: 'X',
        createdAt: DateTime(2026),
        queue: items, currentIndex: 0,
        autoRefresh: false, minQueueSize: 5,
      );
      expect(station.needsRefresh, isFalse);
    });

    test('queue restante <= minQueueSize → needsRefresh true', () {
      final items = List.generate(7, (i) =>
          MediaItem(id: 'm$i', title: 'X'));
      // 7 items, currentIndex 3, restantes = 7 - 3 = 4 (≤ 5)
      final station = RadioStation(
        id: 'r', name: 'X',
        seedType: RadioSeedType.song, seedValue: 'X',
        createdAt: DateTime(2026),
        queue: items, currentIndex: 3,
        minQueueSize: 5,
      );
      expect(station.needsRefresh, isTrue);
    });

    test('queue restante > minQueueSize → needsRefresh false', () {
      final items = List.generate(20, (i) =>
          MediaItem(id: 'm$i', title: 'X'));
      // 20 items, currentIndex 0, restantes = 20 (> 5)
      final station = RadioStation(
        id: 'r', name: 'X',
        seedType: RadioSeedType.song, seedValue: 'X',
        createdAt: DateTime(2026),
        queue: items, currentIndex: 0,
        minQueueSize: 5,
      );
      expect(station.needsRefresh, isFalse);
    });
  });

  group('RadioStation — round-trip JSON', () {
    test('preserva campos básicos', () {
      final original = RadioStation(
        id: 'r1', name: 'My Radio',
        description: 'Una radio chill',
        imageUrl: 'https://x/img.jpg',
        seedType: RadioSeedType.mood,
        seedValue: 'chill',
        mood: RadioMood.chill,
        createdAt: DateTime(2026, 1, 15),
        playCount: 42,
        skippedSongIds: const ['s1', 's2'],
        likedSongIds: const ['l1'],
        autoRefresh: false,
        minQueueSize: 10,
      );
      final restored = RadioStation.fromJson(original.toJson());
      expect(restored.id, 'r1');
      expect(restored.seedType, RadioSeedType.mood);
      expect(restored.mood, RadioMood.chill);
      expect(restored.playCount, 42);
      expect(restored.skippedSongIds, ['s1', 's2']);
      expect(restored.likedSongIds, ['l1']);
      expect(restored.autoRefresh, isFalse);
      expect(restored.minQueueSize, 10);
    });

    test('mood null se preserva', () {
      final original = RadioStation(
        id: 'r1', name: 'X',
        seedType: RadioSeedType.song, seedValue: 's1',
        createdAt: DateTime(2026),
      );
      final restored = RadioStation.fromJson(original.toJson());
      expect(restored.mood, isNull);
    });

    test('fromJson seedType inválido cae a song', () {
      final station = RadioStation.fromJson({
        'id': 'r1', 'name': 'X', 'seedType': 'invalid',
        'seedValue': 'X', 'createdAt': DateTime(2026).toIso8601String(),
      });
      expect(station.seedType, RadioSeedType.song);
    });
  });

  group('RadioStationParams', () {
    test('defaults: initialQueueSize=25, includeExplicit=true', () {
      const params = RadioStationParams(
        seedType: RadioSeedType.artist,
        seedValue: 'a1',
      );
      expect(params.initialQueueSize, 25);
      expect(params.includeExplicit, isTrue);
      expect(params.excludeArtists, isNull);
      expect(params.excludeGenres, isNull);
    });

    test('valores custom se respetan', () {
      const params = RadioStationParams(
        seedType: RadioSeedType.genre,
        seedValue: 'rock',
        mood: RadioMood.energetic,
        initialQueueSize: 50,
        includeExplicit: false,
        excludeArtists: ['Artist 1'],
        excludeGenres: ['Pop'],
        minYear: 1980,
        maxYear: 2000,
        minPopularity: 0.3,
        maxPopularity: 0.8,
      );
      expect(params.initialQueueSize, 50);
      expect(params.includeExplicit, isFalse);
      expect(params.excludeArtists, ['Artist 1']);
      expect(params.minYear, 1980);
      expect(params.maxYear, 2000);
    });
  });
}
