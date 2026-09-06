import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:neom_audio_player/ui/player/audio_player_controller.dart';
import 'package:neom_audio_player/ui/player/audio_player_page.dart';
import 'package:neom_audio_player/ui/player/miniplayer_controller.dart';
import 'package:neom_audio_player/ui/player/widgets/unavailable_audio_details.dart';
import 'package:neom_audio_player/utils/audio_item_source_availability.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/playable_item.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:sint/sint.dart';

class _UnusedUserService implements UserService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('The catalogue detail must not read user services');
}

class _ExistingMiniPlayer extends MiniPlayerController {
  // Represents an existing session; starting real audio is forbidden here.
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  void onReady() {}
}

void main() {
  final previousGuestMode = AppConfig.instance.isGuestMode;

  setUp(() {
    AppConfig.instance.isGuestMode = true;
    Sint.testMode = true;
  });

  tearDown(() {
    Sint.reset();
    AppConfig.instance.isGuestMode = previousGuestMode;
  });

  Future<void> openDetails(WidgetTester tester, PlayableItem item) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).pushNamed(
                AppRouteConstants.audioPlayerMedia,
                arguments: [item],
              ),
              child: const Text('Open catalogue item'),
            ),
          ),
        ),
        routes: {
          AppRouteConstants.audioPlayerMedia: (_) => const AudioPlayerPage(),
        },
      ),
    );
    await tester.tap(find.text('Open catalogue item'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'missing release source keeps its detail without audio services',
    (tester) async {
      final item = AppReleaseItem(
        id: 'song2444_0',
        name: 'Song 2444',
        ownerName: 'Catalogue artist',
        description: 'Public catalogue description',
      );
      expect(item.mediaType, isNull);
      await openDetails(tester, item);

      expect(find.byType(UnavailableAudioDetails), findsOneWidget);
      expect(find.text(item.name), findsOneWidget);
      expect(find.text(item.ownerName), findsOneWidget);
      expect(find.text(item.description), findsOneWidget);
      expect(
        find.text(CommonTranslationConstants.noAvailablePreviewUrl.tr),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(Sint.isRegistered<UserService>(), isFalse);
      expect(Sint.isRegistered<AudioPlayerInvokerService>(), isFalse);
      expect(
        Sint.isRegistered<AudioPlayerController>(
          tag: AppPageIdConstants.mediaPlayer,
        ),
        isFalse,
      );
      expect(Sint.isRegistered<MiniPlayerController>(), isFalse);
      for (final box in [
        AppHiveBox.player,
        AppHiveBox.settings,
        AppHiveBox.downloads,
      ]) {
        expect(Hive.isBoxOpen(box.name), isFalse);
      }
      expect(tester.takeException(), isNull);

      // The unavailable detail stays open until the user navigates back.
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(UnavailableAudioDetails), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Open catalogue item'), findsOneWidget);
    },
  );

  testWidgets('blank source does not attach the prior playing item', (
    tester,
  ) async {
    Sint.put<UserService>(_UnusedUserService());
    final miniPlayer = _ExistingMiniPlayer();
    const priorItem = MediaItem(
      id: 'previous-track',
      title: 'Previous title',
      artist: 'Previous artist',
      extras: {'url': '/local/previous-track.mp3'},
    );
    miniPlayer.mediaItem.value = priorItem;
    Sint.put<MiniPlayerController>(miniPlayer);

    await openDetails(
      tester,
      AppMediaItem(
        id: 'missing-media',
        name: 'Requested title',
        ownerName: 'Requested artist',
        url: ' \n ',
      ),
    );
    expect(find.text('Requested title'), findsOneWidget);
    expect(find.text('Requested artist'), findsOneWidget);
    expect(find.text('Previous title'), findsNothing);
    expect(miniPlayer.mediaItem.value, same(priorItem));

    miniPlayer.mediaItem.value = priorItem.copyWith(title: 'Another title');
    miniPlayer.update([AppPageIdConstants.miniPlayer, 'web_now_playing_full']);
    await tester.pump();
    expect(find.text('Requested title'), findsOneWidget);
    expect(find.text('Another title'), findsNothing);
    expect(Sint.isRegistered<AudioPlayerInvokerService>(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sint media route retains unavailable metadata and can go back', (
    tester,
  ) async {
    final item = AppReleaseItem(
      id: 'song2444_0',
      name: 'Requested song',
      ownerName: 'Requested artist',
      previewUrl: ' \n ',
      imgUrl: 'file:///bad-cover.png?invalid=query',
    );
    await tester.pumpWidget(
      SintMaterialApp(
        initialRoute: '/',
        sintPages: [
          SintPage(
            name: '/',
            page: () => Scaffold(
              body: TextButton(
                onPressed: () => Sint.toNamed(
                  AppRouteConstants.audioPlayerMedia,
                  arguments: [item],
                ),
                child: const Text('Catalogue'),
              ),
            ),
          ),
          SintPage(
            name: AppRouteConstants.audioPlayerMedia,
            page: () => const AudioPlayerPage(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catalogue'));
    await tester.pumpAndSettle();
    expect(Sint.currentRoute, AppRouteConstants.audioPlayerMedia);
    expect(find.text(item.name), findsOneWidget);
    expect(find.text(item.ownerName), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(Sint.isRegistered<AudioPlayerInvokerService>(), isFalse);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(Sint.currentRoute, '/');
    expect(find.text('Catalogue'), findsOneWidget);
  });

  test(
    'source check keeps explicit offline sources on their existing path',
    () {
      for (final item in <PlayableItem>[
        AppMediaItem(url: '/local/download.mp3'),
        AppMediaItem(url: 'file:///local/download.mp3'),
        AppMediaItem(path: '/local/download.mp3'),
        AppReleaseItem(localPath: '/local/download.mp3'),
        AppReleaseItem(previewUrl: 'file:///local/download.mp3'),
        AppReleaseItem(
          streamingUrl: '',
          previewUrl: 'file:///local/download.mp3',
        ),
        AppMediaItem(url: 'https://example.invalid/track.mp3'),
      ]) {
        expect(hasNoAudioSource(item), isFalse);
      }
      expect(hasNoAudioSource(AppMediaItem(url: ' ', path: ' ')), isTrue);
      expect(
        hasNoAudioSource(AppReleaseItem(previewUrl: '\n', localPath: ' ')),
        isTrue,
      );
    },
  );
}
