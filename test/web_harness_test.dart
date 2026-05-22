import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neom_audio_player/ui/web/utils/web_duration_formatter.dart';
import 'package:neom_audio_player/ui/web/utils/web_lrc_parser.dart';
import 'package:neom_audio_player/ui/web/web_keyboard_shortcuts.dart';

/// Harness-style tests for the public web utilities and the keyboard
/// shortcut bindings. These cover code paths that are too tightly coupled to
/// `Sint.find<NeomAudioHandler>()` to test inside a real widget tree, by
/// pulling the underlying logic out into pure functions.
void main() {
  // ──────────────────────────────────────────────────────────────────────
  // parseLrc — public extraction of WebLyricsPanel's parser
  // ──────────────────────────────────────────────────────────────────────
  group('parseLrc', () {
    test('returns empty list for empty input', () {
      expect(parseLrc(''), isEmpty);
    });

    test('returns empty list for whitespace-only input', () {
      expect(parseLrc('   \n\n  \n'), isEmpty);
    });

    test('returns empty list for plain text without timestamps', () {
      expect(parseLrc('hello world\nno timestamps here'), isEmpty);
    });

    test('parses a single timestamp line', () {
      final entries = parseLrc('[00:12.50]hello');
      expect(entries.length, 1);
      expect(entries.first.timestamp,
          const Duration(seconds: 12, milliseconds: 500));
      expect(entries.first.text, 'hello');
    });

    test('parses two-digit milliseconds as centiseconds', () {
      // [00:01.05] = 1.05s = 1050ms (5 centi → 50 ms)
      final entries = parseLrc('[00:01.05]centi');
      expect(entries.first.timestamp,
          const Duration(seconds: 1, milliseconds: 50));
    });

    test('parses three-digit milliseconds verbatim', () {
      final entries = parseLrc('[00:00.123]ms');
      expect(entries.first.timestamp, const Duration(milliseconds: 123));
    });

    test('handles multiple timestamps on the same lyric', () {
      final entries = parseLrc('[00:05.00][01:05.00]repeated');
      expect(entries.length, 2);
      expect(entries.every((e) => e.text == 'repeated'), isTrue);
    });

    test('sorts entries chronologically even when input is reversed', () {
      final entries = parseLrc('[01:00.00]later\n[00:30.00]earlier');
      expect(entries.first.text, 'earlier');
      expect(entries.last.text, 'later');
    });

    test('skips metadata-only lines', () {
      final entries = parseLrc(
        '[ar:Artist]\n[ti:Title]\n[al:Album]\n[00:01.00]first verse',
      );
      expect(entries.length, 1);
      expect(entries.first.text, 'first verse');
    });

    test('preserves the empty text when a stamp has no lyric', () {
      final entries = parseLrc('[00:30.00]');
      expect(entries.length, 1);
      expect(entries.first.text, '');
    });

    test('trims surrounding whitespace from lyric text', () {
      final entries = parseLrc('[00:10.00]   spaced text   ');
      expect(entries.first.text, 'spaced text');
    });

    test('accepts colon as fractional separator', () {
      final entries = parseLrc('[00:10:50]hi');
      expect(entries.first.timestamp,
          const Duration(seconds: 10, milliseconds: 500));
    });

    test('skips lines that do not start with a timestamp', () {
      // The parser anchors on line start, so a garbage prefix invalidates
      // the whole line — even if a valid timestamp appears later in it.
      final entries = parseLrc(
        'garbage [00:02.00]ignored\n[00:03.00]kept',
      );
      expect(entries.length, 1);
      expect(entries.first.text, 'kept');
    });

    test('keeps stable order across many lines', () {
      final raw = List.generate(
        20,
        (i) => '[00:${i.toString().padLeft(2, '0')}.00]line $i',
      ).reversed.join('\n');
      final entries = parseLrc(raw);
      expect(entries.length, 20);
      for (var i = 0; i < entries.length; i++) {
        expect(entries[i].text, 'line $i');
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // formatRemainingDuration — extracted from WebQueuePanel
  // ──────────────────────────────────────────────────────────────────────
  group('formatRemainingDuration', () {
    test('returns "~0 min" for zero duration', () {
      expect(formatRemainingDuration(Duration.zero), '~0 min');
    });

    test('returns "~0 min" for negative duration', () {
      expect(formatRemainingDuration(const Duration(seconds: -30)), '~0 min');
    });

    test('formats sub-hour durations in minutes', () {
      expect(formatRemainingDuration(const Duration(minutes: 1)), '~1 min');
      expect(formatRemainingDuration(const Duration(minutes: 45)), '~45 min');
      expect(formatRemainingDuration(const Duration(minutes: 59)), '~59 min');
    });

    test('formats whole-hour durations without minutes', () {
      expect(formatRemainingDuration(const Duration(hours: 1)), '~1h');
      expect(formatRemainingDuration(const Duration(hours: 3)), '~3h');
    });

    test('formats hour + minute combinations', () {
      expect(
        formatRemainingDuration(const Duration(hours: 1, minutes: 23)),
        '~1h 23min',
      );
      expect(
        formatRemainingDuration(const Duration(hours: 2, minutes: 5)),
        '~2h 5min',
      );
    });

    test('truncates seconds (does not round up)', () {
      // 59m 59s should still report as 59 min, not 1h.
      expect(
        formatRemainingDuration(const Duration(minutes: 59, seconds: 59)),
        '~59 min',
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // webKeyboardShortcuts — verify the activator → intent map
  // ──────────────────────────────────────────────────────────────────────
  group('webKeyboardShortcuts', () {
    test('exposes the expected number of bindings', () {
      // 11 = space + 4 ctrl-arrows + 2 plain arrows + L Q F M
      expect(webKeyboardShortcuts.length, 11);
    });

    test('binds Space to PlayPauseIntent', () {
      final intent = webKeyboardShortcuts[
          const SingleActivator(LogicalKeyboardKey.space)];
      expect(intent, isA<PlayPauseIntent>());
    });

    test('binds Ctrl + ArrowRight to SkipNextIntent', () {
      final intent = webKeyboardShortcuts[const SingleActivator(
          LogicalKeyboardKey.arrowRight,
          control: true)];
      expect(intent, isA<SkipNextIntent>());
    });

    test('binds Ctrl + ArrowLeft to SkipPreviousIntent', () {
      final intent = webKeyboardShortcuts[const SingleActivator(
          LogicalKeyboardKey.arrowLeft,
          control: true)];
      expect(intent, isA<SkipPreviousIntent>());
    });

    test('binds Ctrl + ArrowUp / ArrowDown to volume intents', () {
      expect(
        webKeyboardShortcuts[const SingleActivator(
            LogicalKeyboardKey.arrowUp,
            control: true)],
        isA<VolumeUpIntent>(),
      );
      expect(
        webKeyboardShortcuts[const SingleActivator(
            LogicalKeyboardKey.arrowDown,
            control: true)],
        isA<VolumeDownIntent>(),
      );
    });

    test('binds plain ArrowRight / ArrowLeft to seek intents', () {
      expect(
        webKeyboardShortcuts[
            const SingleActivator(LogicalKeyboardKey.arrowRight)],
        isA<SeekForwardIntent>(),
      );
      expect(
        webKeyboardShortcuts[
            const SingleActivator(LogicalKeyboardKey.arrowLeft)],
        isA<SeekBackwardIntent>(),
      );
    });

    test('binds L / Q / F / M to their toggle intents', () {
      expect(
        webKeyboardShortcuts[
            const SingleActivator(LogicalKeyboardKey.keyL)],
        isA<ToggleLikeIntent>(),
      );
      expect(
        webKeyboardShortcuts[
            const SingleActivator(LogicalKeyboardKey.keyQ)],
        isA<ToggleQueueIntent>(),
      );
      expect(
        webKeyboardShortcuts[
            const SingleActivator(LogicalKeyboardKey.keyF)],
        isA<ToggleFullScreenIntent>(),
      );
      expect(
        webKeyboardShortcuts[
            const SingleActivator(LogicalKeyboardKey.keyM)],
        isA<ToggleMuteIntent>(),
      );
    });

    test('plain arrows are distinct from Ctrl+arrows', () {
      // Sanity: SingleActivator equality is value-based, so these must hash
      // to different keys in the map.
      final plainRight =
          webKeyboardShortcuts[const SingleActivator(LogicalKeyboardKey.arrowRight)];
      final ctrlRight = webKeyboardShortcuts[const SingleActivator(
          LogicalKeyboardKey.arrowRight,
          control: true)];
      expect(plainRight, isNot(equals(ctrlRight)));
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // buildWebKeyboardActions — verifies all 11 Action<Intent> entries exist
  // without invoking them (invocation needs Sint-registered handlers).
  // ──────────────────────────────────────────────────────────────────────
  group('buildWebKeyboardActions', () {
    test('returns an Action for every shortcut intent type', () {
      final actions = buildWebKeyboardActions(
        onToggleQueue: () {},
        onToggleFullScreen: () {},
      );
      expect(actions.containsKey(PlayPauseIntent), isTrue);
      expect(actions.containsKey(SkipNextIntent), isTrue);
      expect(actions.containsKey(SkipPreviousIntent), isTrue);
      expect(actions.containsKey(VolumeUpIntent), isTrue);
      expect(actions.containsKey(VolumeDownIntent), isTrue);
      expect(actions.containsKey(ToggleLikeIntent), isTrue);
      expect(actions.containsKey(ToggleQueueIntent), isTrue);
      expect(actions.containsKey(ToggleFullScreenIntent), isTrue);
      expect(actions.containsKey(ToggleMuteIntent), isTrue);
      expect(actions.containsKey(SeekForwardIntent), isTrue);
      expect(actions.containsKey(SeekBackwardIntent), isTrue);
      expect(actions.length, 11);
    });

    test('ToggleQueueIntent action invokes the provided callback', () {
      var calls = 0;
      final actions = buildWebKeyboardActions(
        onToggleQueue: () => calls++,
      );
      final action = actions[ToggleQueueIntent]!;
      action.invoke(const ToggleQueueIntent());
      expect(calls, 1);
    });

    test('ToggleFullScreenIntent tolerates a null callback', () {
      final actions = buildWebKeyboardActions(onToggleQueue: () {});
      final action = actions[ToggleFullScreenIntent]!;
      // Should not throw even though no callback was provided.
      expect(() => action.invoke(const ToggleFullScreenIntent()),
          returnsNormally);
    });
  });
}
