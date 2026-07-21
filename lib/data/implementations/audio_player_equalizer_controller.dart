import 'package:hive/hive.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_sound/neom_sound.dart' hide EqualizerPreset, EqualizerService;
import 'package:sint/sint.dart';

import '../../domain/use_cases/audio_player_equalizer_service.dart';
import '../../utils/enums/audio_player_equalizer_preset.dart';

/// Concrete [AudioPlayerEqualizerService] backed by Android's native equalizer
/// via [AndroidEqualizer] from just_audio.
///
/// Persists enabled state, per-band gains, and active preset in Hive.
class AudioPlayerEqualizerController extends SintController implements AudioPlayerEqualizerService {

  static const String _boxName = 'equalizer';

  Box? _box;
  AndroidEqualizer? _equalizer;

  final _isEnabled = false.obs;
  final Rxn<AudioPlayerEqualizerPreset> _activePreset = Rxn<AudioPlayerEqualizerPreset>();

  /// Sets the Android equalizer instance from the audio pipeline.
  void setEqualizer(AndroidEqualizer equalizer) {
    _equalizer = equalizer;
  }

  @override
  void onInit() {
    super.onInit();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      _box = await Hive.openBox(_boxName);
      _isEnabled.value = _box?.get('enabled', defaultValue: false) as bool? ?? false;
      final presetName = _box?.get('activePreset') as String?;
      if (presetName != null) {
        _activePreset.value = AudioPlayerEqualizerPreset.values.firstWhere(
          (e) => e.value == presetName,
          orElse: () => AudioPlayerEqualizerPreset.flat,
        );
      }
      if (_isEnabled.value && _equalizer != null) {
        await _equalizer!.setEnabled(true);
        await _restoreBandGains();
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_audio_player', operation: 'AudioPlayerEqualizerController._initHive');
    }
  }

  // ─── AudioPlayerEqualizerService ─────────────────────────────────────────────────

  @override
  bool get isEnabled => _isEnabled.value;

  @override
  AudioPlayerEqualizerPreset? get activePreset => _activePreset.value;

  @override
  Future<void> setEnabled(bool enabled) async {
    _isEnabled.value = enabled;
    await _box?.put('enabled', enabled);
    await _equalizer?.setEnabled(enabled);
  }

  @override
  Future<int> getBandCount() async {
    if (_equalizer == null) return 0;
    final params = await _equalizer!.parameters;
    return params.bands.length;
  }

  @override
  Future<List<double>> getBandGains() async {
    if (_equalizer == null) return const [];
    final params = await _equalizer!.parameters;
    return params.bands.map((b) => b.gain).toList();
  }

  @override
  Future<List<double>> getCenterFrequencies() async {
    if (_equalizer == null) return const [];
    final params = await _equalizer!.parameters;
    return params.bands.map((b) => b.centerFrequency.toDouble()).toList();
  }

  @override
  Future<({double minDb, double maxDb})> getGainRange() async {
    if (_equalizer == null) return (minDb: -15.0, maxDb: 15.0);
    final params = await _equalizer!.parameters;
    return (minDb: params.minDecibels, maxDb: params.maxDecibels);
  }

  @override
  Future<void> setBandGain(int bandIndex, double gain) async {
    if (_equalizer == null) return;
    final params = await _equalizer!.parameters;
    if (bandIndex < 0 || bandIndex >= params.bands.length) return;

    final clamped = gain.clamp(params.minDecibels, params.maxDecibels);
    await params.bands[bandIndex].setGain(clamped);
    await _box?.put('band_$bandIndex', clamped);
    _activePreset.value = null;
    await _box?.delete('activePreset');
  }

  @override
  Future<void> applyPreset(AudioPlayerEqualizerPreset preset) async {
    if (_equalizer == null) return;
    final params = await _equalizer!.parameters;
    final gains = preset.getGains(params.bands.length);

    for (int i = 0; i < params.bands.length; i++) {
      final clamped = gains[i].clamp(params.minDecibels, params.maxDecibels);
      await params.bands[i].setGain(clamped);
      await _box?.put('band_$i', clamped);
    }

    _activePreset.value = preset;
    await _box?.put('activePreset', preset.value);
    AppConfig.logger.i('Applied equalizer preset: ${preset.displayName}');
  }

  @override
  Future<void> resetBands() async {
    await applyPreset(AudioPlayerEqualizerPreset.flat);
  }

  // ─── Internal ─────────────────────────────────────────────────────────

  Future<void> _restoreBandGains() async {
    if (_equalizer == null || _box == null) return;
    final params = await _equalizer!.parameters;
    for (int i = 0; i < params.bands.length; i++) {
      final gain = _box?.get('band_$i') as double?;
      if (gain != null) {
        await params.bands[i].setGain(
          gain.clamp(params.minDecibels, params.maxDecibels),
        );
      }
    }
  }

}
