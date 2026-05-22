import 'package:neom_sound/neom_sound.dart';

/// Concrete [NativeEqualizerBridge] backed by just_audio's [AndroidEqualizer].
///
/// `just_audio` is re-exported from `neom_sound`, so this bridge imports
/// everything it needs through the single `package:neom_sound/neom_sound.dart`
/// entry point — it never touches `package:just_audio/…` directly.
class AndroidEqualizerBridge implements NativeEqualizerBridge {
  final AndroidEqualizer _equalizer;

  AndroidEqualizerBridge(this._equalizer);

  @override
  Future<void> setEnabled(bool enabled) => _equalizer.setEnabled(enabled);

  @override
  Future<void> setBandGain(int index, double gain) async {
    final params = await _equalizer.parameters;
    final bands = params.bands;
    if (index >= 0 && index < bands.length) {
      await bands[index].setGain(gain);
    }
  }

  @override
  Future<int> get bandCount async {
    final params = await _equalizer.parameters;
    return params.bands.length;
  }
}
