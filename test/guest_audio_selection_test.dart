import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:neom_audio_player/audio_player_invoker.dart';
import 'package:neom_audio_player/neom_audio_handler.dart';
import 'package:neom_audio_player/ui/player/miniplayer_controller.dart';
import 'package:neom_audio_player/utils/audio_item_source_availability.dart';
import 'package:neom_audio_player/utils/mappers/media_item_mapper.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sint/sint.dart';

class _Handler extends Fake implements NeomAudioHandler {
  @override
  final queue = BehaviorSubject<List<MediaItem>>.seeded([]);
  @override
  final mediaItem = BehaviorSubject<MediaItem?>.seeded(null);
  @override
  final playbackState = BehaviorSubject<PlaybackState>.seeded(PlaybackState());
  @override
  MediaItem? currentMediaItem;
  final starts = <String>[];
  final pendingPlayback = <Completer<void>>[];
  bool failLoad = false;
  int stops = 0;

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {}
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {}
  @override
  Future<void> updateQueue(List<MediaItem> items) async {
    if (failLoad) throw StateError('Fake source unavailable');
    queue.add(items);
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {}
  @override
  Future<void> play() {
    starts.add(currentMediaItem!.id);
    final completion = Completer<void>();
    pendingPlayback.add(completion);
    return completion.future;
  }

  Future<void> disposeFake() async {
    for (final playback in pendingPlayback) {
      playback.complete();
    }
    await Future.wait([
      queue.close(),
      mediaItem.close(),
      playbackState.close(),
    ]);
  }
}

class _Invoker extends AudioPlayerInvoker {
  final _Handler handler;
  _Invoker(this.handler);
  @override
  Future<NeomAudioHandler?> getOrInitAudioHandler() async => handler;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final wasGuest = AppConfig.instance.isGuestMode;
  late _Handler handler;
  late _Invoker invoker;

  setUp(() {
    Sint.testMode = true;
    AppConfig.instance.isGuestMode = true;
    handler = _Handler();
    invoker = _Invoker(handler);
  });
  tearDown(() async {
    await handler.disposeFake();
    Sint.reset();
    AppConfig.instance.isGuestMode = wasGuest;
  });

  test(
    'release mapping uses full URL, including legacy streaming-only songs',
    () async {
      final release = AppReleaseItem(
        id: 'full-song',
        name: 'Complete song',
        streamingUrl: ' https://audio.example/full.mp3 ',
        previewUrl: 'https://audio.example/preview.mp3',
      );
      expect(
        AppMediaItemMapper.fromAppReleaseItem(release).url,
        'https://audio.example/full.mp3',
      );
      expect(
        MediaItemMapper.fromAppReleaseItem(item: release).extras!['url'],
        'https://audio.example/full.mp3',
      );
      release.previewUrl = '';
      await invoker.init(items: [release]);
      expect(
        handler.queue.value.single.extras!['url'],
        'https://audio.example/full.mp3',
      );
      expect(handler.starts, ['full-song']);
      for (final box in [
        AppHiveBox.player,
        AppHiveBox.stats,
        AppHiveBox.downloads,
      ]) {
        expect(Hive.isBoxOpen(box.name), isFalse);
      }
    },
  );

  test(
    'filtered queue keeps the tapped song and replaces the previous queue',
    () async {
      final first = AppMediaItem(
        id: 'first',
        url: 'https://audio.example/first.mp3',
      );
      final selected = AppMediaItem(
        id: 'selected',
        url: 'https://audio.example/selected.mp3',
      );
      final last = AppMediaItem(
        id: 'last',
        url: 'https://audio.example/last.mp3',
      );
      await invoker.init(items: [first]);
      await invoker.init(
        items: [
          AppMediaItem(
            id: 'book',
            type: MediaItemType.pdf,
            url: 'https://audio.example/book.pdf',
          ),
          selected,
          last,
        ],
        index: 1,
      );
      expect(handler.starts, ['first', 'selected']);
      expect(handler.queue.value.map((item) => item.id), ['selected', 'last']);
      expect(handler.currentMediaItem?.id, 'selected');
      expect(invoker.currentReleaseItems, isEmpty);
      expect(
        handler.pendingPlayback.every((future) => !future.isCompleted),
        isTrue,
        reason:
            'A new selection must not wait for the previous song to finish.',
      );
    },
  );

  test('missing selected source never plays its available neighbour', () async {
    await invoker.init(
      items: [
        AppMediaItem(id: 'prior', url: 'https://audio.example/prior.mp3'),
      ],
    );
    await invoker.init(
      items: [
        AppMediaItem(id: 'missing'),
        AppMediaItem(id: 'neighbour', url: 'https://audio.example/other.mp3'),
      ],
    );
    expect(handler.starts, ['prior']);
    expect(handler.currentMediaItem, isNull);
    expect(handler.queue.value, isEmpty);
    expect(handler.stops, greaterThanOrEqualTo(2));
  });

  test(
    'failed source load clears prior playback without starting it again',
    () async {
      await invoker.init(
        items: [
          AppMediaItem(id: 'prior', url: 'https://audio.example/prior.mp3'),
        ],
      );
      handler.failLoad = true;
      await invoker.init(
        items: [
          AppMediaItem(
            id: 'requested',
            url: 'https://audio.example/requested.mp3',
          ),
        ],
      );
      expect(handler.starts, ['prior']);
      expect(handler.queue.value, isEmpty);
      expect(handler.currentMediaItem, isNull);
      expect(Sint.isRegistered<MiniPlayerController>(), isFalse);
    },
  );

  test(
    'web source requires an absolute HTTP URL and preserves signed queries',
    () {
      expect(
        isRemoteAudioSource('https://audio.example/song.mp3?token=secret'),
        isTrue,
      );
      for (final source in [
        '',
        ' ',
        'song.mp3',
        '/song.mp3',
        'file:///song.mp3',
        'javascript:play()',
        'https:///song.mp3',
      ]) {
        expect(isRemoteAudioSource(source), isFalse, reason: source);
      }
    },
  );
}
