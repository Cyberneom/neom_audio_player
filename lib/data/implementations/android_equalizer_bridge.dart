import 'package:neom_sound/neom_sound.dart';

/// Concrete [NativeEqualizerBridge] backed by just_audio's [AndroidEqualizer].
///
/// `just_audio` is re-exported from `neom_sound`, so this bridge imports
/// everything it needs through the single `package:neom_sound/neom_sound.dart`
/// entry point — it never touches `package:just_audio/…` directly.
///
/// Guards against querying `AndroidEqualizer.parameters` before ExoPlayer has
/// bound an Android audio session ID (which throws a native NPE on some
/// Android devices when no track has played yet).
class AndroidEqualizerBridge implements NativeEqualizerBridge {
  final AndroidEqualizer _equalizer;

  AndroidEqualizerBridge(this._equalizer);

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _equalizer.setEnabled(enabled);
    } catch (_) {
      // Equalizer may not have an active Android audio session yet.
    }
  }

  @override
  Future<void> setBandGain(int index, double gain) async {
    try {
      final params = await _equalizer.parameters;
      final bands = params.bands;
      if (index >= 0 && index < bands.length) {
        await bands[index].setGain(gain);
      }
    } catch (_) {
      // Ignore until ExoPlayer attaches an audio session.
    }
  }

  @override
  Future<int> get bandCount async {
    try {
      final params = await _equalizer.parameters;
      return params.bands.length;
    } catch (_) {
      return 0;
    }
  }
}
