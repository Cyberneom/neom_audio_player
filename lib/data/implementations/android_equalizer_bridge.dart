import 'package:just_audio/just_audio.dart';
import 'package:neom_sound/domain/use_cases/native_equalizer_bridge.dart';

/// Concrete [NativeEqualizerBridge] backed by just_audio's [AndroidEqualizer].
///
/// Created in neom_audio_player so that neom_sound does NOT depend on just_audio.
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
