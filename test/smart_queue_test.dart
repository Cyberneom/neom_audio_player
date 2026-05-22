// Tests for `SmartQueue`, `SmartQueueItem`, `QueueItemSource`,
// `RecommendationSource`, `RecommendationParams`.

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/domain/models/smart_queue.dart';

void main() {
  group('QueueItemSource', () {
    test('tiene 10 sources', () {
      expect(QueueItemSource.values, hasLength(10));
    });

    test('cada source tiene value + displayName únicos', () {
      final values = QueueItemSource.values.map((s) => s.value).toSet();
      final names = QueueItemSource.values.map((s) => s.displayName).toSet();
      expect(values.length, 10);
      expect(names.length, 10);
    });
  });

  group('RecommendationSource', () {
    test('tiene 7 sources', () {
      expect(RecommendationSource.values, hasLength(7));
    });

    test('value específicos', () {
      expect(RecommendationSource.currentSong.value, 'current_song');
      expect(RecommendationSource.collaborative.value, 'collaborative');
    });
  });

  group('SmartQueueItem', () {
    test('defaults: isRecommendation=false', () {
      final item = SmartQueueItem(
        mediaItem: const MediaItem(id: 'm1', title: 'X'),
        source: QueueItemSource.userAdded,
        addedAt: DateTime(2026),
        addedBy: 'u1',
      );
      expect(item.isRecommendation, isFalse);
      expect(item.recommendationScore, isNull);
      expect(item.recommendationReason, isNull);
    });

    test('copyWith preserva campos no especificados', () {
      final original = SmartQueueItem(
        mediaItem: const MediaItem(id: 'm1', title: 'X'),
        source: QueueItemSource.userAdded,
        addedAt: DateTime(2026),
        addedBy: 'u1',
      );
      final copy = original.copyWith(
        isRecommendation: true,
        recommendationScore: 0.85,
      );
      expect(copy.mediaItem.id, 'm1');
      expect(copy.isRecommendation, isTrue);
      expect(copy.recommendationScore, 0.85);
    });
  });

  group('SmartQueue — defaults & getters', () {
    SmartQueueItem makeItem(String id) => SmartQueueItem(
      mediaItem: MediaItem(id: id, title: 'Song $id'),
      source: QueueItemSource.userAdded,
      addedAt: DateTime(2026),
      addedBy: 'u1',
    );

    test('defaults', () {
      const queue = SmartQueue();
      expect(queue.items, isEmpty);
      expect(queue.currentIndex, 0);
      expect(queue.isShuffled, isFalse);
      expect(queue.autoAddRecommendations, isTrue);
      expect(queue.minItemsForAutoAdd, 3);
      expect(queue.playHistory, isEmpty);
      expect(queue.avoidSongs, isEmpty);
    });

    test('currentItem: null si items vacío', () {
      const queue = SmartQueue();
      expect(queue.currentItem, isNull);
    });

    test('currentItem: null si currentIndex < 0', () {
      final queue = SmartQueue(
        items: [makeItem('a')],
        currentIndex: -1,
      );
      expect(queue.currentItem, isNull);
    });

    test('currentItem: retorna items[currentIndex] cuando no shuffled', () {
      final queue = SmartQueue(
        items: [makeItem('a'), makeItem('b'), makeItem('c')],
        currentIndex: 1,
      );
      expect(queue.currentItem?.mediaItem.id, 'b');
    });

    test('currentItem: shuffled usa shuffleIndices', () {
      final queue = SmartQueue(
        items: [makeItem('a'), makeItem('b'), makeItem('c')],
        shuffleIndices: const [2, 0, 1],
        currentIndex: 0,
        isShuffled: true,
      );
      // currentIndex 0 → shuffleIndices[0] = 2 → items[2] = 'c'
      expect(queue.currentItem?.mediaItem.id, 'c');
    });

    test('currentItem: shuffled out-of-bounds shuffleIndices → null', () {
      final queue = SmartQueue(
        items: [makeItem('a'), makeItem('b')],
        shuffleIndices: const [0, 1],
        currentIndex: 5, // > shuffleIndices.length
        isShuffled: true,
      );
      expect(queue.currentItem, isNull);
    });

    test('mediaItems: retorna lista de MediaItem', () {
      final queue = SmartQueue(
        items: [makeItem('a'), makeItem('b')],
      );
      expect(queue.mediaItems.map((m) => m.id).toList(), ['a', 'b']);
    });
  });

  group('SmartQueue.upcomingItems', () {
    SmartQueueItem makeItem(String id) => SmartQueueItem(
      mediaItem: MediaItem(id: id, title: id),
      source: QueueItemSource.userAdded,
      addedAt: DateTime(2026),
      addedBy: 'u1',
    );

    test('vacío si items vacío', () {
      const queue = SmartQueue();
      expect(queue.upcomingItems, isEmpty);
    });

    test('vacío si currentIndex es la última', () {
      final queue = SmartQueue(
        items: [makeItem('a')],
        currentIndex: 0,
      );
      // upcomingItems = [] cuando currentIndex >= items.length - 1
      expect(queue.upcomingItems, isEmpty);
    });

    test('returns siguientes items en orden cuando no shuffled', () {
      final queue = SmartQueue(
        items: [makeItem('a'), makeItem('b'), makeItem('c'), makeItem('d')],
        currentIndex: 1,
      );
      expect(queue.upcomingItems.map((i) => i.mediaItem.id).toList(),
          ['c', 'd']);
    });

    test('returns siguientes en shuffled order', () {
      final queue = SmartQueue(
        items: [makeItem('a'), makeItem('b'), makeItem('c'), makeItem('d')],
        shuffleIndices: const [3, 1, 0, 2],
        currentIndex: 1,
        isShuffled: true,
      );
      // currentIndex 1, shuffleIndices.sublist(2) = [0, 2] → items[0]='a', items[2]='c'
      expect(queue.upcomingItems.map((i) => i.mediaItem.id).toList(),
          ['a', 'c']);
    });

    test('shuffled con índices fuera de rango filtra defensivamente', () {
      final queue = SmartQueue(
        items: [makeItem('a'), makeItem('b')],
        shuffleIndices: const [0, 99, 1], // 99 inválido
        currentIndex: 0,
        isShuffled: true,
      );
      // upcomingItems desde sublist(1) = [99, 1], filtra inválidos
      expect(queue.upcomingItems.map((i) => i.mediaItem.id).toList(),
          ['b']); // 99 filtrado, 1 válido
    });
  });

  group('SmartQueue.shouldAddRecommendations', () {
    SmartQueueItem makeItem(String id) => SmartQueueItem(
      mediaItem: MediaItem(id: id, title: id),
      source: QueueItemSource.userAdded,
      addedAt: DateTime(2026),
      addedBy: 'u1',
    );

    test('autoAddRecommendations=false → siempre false', () {
      final queue = SmartQueue(
        items: List.generate(10, (i) => makeItem('$i')),
        autoAddRecommendations: false,
      );
      expect(queue.shouldAddRecommendations, isFalse);
    });

    test('upcomingItems > minItemsForAutoAdd → false', () {
      final queue = SmartQueue(
        items: List.generate(10, (i) => makeItem('$i')),
        currentIndex: 0,
        minItemsForAutoAdd: 3,
      );
      // upcoming = 9, 9 > 3 → false
      expect(queue.shouldAddRecommendations, isFalse);
    });

    test('upcomingItems <= minItemsForAutoAdd → true', () {
      final queue = SmartQueue(
        items: List.generate(5, (i) => makeItem('$i')),
        currentIndex: 2,
        minItemsForAutoAdd: 3,
      );
      // upcoming = 2, 2 <= 3 → true
      expect(queue.shouldAddRecommendations, isTrue);
    });
  });

  group('RecommendationParams', () {
    test('default count=10, opcionales null', () {
      const params = RecommendationParams();
      expect(params.count, 10);
      expect(params.seedSongIds, isNull);
      expect(params.seedArtistIds, isNull);
      expect(params.targetEnergy, isNull);
      expect(params.minYear, isNull);
    });

    test('toJson omite campos null', () {
      const params = RecommendationParams(count: 20);
      final json = params.toJson();
      expect(json['count'], 20);
      expect(json.containsKey('seedSongIds'), isFalse);
      expect(json.containsKey('targetEnergy'), isFalse);
    });

    test('toJson incluye campos no-null', () {
      const params = RecommendationParams(
        count: 5,
        seedSongIds: ['s1', 's2'],
        targetEnergy: 0.7,
        targetDanceability: 0.8,
        targetValence: 0.6,
        minPopularity: 30,
        maxPopularity: 90,
        minYear: 2000,
        maxYear: 2025,
        excludeSongIds: ['x1'],
        excludeArtistIds: ['a1'],
        seedArtistIds: ['a2'],
        seedGenres: ['rock'],
      );
      final json = params.toJson();
      expect(json['count'], 5);
      expect(json['seedSongIds'], ['s1', 's2']);
      expect(json['targetEnergy'], 0.7);
      expect(json['minPopularity'], 30);
      expect(json['minYear'], 2000);
      expect(json['excludeSongIds'], ['x1']);
      expect(json['seedGenres'], ['rock']);
    });
  });
}
