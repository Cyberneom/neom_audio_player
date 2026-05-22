// Tests for `NeomAudioUtilities.sortSongs`. Sorting de AppMediaItem por
// distintos criterios.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/utils/neom_audio_utilities.dart';
import 'package:neom_core/domain/model/app_media_item.dart';

void main() {
  AppMediaItem make({
    required String name,
    String album = '',
    String ownerName = '',
    int releaseDate = 0,
    int duration = 0,
  }) =>
      AppMediaItem(
        id: name,
        name: name,
        album: album,
        ownerName: ownerName,
        releaseDate: releaseDate,
        duration: duration,
      );

  group('sortSongs sortVal=0 (by name)', () {
    test('orden ascendente por name uppercase', () {
      final items = [
        make(name: 'banana'),
        make(name: 'apple'),
        make(name: 'Cherry'),
      ];
      final sorted = NeomAudioUtilities.sortSongs(items, sortVal: 0, order: 0);
      expect(sorted.map((i) => i.name).toList(),
          ['apple', 'banana', 'Cherry']);
    });

    test('order=1 invierte el orden', () {
      final items = [
        make(name: 'apple'),
        make(name: 'banana'),
      ];
      final sorted = NeomAudioUtilities.sortSongs(items, sortVal: 0, order: 1);
      expect(sorted.map((i) => i.name).toList(), ['banana', 'apple']);
    });
  });

  group('sortSongs sortVal=1 (by releaseDate)', () {
    test('orden por releaseDate como string uppercase', () {
      final items = [
        make(name: 'c', releaseDate: 300),
        make(name: 'a', releaseDate: 100),
        make(name: 'b', releaseDate: 200),
      ];
      final sorted = NeomAudioUtilities.sortSongs(items, sortVal: 1, order: 0);
      // 100 → 200 → 300 lexicográfico
      expect(sorted.map((i) => i.name).toList(), ['a', 'b', 'c']);
    });
  });

  group('sortSongs sortVal=2 (by album)', () {
    test('orden alfabético por album', () {
      final items = [
        make(name: 'A', album: 'Beta'),
        make(name: 'B', album: 'Alpha'),
        make(name: 'C', album: 'Gamma'),
      ];
      final sorted = NeomAudioUtilities.sortSongs(items, sortVal: 2, order: 0);
      expect(sorted.map((i) => i.album).toList(),
          ['Alpha', 'Beta', 'Gamma']);
    });
  });

  group('sortSongs sortVal=3 (by ownerName)', () {
    test('orden alfabético por ownerName', () {
      final items = [
        make(name: 'X', ownerName: 'Charlie'),
        make(name: 'Y', ownerName: 'Alice'),
        make(name: 'Z', ownerName: 'Bob'),
      ];
      final sorted = NeomAudioUtilities.sortSongs(items, sortVal: 3, order: 0);
      expect(sorted.map((i) => i.ownerName).toList(),
          ['Alice', 'Bob', 'Charlie']);
    });
  });

  group('sortSongs sortVal=4 (by duration)', () {
    test('orden por duration como string', () {
      final items = [
        make(name: 'a', duration: 300),
        make(name: 'b', duration: 100),
        make(name: 'c', duration: 200),
      ];
      final sorted = NeomAudioUtilities.sortSongs(items, sortVal: 4, order: 0);
      expect(sorted.map((i) => i.name).toList(), ['b', 'c', 'a']);
    });
  });

  group('sortSongs sortVal default (descending releaseDate)', () {
    test('sortVal desconocido cae al default reverse releaseDate', () {
      final items = [
        make(name: 'a', releaseDate: 100),
        make(name: 'b', releaseDate: 300),
        make(name: 'c', releaseDate: 200),
      ];
      final sorted = NeomAudioUtilities.sortSongs(items, sortVal: 99, order: 0);
      // Default es comparación reversa (b primero, a últimos)
      expect(sorted.map((i) => i.name).toList(), ['b', 'c', 'a']);
    });
  });

  group('sortSongs.mediaActions', () {
    test('expone seek/seekForward/seekBackward', () {
      expect(NeomAudioUtilities.mediaActions, hasLength(3));
    });
  });

  group('sortSongs — edge cases', () {
    test('lista vacía → vacía', () {
      final empty = NeomAudioUtilities.sortSongs([], sortVal: 0, order: 0);
      expect(empty, isEmpty);
    });

    test('un solo item → mismo item', () {
      final one = NeomAudioUtilities.sortSongs(
        [make(name: 'solo')], sortVal: 0, order: 0,
      );
      expect(one, hasLength(1));
      expect(one.first.name, 'solo');
    });
  });
}
