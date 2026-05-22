// Tests for `MediaLyrics`, `CrossfadeMode`, `GaplessMode`, `NormalizationMode`,
// `SleepTimerPreset`, `CarModeLayout`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/domain/models/media_lyrics.dart';
import 'package:neom_audio_player/utils/enums/lyrics_source.dart';
import 'package:neom_audio_player/utils/enums/lyrics_type.dart';
import 'package:neom_audio_player/utils/enums/playback_mode.dart';

void main() {
  group('MediaLyrics', () {
    test('defaults: source=internal, type=text', () {
      final lyrics = MediaLyrics();
      expect(lyrics.mediaId, '');
      expect(lyrics.lyrics, '');
      expect(lyrics.source, LyricsSource.internal);
      expect(lyrics.type, LyricsType.text);
    });

    test('preserva campos custom', () {
      final lyrics = MediaLyrics(
        mediaId: 'm1',
        lyrics: 'Letra de la canción',
        source: LyricsSource.spotify,
        type: LyricsType.lrc,
      );
      expect(lyrics.mediaId, 'm1');
      expect(lyrics.source, LyricsSource.spotify);
      expect(lyrics.type, LyricsType.lrc);
    });
  });

  group('CrossfadeMode', () {
    test('tiene 6 modos: off, short, medium, long, extraLong, custom', () {
      expect(CrossfadeMode.values, hasLength(6));
    });

    test('off → Duration.zero', () {
      expect(CrossfadeMode.off.duration, Duration.zero);
      expect(CrossfadeMode.off.value, 'off');
    });

    test('duraciones específicas: short=2s, medium=5s, long=8s, extraLong=12s', () {
      expect(CrossfadeMode.short.duration, const Duration(seconds: 2));
      expect(CrossfadeMode.medium.duration, const Duration(seconds: 5));
      expect(CrossfadeMode.long.duration, const Duration(seconds: 8));
      expect(CrossfadeMode.extraLong.duration, const Duration(seconds: 12));
    });

    test('custom usa Duration.zero como placeholder', () {
      expect(CrossfadeMode.custom.duration, Duration.zero);
    });

    test('cada modo tiene displayName único', () {
      final names = CrossfadeMode.values.map((m) => m.displayName).toSet();
      expect(names.length, 6);
    });
  });

  group('GaplessMode', () {
    test('tiene 3 modos', () {
      expect(GaplessMode.values, hasLength(3));
      expect(GaplessMode.values, [
        GaplessMode.off,
        GaplessMode.trimSilence,
        GaplessMode.full,
      ]);
    });

    test('valores: off, trim_silence, full', () {
      expect(GaplessMode.off.value, 'off');
      expect(GaplessMode.trimSilence.value, 'trim_silence');
      expect(GaplessMode.full.value, 'full');
    });
  });

  group('NormalizationMode', () {
    test('tiene 4 modos', () {
      expect(NormalizationMode.values, hasLength(4));
    });

    test('targetLoudness: off=0, quiet=-23, normal=-14, loud=-11', () {
      expect(NormalizationMode.off.targetLoudness, 0);
      expect(NormalizationMode.quiet.targetLoudness, -23);
      expect(NormalizationMode.normal.targetLoudness, -14);
      expect(NormalizationMode.loud.targetLoudness, -11);
    });

    test('orden: off → quiet → normal → loud (loudness creciente)', () {
      expect(NormalizationMode.quiet.targetLoudness,
          lessThan(NormalizationMode.normal.targetLoudness));
      expect(NormalizationMode.normal.targetLoudness,
          lessThan(NormalizationMode.loud.targetLoudness));
    });
  });

  group('SleepTimerPreset', () {
    test('tiene 8 presets', () {
      expect(SleepTimerPreset.values, hasLength(8));
    });

    test('duraciones: 5min, 10min, 15min, 30min, 45min, 1h', () {
      expect(SleepTimerPreset.fiveMinutes.duration, const Duration(minutes: 5));
      expect(SleepTimerPreset.tenMinutes.duration, const Duration(minutes: 10));
      expect(SleepTimerPreset.fifteenMinutes.duration, const Duration(minutes: 15));
      expect(SleepTimerPreset.thirtyMinutes.duration, const Duration(minutes: 30));
      expect(SleepTimerPreset.fortyFiveMinutes.duration, const Duration(minutes: 45));
      expect(SleepTimerPreset.oneHour.duration, const Duration(hours: 1));
    });

    test('endOfTrack y custom usan Duration.zero', () {
      expect(SleepTimerPreset.endOfTrack.duration, Duration.zero);
      expect(SleepTimerPreset.custom.duration, Duration.zero);
    });

    test('todos tienen value + displayName únicos', () {
      final values = SleepTimerPreset.values.map((p) => p.value).toSet();
      final names = SleepTimerPreset.values.map((p) => p.displayName).toSet();
      expect(values.length, 8);
      expect(names.length, 8);
    });

    test('orden ascendente de duraciones (excluyendo zero)', () {
      final sorted = [
        SleepTimerPreset.fiveMinutes,
        SleepTimerPreset.tenMinutes,
        SleepTimerPreset.fifteenMinutes,
        SleepTimerPreset.thirtyMinutes,
        SleepTimerPreset.fortyFiveMinutes,
        SleepTimerPreset.oneHour,
      ];
      for (var i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i].duration, lessThan(sorted[i + 1].duration));
      }
    });
  });

  group('CarModeLayout', () {
    test('tiene 3 layouts: simple, standard, full', () {
      expect(CarModeLayout.values, hasLength(3));
    });

    test('valores y displayNames únicos', () {
      final values = CarModeLayout.values.map((l) => l.value).toSet();
      final names = CarModeLayout.values.map((l) => l.displayName).toSet();
      expect(values.length, 3);
      expect(names.length, 3);
    });
  });
}
