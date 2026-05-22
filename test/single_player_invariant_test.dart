import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Architectural invariant**
///
/// At any moment the audio player module must own at most one
/// `just_audio` `AudioPlayer` instance — otherwise two tracks could play on
/// top of each other when the user switches songs. The handler enforces
/// this by:
///
/// 1. Holding a single `late final AudioPlayer player` field.
/// 2. Constructing it exactly once inside `NeomAudioHandler()` (with a
///    web/non-web branch that is mutually exclusive — only one of the two
///    constructor calls runs per instance).
/// 3. Replacing the audio source via `player.setAudioSource(s)` /
///    `player.setAudioSources([...])` instead of spawning new players.
///    `just_audio` guarantees the previous source is stopped before the
///    new one starts when those methods are used on the same player.
/// 4. Being registered as a `fenix: true` singleton in the host app's
///    root binding (`Sint.find<NeomAudioHandler>()` returns the same
///    instance for the lifetime of the process).
///
/// These tests are intentionally **source-level** — they read
/// `lib/neom_audio_handler.dart` as text and assert the structural rules
/// above. The tests are cheap, hermetic, and they fail loudly the moment
/// somebody adds a second `AudioPlayer(...)` constructor call or removes
/// the `late final` modifier.
void main() {
  late String handlerSource;

  /// Strip line comments and block comments so the structural assertions
  /// below cannot be fooled by example snippets in dartdoc strings.
  String stripComments(String src) {
    // Remove /* ... */ block comments (non-greedy, multi-line).
    var out = src.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    // Remove // ... and /// ... line comments.
    out = out.replaceAll(RegExp(r'//[^\n]*'), '');
    return out;
  }

  setUpAll(() {
    final file = File('lib/neom_audio_handler.dart');
    expect(file.existsSync(), isTrue,
        reason: 'lib/neom_audio_handler.dart not found — '
            'are tests being run from the module root?');
    handlerSource = stripComments(file.readAsStringSync());
  });

  group('Single AudioPlayer invariant', () {
    test('NeomAudioHandler declares exactly one AudioPlayer field', () {
      // Match either `late final AudioPlayer player` or
      // `late AudioPlayer player` (defensive against minor refactors).
      final fieldRegex = RegExp(
        r'late\s+(?:final\s+)?AudioPlayer\s+player\b',
      );
      final matches = fieldRegex.allMatches(handlerSource).toList();
      expect(
        matches.length,
        1,
        reason:
            'Expected exactly one `late [final] AudioPlayer player` field '
            'in NeomAudioHandler — found ${matches.length}. '
            'Adding a second player would let two tracks play '
            'simultaneously.',
      );
    });

    test('the player field is declared `late final` (set once)', () {
      expect(
        handlerSource.contains(RegExp(r'late\s+final\s+AudioPlayer\s+player')),
        isTrue,
        reason: 'The player field must be `late final` so it can only be '
            'assigned once during construction.',
      );
    });

    test('AudioPlayer is constructed only inside NeomAudioHandler\'s ctor', () {
      // Find every `AudioPlayer(` constructor call and assert each one
      // lives inside the constructor body. We approximate "inside the
      // constructor" by checking that no constructor call appears after
      // the `_init()` call that sits at the end of the constructor.
      final ctorCalls = RegExp(r'AudioPlayer\s*\(').allMatches(handlerSource);
      expect(ctorCalls, isNotEmpty,
          reason: 'NeomAudioHandler must construct an AudioPlayer.');

      final ctorStart = handlerSource.indexOf('NeomAudioHandler()');
      final ctorEnd = handlerSource.indexOf('Future<void> _init()');
      expect(ctorStart, isNonNegative);
      expect(ctorEnd, greaterThan(ctorStart));

      for (final m in ctorCalls) {
        expect(
          m.start >= ctorStart && m.start < ctorEnd,
          isTrue,
          reason:
              'Found an `AudioPlayer(...)` call outside the NeomAudioHandler '
              'constructor at offset ${m.start}. All player construction '
              'must happen exactly once, in the constructor body.',
        );
      }
    });

    test('there are no more than two AudioPlayer constructor calls (web/non-web branch)', () {
      // The constructor has an `if (!kIsWeb) ... else ...` branch with one
      // call per arm — that is two textual occurrences but only one
      // executes at runtime. Anything beyond two indicates a regression.
      final calls = RegExp(r'AudioPlayer\s*\(').allMatches(handlerSource);
      expect(
        calls.length,
        lessThanOrEqualTo(2),
        reason: 'NeomAudioHandler should construct AudioPlayer at most twice '
            '(one per kIsWeb branch). Found ${calls.length} calls.',
      );
    });

    test('track switching uses player.setAudioSource(s) — not new players', () {
      // The whole point of the invariant: when changing tracks the existing
      // player has its source replaced. The handler must call setAudioSource
      // / setAudioSources at least once.
      final replaces = RegExp(
        r'player\.setAudioSources?\s*\(',
      ).allMatches(handlerSource);
      expect(
        replaces,
        isNotEmpty,
        reason: 'Track switches must go through `player.setAudioSource(s)` so '
            'just_audio atomically stops the previous source.',
      );
    });

    test('handler does not import dart:io to spawn extra player processes', () {
      // Defensive: the handler should not be reaching for Process.start or
      // similar to launch a second audio process behind our back.
      expect(handlerSource.contains('Process.start'), isFalse);
      expect(handlerSource.contains('Process.run'), isFalse);
    });
  });

  group('Module-wide AudioPlayer construction audit', () {
    test('no widget under lib/ui/web/ creates its own AudioPlayer', () {
      final webDir = Directory('lib/ui/web');
      expect(webDir.existsSync(), isTrue);
      final offenders = <String>[];
      for (final entity in webDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = stripComments(entity.readAsStringSync());
        if (RegExp(r'\bAudioPlayer\s*\(').hasMatch(content)) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Web widgets must never instantiate AudioPlayer directly — '
            'they have to go through NeomAudioHandler. Offenders: $offenders',
      );
    });
  });
}
