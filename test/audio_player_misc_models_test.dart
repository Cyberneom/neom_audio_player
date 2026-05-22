// Tests for `MediaState`, `QueueState`, `PositionData`, `LyricsCacheEntry`,
// `LyricsSource`, `LyricsType`, `PlaylistItem`, `PlaylistSection`,
// `PlaylistType`.

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/domain/models/lyrics_cache_entry.dart';
import 'package:neom_audio_player/domain/models/media_state.dart';
import 'package:neom_audio_player/domain/models/playlist_item.dart';
import 'package:neom_audio_player/domain/models/playlist_section.dart';
import 'package:neom_audio_player/domain/models/position_data.dart';
import 'package:neom_audio_player/domain/models/queue_state.dart';
import 'package:neom_audio_player/utils/enums/lyrics_source.dart';
import 'package:neom_audio_player/utils/enums/lyrics_type.dart';
import 'package:neom_audio_player/utils/enums/playlist_type.dart';

void main() {
  group('MediaState', () {
    test('preserva mediaItem y position', () {
      final state = MediaState(
        const MediaItem(id: 'm1', title: 'X'),
        const Duration(seconds: 30),
      );
      expect(state.mediaItem?.id, 'm1');
      expect(state.position, const Duration(seconds: 30));
    });

    test('mediaItem null permitido', () {
      final state = MediaState(null, Duration.zero);
      expect(state.mediaItem, isNull);
    });
  });

  group('PositionData', () {
    test('preserva las 3 durations', () {
      final data = PositionData(
        const Duration(seconds: 30),
        const Duration(seconds: 60),
        const Duration(seconds: 180),
      );
      expect(data.position, const Duration(seconds: 30));
      expect(data.bufferedPosition, const Duration(seconds: 60));
      expect(data.duration, const Duration(seconds: 180));
    });
  });

  group('QueueState', () {
    test('static empty: queue vacío, queueIndex=0, repeatMode=none', () {
      const empty = QueueState.empty;
      expect(empty.queue, isEmpty);
      expect(empty.queueIndex, 0);
      expect(empty.shuffleIndices, isEmpty);
      expect(empty.repeatMode, AudioServiceRepeatMode.none);
    });

    test('hasPrevious: false en queueIndex=0 con repeat=none', () {
      const state = QueueState(
        [], 0, [], AudioServiceRepeatMode.none,
      );
      expect(state.hasPrevious, isFalse);
    });

    test('hasPrevious: true con queueIndex > 0', () {
      const state = QueueState(
        [
          MediaItem(id: 'm1', title: 'X'),
          MediaItem(id: 'm2', title: 'Y'),
        ],
        1, [], AudioServiceRepeatMode.none,
      );
      expect(state.hasPrevious, isTrue);
    });

    test('hasPrevious: true cuando repeat != none aunque queueIndex=0', () {
      const state = QueueState(
        [MediaItem(id: 'm1', title: 'X')],
        0, [], AudioServiceRepeatMode.all,
      );
      expect(state.hasPrevious, isTrue);
    });

    test('hasNext: true si queueIndex+1 < queue.length', () {
      const state = QueueState(
        [
          MediaItem(id: 'm1', title: 'X'),
          MediaItem(id: 'm2', title: 'Y'),
        ],
        0, [], AudioServiceRepeatMode.none,
      );
      expect(state.hasNext, isTrue);
    });

    test('hasNext: false en última con repeat=none', () {
      const state = QueueState(
        [MediaItem(id: 'm1', title: 'X')],
        0, [], AudioServiceRepeatMode.none,
      );
      expect(state.hasNext, isFalse);
    });

    test('hasNext: true en última con repeat=all', () {
      const state = QueueState(
        [MediaItem(id: 'm1', title: 'X')],
        0, [], AudioServiceRepeatMode.all,
      );
      expect(state.hasNext, isTrue);
    });

    test('indices: usa shuffleIndices si no null', () {
      const state = QueueState(
        [
          MediaItem(id: 'a', title: 'a'),
          MediaItem(id: 'b', title: 'b'),
        ],
        0, [1, 0], AudioServiceRepeatMode.none,
      );
      expect(state.indices, [1, 0]);
    });

    test('indices: genera secuencial cuando shuffleIndices=null', () {
      const state = QueueState(
        [
          MediaItem(id: 'a', title: 'a'),
          MediaItem(id: 'b', title: 'b'),
          MediaItem(id: 'c', title: 'c'),
        ],
        0, null, AudioServiceRepeatMode.none,
      );
      expect(state.indices, [0, 1, 2]);
    });
  });

  group('LyricsSource / LyricsType', () {
    test('LyricsSource tiene 6 valores', () {
      expect(LyricsSource.values, hasLength(6));
      expect(LyricsSource.values, [
        LyricsSource.internal,
        LyricsSource.spotify,
        LyricsSource.google,
        LyricsSource.musicMatch,
        LyricsSource.whisper,
        LyricsSource.other,
      ]);
    });

    test('LyricsType tiene 4 valores', () {
      expect(LyricsType.values, hasLength(4));
    });
  });

  group('LyricsCacheEntry', () {
    test('defaults: source=internal, type=text', () {
      final entry = LyricsCacheEntry();
      expect(entry.mediaId, '');
      expect(entry.lyrics, '');
      expect(entry.source, LyricsSource.internal);
      expect(entry.type, LyricsType.text);
    });

    test('isExpired: false dentro de 72 horas', () {
      final entry = LyricsCacheEntry(
        cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(entry.isExpired, isFalse);
    });

    test('isExpired: true después de 72 horas', () {
      final entry = LyricsCacheEntry(
        cachedAt: DateTime.now().subtract(const Duration(hours: 73)),
      );
      expect(entry.isExpired, isTrue);
    });

    test('round-trip JSON', () {
      final original = LyricsCacheEntry(
        mediaId: 'm1',
        lyrics: 'Letra de la canción...',
        source: LyricsSource.spotify,
        type: LyricsType.lrc,
        cachedAt: DateTime(2026, 1, 15),
      );
      final restored = LyricsCacheEntry.fromJSON(original.toJSON());
      expect(restored.mediaId, 'm1');
      expect(restored.lyrics, 'Letra de la canción...');
      expect(restored.source, LyricsSource.spotify);
      expect(restored.type, LyricsType.lrc);
      expect(restored.cachedAt.year, 2026);
    });

    test('fromJSON con mapa vacío usa defaults', () {
      final entry = LyricsCacheEntry.fromJSON({});
      expect(entry.mediaId, '');
      expect(entry.source, LyricsSource.internal);
      expect(entry.type, LyricsType.text);
    });

    test('fromJSON con source inválido cae a internal', () {
      final entry = LyricsCacheEntry.fromJSON({'source': 'invalid'});
      expect(entry.source, LyricsSource.internal);
    });
  });

  group('PlaylistType (audio_player module)', () {
    test('tiene 4 valores con value', () {
      expect(PlaylistType.values, hasLength(4));
      expect(PlaylistType.audio.value, 'audio');
      expect(PlaylistType.video.value, 'video');
      expect(PlaylistType.playlist.value, 'playlist');
      expect(PlaylistType.chart.value, 'chart');
    });
  });

  group('PlaylistItem', () {
    test('defaults: type=playlist, count=0', () {
      final item = PlaylistItem();
      expect(item.id, '');
      expect(item.type, PlaylistType.playlist);
      expect(item.count, 0);
    });

    test('toJSON serializa type.name', () {
      final item = PlaylistItem(
        id: 'p1', title: 'My Playlist',
        type: PlaylistType.audio, count: 5,
      );
      final json = item.toJSON();
      expect(json['id'], 'p1');
      expect(json['type'], 'audio');
      expect(json['count'], 5);
    });

    test('NC-playlist-01: fromJSON usa "playlistId" no "id" como key', () {
      // Documentado: el fromJSON usa "playlistId" pero toJSON usa "id".
      // Es asimétrico: round-trip directo NO funciona.
      final item = PlaylistItem.fromJSON({
        'playlistId': 'p1',
        'title': 'My Playlist',
        'subtitle': 'sub',
        'description': 'desc',
        'firstItemId': '',
        'imgUrl': 'https://x',
        'type': 'audio',
        'count': '5',
      });
      expect(item.id, 'p1');
      expect(item.title, 'My Playlist');
      expect(item.count, 5);
    });

    test('NC-playlist-02: int.parse crashea si count es null', () {
      // Documentado: data['count'].toString() devuelve "null" si count falta,
      // y int.parse("null") crashea.
      expect(
        () => PlaylistItem.fromJSON({
          'playlistId': 'p1', 'title': 'X', 'subtitle': '',
          'description': '', 'firstItemId': '', 'imgUrl': '',
          'type': 'playlist',
          // sin 'count'
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PlaylistSection', () {
    test('defaults: title vacío, playlistItems null', () {
      final section = PlaylistSection();
      expect(section.title, '');
      expect(section.playlistItems, isNull);
    });

    test('preserva título y items', () {
      final section = PlaylistSection(
        title: 'Recomendados',
        playlistItems: [
          PlaylistItem(id: 'p1', title: 'X'),
        ],
      );
      expect(section.title, 'Recomendados');
      expect(section.playlistItems, hasLength(1));
    });
  });
}
