import 'package:flutter_test/flutter_test.dart';

import 'package:neom_audio_player/domain/use_cases/enhanced_playback_service.dart';
import 'package:neom_audio_player/utils/enums/playback_mode.dart';

/// Tests for EnhancedPlaybackSettings model — verifies serialization,
/// copyWith, defaults, and pitch field integration.
///
/// Hermetic — no Hive, no audio handler, no Sint.
void main() {
  // ──────────────────────────────────────────────────────────────────────
  // Default values
  // ──────────────────────────────────────────────────────────────────────
  group('EnhancedPlaybackSettings defaults', () {
    test('has sensible default values', () {
      const settings = EnhancedPlaybackSettings();
      expect(settings.crossfadeMode, CrossfadeMode.off);
      expect(settings.gaplessMode, GaplessMode.off);
      expect(settings.normalizationMode, NormalizationMode.off);
      expect(settings.playbackSpeed, 1.0);
      expect(settings.pitch, 1.0);
      expect(settings.skipSilence, isFalse);
      expect(settings.autoCarMode, isFalse);
      expect(settings.sleepTimerFadeOut, isTrue);
      expect(settings.audioFocusMode, AudioFocusMode.duck);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // copyWith
  // ──────────────────────────────────────────────────────────────────────
  group('EnhancedPlaybackSettings.copyWith', () {
    test('copies all fields when none specified', () {
      final original = EnhancedPlaybackSettings(
        playbackSpeed: 1.5,
        pitch: 0.8,
        crossfadeMode: CrossfadeMode.medium,
        skipSilence: true,
      );
      final copy = original.copyWith();
      expect(copy.playbackSpeed, 1.5);
      expect(copy.pitch, 0.8);
      expect(copy.crossfadeMode, CrossfadeMode.medium);
      expect(copy.skipSilence, isTrue);
    });

    test('overrides only specified fields', () {
      const original = EnhancedPlaybackSettings();
      final modified = original.copyWith(pitch: 1.3, playbackSpeed: 0.75);
      expect(modified.pitch, 1.3);
      expect(modified.playbackSpeed, 0.75);
      // Other fields unchanged
      expect(modified.crossfadeMode, CrossfadeMode.off);
      expect(modified.skipSilence, isFalse);
    });

    test('pitch field works independently from speed', () {
      const settings = EnhancedPlaybackSettings();
      final withPitch = settings.copyWith(pitch: 1.5);
      final withSpeed = settings.copyWith(playbackSpeed: 0.5);
      expect(withPitch.pitch, 1.5);
      expect(withPitch.playbackSpeed, 1.0); // unchanged
      expect(withSpeed.playbackSpeed, 0.5);
      expect(withSpeed.pitch, 1.0); // unchanged
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // JSON serialization round-trip
  // ──────────────────────────────────────────────────────────────────────
  group('EnhancedPlaybackSettings JSON', () {
    test('toJson/fromJson round-trip preserves all fields', () {
      final original = EnhancedPlaybackSettings(
        crossfadeMode: CrossfadeMode.long,
        customCrossfadeDuration: const Duration(seconds: 10),
        gaplessMode: GaplessMode.full,
        normalizationMode: NormalizationMode.loud,
        sleepTimerFadeOut: false,
        sleepTimerFadeOutDuration: const Duration(seconds: 15),
        carModeLayout: CarModeLayout.full,
        autoCarMode: true,
        playbackSpeed: 1.75,
        pitch: 0.85,
        skipSilence: true,
        skipSilenceThresholdMs: 300,
        audioFocusMode: AudioFocusMode.pause,
      );

      final json = original.toJson();
      final restored = EnhancedPlaybackSettings.fromJson(json);

      expect(restored.crossfadeMode, CrossfadeMode.long);
      expect(restored.customCrossfadeDuration, const Duration(seconds: 10));
      expect(restored.gaplessMode, GaplessMode.full);
      expect(restored.normalizationMode, NormalizationMode.loud);
      expect(restored.sleepTimerFadeOut, isFalse);
      expect(restored.sleepTimerFadeOutDuration, const Duration(seconds: 15));
      expect(restored.carModeLayout, CarModeLayout.full);
      expect(restored.autoCarMode, isTrue);
      expect(restored.playbackSpeed, 1.75);
      expect(restored.pitch, 0.85);
      expect(restored.skipSilence, isTrue);
      expect(restored.skipSilenceThresholdMs, 300);
      expect(restored.audioFocusMode, AudioFocusMode.pause);
    });

    test('toJson includes pitch field', () {
      final settings = EnhancedPlaybackSettings(pitch: 1.4);
      final json = settings.toJson();
      expect(json.containsKey('pitch'), isTrue);
      expect(json['pitch'], 1.4);
    });

    test('fromJson handles missing pitch gracefully', () {
      final settings = EnhancedPlaybackSettings.fromJson({});
      expect(settings.pitch, 1.0); // default
    });

    test('fromJson handles missing fields with defaults', () {
      final settings = EnhancedPlaybackSettings.fromJson({});
      expect(settings.crossfadeMode, CrossfadeMode.off);
      expect(settings.playbackSpeed, 1.0);
      expect(settings.pitch, 1.0);
      expect(settings.skipSilence, isFalse);
    });

    test('fromJson handles unknown enum values', () {
      final settings = EnhancedPlaybackSettings.fromJson({
        'crossfadeMode': 'nonexistent',
        'gaplessMode': 'nonexistent',
        'normalizationMode': 'nonexistent',
        'audioFocusMode': 'nonexistent',
        'carModeLayout': 'nonexistent',
      });
      expect(settings.crossfadeMode, CrossfadeMode.off);
      expect(settings.gaplessMode, GaplessMode.off);
      expect(settings.normalizationMode, NormalizationMode.off);
      expect(settings.audioFocusMode, AudioFocusMode.duck);
      expect(settings.carModeLayout, CarModeLayout.standard);
    });

    test('fromJson handles null values for numeric fields', () {
      final settings = EnhancedPlaybackSettings.fromJson({
        'playbackSpeed': null,
        'pitch': null,
        'skipSilenceThresholdMs': null,
        'customCrossfadeDuration': null,
        'sleepTimerFadeOutDuration': null,
      });
      expect(settings.playbackSpeed, 1.0);
      expect(settings.pitch, 1.0);
      expect(settings.skipSilenceThresholdMs, 500);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // Playback mode enums
  // ──────────────────────────────────────────────────────────────────────
  group('CrossfadeMode', () {
    test('off has zero duration', () {
      expect(CrossfadeMode.off.duration, Duration.zero);
    });

    test('all modes have non-empty value and displayName', () {
      for (final mode in CrossfadeMode.values) {
        expect(mode.value, isNotEmpty);
        expect(mode.displayName, isNotEmpty);
      }
    });

    test('durations increase from short to extraLong', () {
      expect(CrossfadeMode.short.duration, lessThan(CrossfadeMode.medium.duration));
      expect(CrossfadeMode.medium.duration, lessThan(CrossfadeMode.long.duration));
      expect(CrossfadeMode.long.duration, lessThan(CrossfadeMode.extraLong.duration));
    });
  });

  group('NormalizationMode', () {
    test('off has zero target loudness', () {
      expect(NormalizationMode.off.targetLoudness, 0);
    });

    test('loudness increases from quiet to loud', () {
      expect(NormalizationMode.quiet.targetLoudness,
          lessThan(NormalizationMode.normal.targetLoudness));
      expect(NormalizationMode.normal.targetLoudness,
          lessThan(NormalizationMode.loud.targetLoudness));
    });

    test('all modes have negative LUFS values except off', () {
      for (final mode in NormalizationMode.values) {
        if (mode == NormalizationMode.off) continue;
        expect(mode.targetLoudness, lessThan(0),
            reason: '${mode.name} should have negative LUFS');
      }
    });
  });

  group('AudioFocusMode', () {
    test('has 3 values', () {
      expect(AudioFocusMode.values.length, 3);
    });

    test('all modes have unique values', () {
      final values = AudioFocusMode.values.map((m) => m.value).toSet();
      expect(values.length, AudioFocusMode.values.length);
    });
  });
}
