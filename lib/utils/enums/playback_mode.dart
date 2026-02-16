/// Extended playback modes for enhanced audio experience
enum CrossfadeMode {
  /// No crossfade
  off('off', 'Off', Duration.zero),

  /// Short crossfade (2 seconds)
  short('short', 'Short', Duration(seconds: 2)),

  /// Medium crossfade (5 seconds)
  medium('medium', 'Medium', Duration(seconds: 5)),

  /// Long crossfade (8 seconds)
  long('long', 'Long', Duration(seconds: 8)),

  /// Extra long crossfade (12 seconds)
  extraLong('extra_long', 'Extra Long', Duration(seconds: 12)),

  /// Custom duration
  custom('custom', 'Custom', Duration.zero);

  final String value;
  final String displayName;
  final Duration duration;

  const CrossfadeMode(this.value, this.displayName, this.duration);
}

/// Gapless playback modes
enum GaplessMode {
  /// Standard playback with natural gaps
  off('off', 'Off'),

  /// Remove silence at end of tracks
  trimSilence('trim_silence', 'Trim Silence'),

  /// Full gapless playback
  full('full', 'Gapless');

  final String value;
  final String displayName;

  const GaplessMode(this.value, this.displayName);
}

/// Audio normalization modes
enum NormalizationMode {
  /// No normalization
  off('off', 'Off'),

  /// Quiet - lower overall volume
  quiet('quiet', 'Quiet'),

  /// Normal - standard normalization
  normal('normal', 'Normal'),

  /// Loud - maximize without clipping
  loud('loud', 'Loud');

  final String value;
  final String displayName;

  const NormalizationMode(this.value, this.displayName);

  double get targetLoudness {
    switch (this) {
      case off:
        return 0;
      case quiet:
        return -23;
      case normal:
        return -14;
      case loud:
        return -11;
    }
  }
}

/// Sleep timer presets
enum SleepTimerPreset {
  /// 5 minutes
  fiveMinutes('5_min', '5 min', Duration(minutes: 5)),

  /// 10 minutes
  tenMinutes('10_min', '10 min', Duration(minutes: 10)),

  /// 15 minutes
  fifteenMinutes('15_min', '15 min', Duration(minutes: 15)),

  /// 30 minutes
  thirtyMinutes('30_min', '30 min', Duration(minutes: 30)),

  /// 45 minutes
  fortyFiveMinutes('45_min', '45 min', Duration(minutes: 45)),

  /// 1 hour
  oneHour('1_hour', '1 hour', Duration(hours: 1)),

  /// End of track
  endOfTrack('end_track', 'End of track', Duration.zero),

  /// Custom time
  custom('custom', 'Custom', Duration.zero);

  final String value;
  final String displayName;
  final Duration duration;

  const SleepTimerPreset(this.value, this.displayName, this.duration);
}

/// Car mode display options
enum CarModeLayout {
  /// Simple - large buttons only
  simple('simple', 'Simple'),

  /// Standard - buttons with now playing info
  standard('standard', 'Standard'),

  /// Full - includes queue preview
  full('full', 'Full');

  final String value;
  final String displayName;

  const CarModeLayout(this.value, this.displayName);
}
