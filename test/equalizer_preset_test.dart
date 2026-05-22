import 'package:flutter_test/flutter_test.dart';

import 'package:neom_audio_player/utils/enums/equalizer_preset.dart';

/// Tests for EqualizerPreset gain generation — verifies normalization
/// across variable band counts, boundary conditions, and preset semantics.
///
/// Hermetic — no Hive, no Android audio, no Sint.
void main() {
  // ──────────────────────────────────────────────────────────────────────
  // getGains basics
  // ──────────────────────────────────────────────────────────────────────
  group('EqualizerPreset.getGains', () {
    test('returns empty list for zero bands', () {
      for (final preset in EqualizerPreset.values) {
        expect(preset.getGains(0), isEmpty);
      }
    });

    test('returns empty list for negative bands', () {
      for (final preset in EqualizerPreset.values) {
        expect(preset.getGains(-1), isEmpty);
      }
    });

    test('returns correct number of gains for any band count', () {
      for (final preset in EqualizerPreset.values) {
        for (final count in [1, 3, 5, 7, 10, 15]) {
          expect(preset.getGains(count).length, count,
              reason: '${preset.name} with $count bands');
        }
      }
    });

    test('flat preset returns all zeros', () {
      final gains = EqualizerPreset.flat.getGains(7);
      expect(gains.every((g) => g == 0.0), isTrue);
    });

    test('flat preset returns zero for single band', () {
      final gains = EqualizerPreset.flat.getGains(1);
      expect(gains, [0.0]);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // Preset semantics — verify shapes make acoustic sense
  // ──────────────────────────────────────────────────────────────────────
  group('EqualizerPreset semantics', () {
    test('bassBoost has higher gain at low frequencies', () {
      final gains = EqualizerPreset.bassBoost.getGains(10);
      // First band (low freq) should be higher than last band (high freq)
      expect(gains.first, greaterThan(gains.last));
    });

    test('trebleBoost has higher gain at high frequencies', () {
      final gains = EqualizerPreset.trebleBoost.getGains(10);
      // Last band (high freq) should be higher than first band (low freq)
      expect(gains.last, greaterThan(gains.first));
    });

    test('vocal preset has peak in mid frequencies', () {
      final gains = EqualizerPreset.vocal.getGains(10);
      final midIndex = gains.length ~/ 2;
      final midGain = gains[midIndex];
      // Mid should be higher than edges
      expect(midGain, greaterThan(gains.first));
      expect(midGain, greaterThan(gains.last));
    });

    test('rock preset has scooped mids (V-shape)', () {
      final gains = EqualizerPreset.rock.getGains(10);
      final midIndex = gains.length ~/ 2;
      // Edges should be higher than mid
      expect(gains.first, greaterThan(gains[midIndex]));
      expect(gains.last, greaterThan(gains[midIndex]));
    });

    test('pop preset has boosted mids', () {
      final gains = EqualizerPreset.pop.getGains(10);
      final midIndex = gains.length ~/ 2;
      expect(gains[midIndex], greaterThan(gains.first));
      expect(gains[midIndex], greaterThan(gains.last));
    });

    test('electronic has boosted edges (W-shape)', () {
      final gains = EqualizerPreset.electronic.getGains(10);
      final midIndex = gains.length ~/ 2;
      expect(gains.first, greaterThan(gains[midIndex]));
      expect(gains.last, greaterThan(gains[midIndex]));
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // Normalization: same preset with different band counts
  // ──────────────────────────────────────────────────────────────────────
  group('EqualizerPreset normalization', () {
    test('bassBoost shape is consistent across 5 and 10 bands', () {
      final gains5 = EqualizerPreset.bassBoost.getGains(5);
      final gains10 = EqualizerPreset.bassBoost.getGains(10);
      // Both should have first > last
      expect(gains5.first, greaterThan(gains5.last));
      expect(gains10.first, greaterThan(gains10.last));
    });

    test('single band uses position 0.5 for all presets', () {
      // With 1 band, position is 0.5 (middle)
      for (final preset in EqualizerPreset.values) {
        final gains = preset.getGains(1);
        expect(gains.length, 1);
        // Should not throw or return NaN
        expect(gains.first.isFinite, isTrue);
      }
    });

    test('gains are within reasonable dB range', () {
      for (final preset in EqualizerPreset.values) {
        final gains = preset.getGains(10);
        for (final gain in gains) {
          expect(gain, greaterThanOrEqualTo(-15.0),
              reason: '${preset.name} gain $gain too low');
          expect(gain, lessThanOrEqualTo(15.0),
              reason: '${preset.name} gain $gain too high');
        }
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // Enum properties
  // ──────────────────────────────────────────────────────────────────────
  group('EqualizerPreset properties', () {
    test('all presets have non-empty value and displayName', () {
      for (final preset in EqualizerPreset.values) {
        expect(preset.value, isNotEmpty, reason: preset.name);
        expect(preset.displayName, isNotEmpty, reason: preset.name);
      }
    });

    test('values are unique', () {
      final values = EqualizerPreset.values.map((p) => p.value).toSet();
      expect(values.length, EqualizerPreset.values.length);
    });

    test('enum count is 7', () {
      expect(EqualizerPreset.values.length, 7);
    });
  });
}
