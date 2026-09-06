import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/ui/player/miniplayer_controller.dart';
import 'package:neom_audio_player/ui/web/web_audio_item_page.dart';
import 'package:neom_audio_player/ui/web/widgets/web_now_playing_full.dart';
import 'package:neom_audio_player/utils/mappers/media_item_mapper.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/playable_item.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:sint/sint.dart';

class _MiniPlayer extends MiniPlayerController {
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  void onReady() {}
}

class _Invoker extends Fake implements AudioPlayerInvokerService {
  final _MiniPlayer mini;
  _Invoker(this.mini);
  Completer<void>? loading;
  bool fail = false;
  int calls = 0;
  @override
  Future<void> init({
    List<PlayableItem>? items,
    List<AppReleaseItem>? releaseItems,
    List<AppMediaItem>? mediaItems,
    int index = 0,
    bool fromMiniPlayer = false,
    bool isOffline = false,
    bool recommend = true,
    bool fromDownloads = false,
    bool shuffle = false,
    String? playlistBox,
    bool playItem = true,
  }) async {
    calls++;
    expect(recommend, isFalse);
    if (loading != null) await loading!.future;
    if (fail) throw StateError('Fake audio load failure');
    mini.mediaItem.value = MediaItemMapper.fromPlayableItem(
      item: items!.single,
    );
  }
}

void main() {
  final wasGuest = AppConfig.instance.isGuestMode;
  late _MiniPlayer mini;
  late _Invoker invoker;
  final requested = AppMediaItem(
    id: 'requested',
    name: 'Requested song',
    lyrics: 'Embedded offline lyrics',
    url: 'https://audio.example/full.mp3',
  );
  setUp(() {
    AppConfig.instance.isGuestMode = true;
    Sint.testMode = true;
    mini = Sint.put<MiniPlayerController>(_MiniPlayer()) as _MiniPlayer;
    mini.mediaItem.value = MediaItemMapper.fromAppMediaItem(
      item: AppMediaItem(
        id: 'prior',
        name: 'Previous song',
        url: 'https://audio.example/prior.mp3',
      ),
    );
    invoker = _Invoker(mini);
    Sint.put<AudioPlayerInvokerService>(invoker);
  });
  tearDown(() {
    Sint.reset();
    AppConfig.instance.isGuestMode = wasGuest;
  });

  testWidgets(
    'route loads the requested song once without exposing prior playback',
    (tester) async {
      invoker.loading = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(home: WebAudioItemPage(item: requested)),
      );
      await tester.pump();
      expect(find.text('Requested song'), findsOneWidget);
      expect(find.text('Previous song'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      invoker.loading!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(WebNowPlayingFull), findsOneWidget);
      expect(mini.visibleMediaItem?.id, 'requested');
      expect(invoker.calls, 1);
      await tester.pump();
      expect(invoker.calls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'failed route retains its title with translated feedback and retry',
    (tester) async {
      invoker.fail = true;
      await tester.pumpWidget(
        MaterialApp(home: WebAudioItemPage(item: requested)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Requested song'), findsOneWidget);
      expect(find.text('Previous song'), findsNothing);
      expect(
        find.text(AppTranslationConstants.playbackErrorStopped.tr),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      invoker.fail = false;
      await tester.tap(find.text(AppTranslationConstants.tryAgain.tr));
      await tester.pump();
      await tester.pump();
      expect(find.byType(WebNowPlayingFull), findsOneWidget);
      expect(invoker.calls, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
