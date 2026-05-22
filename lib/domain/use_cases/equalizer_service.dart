import '../../utils/enums/equalizer_preset.dart';

/// Abstract service for audio equalizer management.
///
/// Implementations provide per-band gain control, preset application,
/// enable/disable toggle, and Hive persistence of user settings.
abstract class EqualizerService {

  /// Whether the equalizer is currently enabled.
  bool get isEnabled;

  /// Enables or disables the equalizer.
  Future<void> setEnabled(bool enabled);

  /// The number of frequency bands available on the device.
  Future<int> getBandCount();

  /// Returns the current gain for each band.
  Future<List<double>> getBandGains();

  /// Returns the center frequency (Hz) for each band.
  Future<List<double>> getCenterFrequencies();

  /// Returns the min/max gain range in dB.
  Future<({double minDb, double maxDb})> getGainRange();

  /// Sets the gain for a specific band.
  Future<void> setBandGain(int bandIndex, double gain);

  /// Applies a preset to all bands.
  Future<void> applyPreset(EqualizerPreset preset);

  /// The currently active preset, or null if custom.
  EqualizerPreset? get activePreset;

  /// Resets all bands to flat (0 dB).
  Future<void> resetBands();

}
