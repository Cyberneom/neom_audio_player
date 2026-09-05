import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the decision table implemented in
/// `NeomAudioHandler._setupAudioSessionListeners`, so the intended behaviour is
/// pinned even though the handler itself needs platform channels to run.
({bool pause, bool duck}) onInterruptionBegin(AudioInterruptionType type) =>
    switch (type) {
      AudioInterruptionType.duck => (pause: false, duck: true),
      AudioInterruptionType.pause => (pause: true, duck: false),
      AudioInterruptionType.unknown => (pause: true, duck: false),
    };

bool shouldResumeAfter(AudioInterruptionType type, {required bool weePaused}) =>
    switch (type) {
      AudioInterruptionType.pause => weePaused,
      // Ducking never paused, and `unknown` may mean focus is gone for good.
      AudioInterruptionType.duck => false,
      AudioInterruptionType.unknown => false,
    };

void main() {
  group('audio interruption policy', () {
    test('a call pauses playback', () {
      expect(onInterruptionBegin(AudioInterruptionType.pause).pause, isTrue);
    });

    test('a transient prompt ducks instead of pausing', () {
      final r = onInterruptionBegin(AudioInterruptionType.duck);
      expect(r.duck, isTrue);
      expect(r.pause, isFalse);
    });

    test('unknown interruptions are treated as a pause', () {
      expect(onInterruptionBegin(AudioInterruptionType.unknown).pause, isTrue);
    });

    test('resumes after a call only if we were the ones who paused', () {
      expect(shouldResumeAfter(AudioInterruptionType.pause, weePaused: true), isTrue);
      expect(shouldResumeAfter(AudioInterruptionType.pause, weePaused: false), isFalse);
    });

    test('never auto-resumes after an unknown interruption', () {
      expect(shouldResumeAfter(AudioInterruptionType.unknown, weePaused: true), isFalse);
    });
  });
}
