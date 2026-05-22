/// Predefined equalizer presets with normalized gain values.
///
/// Each preset provides a [gains] function that returns gain values
/// normalized to the number of bands available on the device hardware.
enum EqualizerPreset {
  flat('flat', 'Flat'),
  bassBoost('bass_boost', 'Bass Boost'),
  trebleBoost('treble_boost', 'Treble Boost'),
  vocal('vocal', 'Vocal'),
  rock('rock', 'Rock'),
  pop('pop', 'Pop'),
  electronic('electronic', 'Electronic');

  final String value;
  final String displayName;

  const EqualizerPreset(this.value, this.displayName);

  /// Returns gain values for each band, normalized to [bandCount].
  ///
  /// Position is normalized 0.0 → 1.0 across the band range so
  /// presets adapt to variable hardware band counts.
  List<double> getGains(int bandCount) {
    if (bandCount <= 0) return const [];
    return List.generate(bandCount, (i) {
      final position = bandCount > 1 ? i / (bandCount - 1) : 0.5;
      return _gainForPosition(position);
    });
  }

  double _gainForPosition(double position) {
    return switch (this) {
      flat => 0.0,
      bassBoost => position < 0.33 ? 8.0
          : position < 0.66 ? 3.0
          : -2.0,
      trebleBoost => position < 0.33 ? -2.0
          : position < 0.66 ? 3.0
          : 8.0,
      vocal => position < 0.2 ? -3.0
          : position < 0.4 ? 2.0
          : position < 0.6 ? 6.0
          : position < 0.8 ? 2.0
          : -3.0,
      rock => position < 0.2 ? 5.0
          : position < 0.4 ? 2.0
          : position < 0.6 ? -1.0
          : position < 0.8 ? 3.0
          : 5.0,
      pop => position < 0.2 ? -1.0
          : position < 0.4 ? 4.0
          : position < 0.6 ? 6.0
          : position < 0.8 ? 4.0
          : -1.0,
      electronic => position < 0.2 ? 6.0
          : position < 0.4 ? 3.0
          : position < 0.6 ? 0.0
          : position < 0.8 ? 3.0
          : 6.0,
    };
  }

}
