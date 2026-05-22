import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neom_audio_player/ui/web/utils/web_player_helpers.dart';

/// Tests for the pure helpers backing the web bottom player UI.
///
/// These cover all the edge cases that the original inline maths in
/// `web_bottom_player.dart` either missed or only partially handled — they
/// are the safety net for the seek-bar refactor.
void main() {
  // ──────────────────────────────────────────────────────────────────────
  // computeSliderValue — slider position as a fraction of the track
  // ──────────────────────────────────────────────────────────────────────
  group('computeSliderValue', () {
    test('returns 0.0 when duration is zero (track not loaded)', () {
      expect(
        computeSliderValue(const Duration(seconds: 5), Duration.zero),
        0.0,
      );
    });

    test('returns 0.0 when duration is negative (defensive)', () {
      expect(
        computeSliderValue(
          const Duration(seconds: 5),
          const Duration(seconds: -10),
        ),
        0.0,
      );
    });

    test('returns 0.0 when position is zero', () {
      expect(
        computeSliderValue(Duration.zero, const Duration(minutes: 3)),
        0.0,
      );
    });

    test('returns 0.0 when position is negative', () {
      expect(
        computeSliderValue(
          const Duration(seconds: -2),
          const Duration(minutes: 3),
        ),
        0.0,
      );
    });

    test('returns 1.0 when position equals duration', () {
      expect(
        computeSliderValue(
          const Duration(minutes: 3),
          const Duration(minutes: 3),
        ),
        1.0,
      );
    });

    test('returns 1.0 when position overshoots duration (end-of-track)', () {
      expect(
        computeSliderValue(
          const Duration(minutes: 3, seconds: 5),
          const Duration(minutes: 3),
        ),
        1.0,
      );
    });

    test('returns 0.5 at the exact midpoint', () {
      final v = computeSliderValue(
        const Duration(minutes: 1, seconds: 30),
        const Duration(minutes: 3),
      );
      expect(v, closeTo(0.5, 1e-9));
    });

    test('returns a value strictly inside (0,1) for normal playback', () {
      final v = computeSliderValue(
        const Duration(seconds: 17),
        const Duration(minutes: 4),
      );
      expect(v, greaterThan(0.0));
      expect(v, lessThan(1.0));
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // sliderValueToPosition — inverse used by the seek-bar drag-end handler
  // ──────────────────────────────────────────────────────────────────────
  group('sliderValueToPosition', () {
    const threeMinutes = Duration(minutes: 3);

    test('0.0 maps to Duration.zero', () {
      expect(sliderValueToPosition(0.0, threeMinutes), Duration.zero);
    });

    test('1.0 maps exactly to the full duration', () {
      expect(sliderValueToPosition(1.0, threeMinutes), threeMinutes);
    });

    test('0.5 maps to roughly the midpoint', () {
      expect(
        sliderValueToPosition(0.5, threeMinutes),
        const Duration(seconds: 90),
      );
    });

    test('values above 1.0 are clamped to the full duration', () {
      expect(sliderValueToPosition(1.7, threeMinutes), threeMinutes);
    });

    test('negative values are clamped to Duration.zero', () {
      expect(sliderValueToPosition(-0.3, threeMinutes), Duration.zero);
    });

    test('NaN inputs fall back to Duration.zero', () {
      expect(sliderValueToPosition(double.nan, threeMinutes), Duration.zero);
    });

    test('round-trips with computeSliderValue at the midpoint', () {
      const target = Duration(seconds: 90);
      final v = computeSliderValue(target, threeMinutes);
      expect(sliderValueToPosition(v, threeMinutes), target);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // formatPlayerDuration
  // ──────────────────────────────────────────────────────────────────────
  group('formatPlayerDuration', () {
    test('formats zero as 0:00', () {
      expect(formatPlayerDuration(Duration.zero), '0:00');
    });

    test('formats sub-minute durations with single-digit minutes', () {
      expect(formatPlayerDuration(const Duration(seconds: 5)), '0:05');
      expect(formatPlayerDuration(const Duration(seconds: 42)), '0:42');
    });

    test('formats sub-hour durations as M:SS', () {
      expect(
        formatPlayerDuration(const Duration(minutes: 2, seconds: 7)),
        '2:07',
      );
      expect(
        formatPlayerDuration(const Duration(minutes: 12, seconds: 34)),
        '12:34',
      );
    });

    test('formats hour-long durations as H:MM:SS', () {
      expect(
        formatPlayerDuration(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '1:02:03',
      );
      expect(
        formatPlayerDuration(const Duration(hours: 2)),
        '2:00:00',
      );
    });

    test('clamps negative durations to 0:00', () {
      expect(formatPlayerDuration(const Duration(seconds: -5)), '0:00');
    });

    test('truncates milliseconds (does not round)', () {
      expect(
        formatPlayerDuration(const Duration(seconds: 5, milliseconds: 999)),
        '0:05',
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // cycleRepeatMode
  // ──────────────────────────────────────────────────────────────────────
  group('cycleRepeatMode', () {
    test('none → all', () {
      expect(
        cycleRepeatMode(AudioServiceRepeatMode.none),
        AudioServiceRepeatMode.all,
      );
    });

    test('all → one', () {
      expect(
        cycleRepeatMode(AudioServiceRepeatMode.all),
        AudioServiceRepeatMode.one,
      );
    });

    test('one → none (closes the cycle)', () {
      expect(
        cycleRepeatMode(AudioServiceRepeatMode.one),
        AudioServiceRepeatMode.none,
      );
    });

    test('three cycles return to the original state', () {
      var mode = AudioServiceRepeatMode.none;
      mode = cycleRepeatMode(mode);
      mode = cycleRepeatMode(mode);
      mode = cycleRepeatMode(mode);
      expect(mode, AudioServiceRepeatMode.none);
    });

    test('group mode collapses to none on next cycle', () {
      expect(
        cycleRepeatMode(AudioServiceRepeatMode.group),
        AudioServiceRepeatMode.none,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // clampVolume
  // ──────────────────────────────────────────────────────────────────────
  group('clampVolume', () {
    test('passes through values inside [0, 1]', () {
      expect(clampVolume(0.0), 0.0);
      expect(clampVolume(0.3), 0.3);
      expect(clampVolume(0.75), 0.75);
      expect(clampVolume(1.0), 1.0);
    });

    test('clamps negative values to 0', () {
      expect(clampVolume(-0.5), 0.0);
      expect(clampVolume(-1e9), 0.0);
    });

    test('clamps over-1 values to 1', () {
      expect(clampVolume(1.7), 1.0);
      expect(clampVolume(double.infinity), 1.0);
    });

    test('NaN falls back to the default fallback', () {
      expect(clampVolume(double.nan), 1.0);
    });

    test('NaN respects a custom fallback', () {
      expect(clampVolume(double.nan, fallback: 0.5), 0.5);
    });
  });
}
