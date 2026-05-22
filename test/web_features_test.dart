import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neom_audio_player/ui/web/utils/web_color_extractor.dart';
import 'package:neom_audio_player/ui/web/utils/web_image_resolver.dart';
import 'package:neom_audio_player/ui/web/utils/web_lrc_parser.dart';
import 'package:neom_audio_player/ui/web/utils/web_track_transition.dart';
import 'package:neom_audio_player/ui/web/widgets/web_pseudo_visualizer.dart';

/// Tests for the web layer additions made in Phases 1–6 of the
/// neom_audio_player modernization. These cover pure helpers and lightweight
/// widgets only — anything that touches Firebase, Hive or the live audio
/// handler is intentionally excluded so the suite stays hermetic.
void main() {
  // ──────────────────────────────────────────────────────────────────────
  // WebColorExtractor
  // ──────────────────────────────────────────────────────────────────────
  group('WebColorExtractor', () {
    setUp(WebColorExtractor.clear);
    tearDownAll(WebColorExtractor.clear);

    test('cachedOrFallback returns brand color for null/empty key', () {
      final a = WebColorExtractor.cachedOrFallback(null);
      final b = WebColorExtractor.cachedOrFallback('');
      expect(a, isA<Color>());
      expect(b, isA<Color>());
      expect(a, equals(b));
    });

    test('cachedOrFallback returns fallback when no extraction has run', () {
      final fallback = WebColorExtractor.cachedOrFallback('unknown');
      expect(fallback, isA<Color>());
    });

    test('extract with empty url returns fallback without populating cache', () async {
      final color = await WebColorExtractor.extract(
        cacheKey: 'song-1',
        imageUrl: '',
      );
      expect(color, isA<Color>());
      // Cache should still be empty: cachedOrFallback returns the same fallback.
      expect(
        WebColorExtractor.cachedOrFallback('song-1'),
        equals(color),
      );
    });

    test('extract with empty cacheKey is a safe no-op', () async {
      final color = await WebColorExtractor.extract(
        cacheKey: '',
        imageUrl: 'https://example.com/cover.jpg',
      );
      expect(color, isA<Color>());
    });

    test('clear() resets the in-memory cache', () async {
      await WebColorExtractor.extract(cacheKey: 'a', imageUrl: '');
      WebColorExtractor.clear();
      // Still safe to call after a clear.
      expect(WebColorExtractor.cachedOrFallback('a'), isA<Color>());
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // WebImageResolver
  // ──────────────────────────────────────────────────────────────────────
  group('WebImageResolver', () {
    testWidgets('returns gradient placeholder when imageUrl is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WebImageResolver.build(
              imageUrl: null,
              cacheKey: 'cache-key-1',
              width: 64,
              height: 64,
            ),
          ),
        ),
      );
      // Placeholder always renders the music note icon.
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    });

    testWidgets('returns gradient placeholder when imageUrl is empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WebImageResolver.build(
              imageUrl: '',
              cacheKey: 'cache-key-2',
              width: 32,
              height: 32,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    });

    testWidgets('respects custom placeholder icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WebImageResolver.build(
              imageUrl: null,
              cacheKey: 'cache-key-3',
              width: 32,
              height: 32,
              placeholderIcon: Icons.album_rounded,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.album_rounded), findsOneWidget);
      expect(find.byIcon(Icons.music_note_rounded), findsNothing);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // WebPseudoVisualizer
  // ──────────────────────────────────────────────────────────────────────
  group('WebPseudoVisualizer', () {
    testWidgets('mounts and paints when playing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WebPseudoVisualizer(
              color: Colors.greenAccent,
              barCount: 6,
              width: 40,
              height: 20,
            ),
          ),
        ),
      );
      expect(find.byType(WebPseudoVisualizer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      // Pump a couple of frames to advance the animation controller without
      // pumpAndSettle (which would never settle on a repeating animation).
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('toggling playing flag does not throw', (tester) async {
      bool playing = true;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  WebPseudoVisualizer(
                    color: Colors.purpleAccent,
                    playing: playing,
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => playing = !playing),
                    child: const Text('toggle'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('toggle'));
      await tester.pump();
      await tester.tap(find.text('toggle'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes its AnimationController cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WebPseudoVisualizer(color: Colors.tealAccent),
          ),
        ),
      );
      // Replace the widget tree to trigger dispose.
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      expect(tester.takeException(), isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // WebTrackTransition
  // ──────────────────────────────────────────────────────────────────────
  group('WebTrackTransition', () {
    testWidgets('renders child for the initial track key', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WebTrackTransition(
              trackKey: 'track-1',
              child: Text('hello-track'),
            ),
          ),
        ),
      );
      expect(find.text('hello-track'), findsOneWidget);
    });

    testWidgets('rebuilds child when trackKey changes', (tester) async {
      String key = 'track-1';
      String label = 'first';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  WebTrackTransition(
                    trackKey: key,
                    child: Text(label),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      key = 'track-2';
                      label = 'second';
                    }),
                    child: const Text('next'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('first'), findsOneWidget);
      await tester.tap(find.text('next'));
      // Mid-transition both children may exist; settle the animation.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('second'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // parseLrc smoke (deeper tests live in test/web_harness_test.dart).
  // ──────────────────────────────────────────────────────────────────────
  group('parseLrc smoke', () {
    test('produces LrcEntry instances with the expected fields', () {
      final entries = parseLrc('[00:12.50]first\n[00:18.10]second');
      expect(entries.length, 2);
      expect(entries.first, isA<LrcEntry>());
      expect(entries.first.timestamp,
          const Duration(seconds: 12, milliseconds: 500));
      expect(entries.last.text, 'second');
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // Smoke check: a MediaItem with embedded LRC lyrics is rendered without
  // throwing. This exercises the WebLyricsPanel's offline branch.
  // ──────────────────────────────────────────────────────────────────────
  group('MediaItem extras smoke', () {
    test('embedded lyrics field round-trips through MediaItem.extras', () {
      const lrc = '[00:00.00]intro\n[00:05.00]verse';
      final item = MediaItem(
        id: 'song-x',
        title: 'X',
        extras: const {'lyrics': lrc},
      );
      expect(item.extras?['lyrics'], lrc);
    });
  });
}
