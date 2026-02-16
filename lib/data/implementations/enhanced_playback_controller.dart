import 'dart:async';

import 'package:hive/hive.dart';
import 'package:sint/sint.dart';

import '../../domain/use_cases/enhanced_playback_service.dart';
import '../../utils/enums/playback_mode.dart';

/// Controller implementation for enhanced playback features
class EnhancedPlaybackController extends SintController
    implements EnhancedPlaybackService {
  static const String _boxName = 'enhanced_playback';
  static const String _settingsKey = 'settings';

  Box? _box;

  final _settings = Rx<EnhancedPlaybackSettings>(const EnhancedPlaybackSettings());
  final _sleepTimerRemaining = Rx<Duration>(Duration.zero);
  final _isSleepTimerActive = false.obs;
  final _isCarModeActive = false.obs;
  final _currentLoudness = 0.0.obs;
  final _activeSleepTimerPreset = Rxn<SleepTimerPreset>();

  Timer? _sleepTimer;
  Timer? _fadeOutTimer;
  final _sleepTimerStreamController = StreamController<Duration>.broadcast();

  // Volume for fade out
  double _originalVolume = 1.0;

  @override
  void onInit() {
    super.onInit();
    _initHive();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox(_boxName);
    await loadSettings();
  }

  // ============ Crossfade ============

  @override
  CrossfadeMode get crossfadeMode => _settings.value.crossfadeMode;

  @override
  Duration get customCrossfadeDuration => _settings.value.customCrossfadeDuration;

  @override
  bool get isCrossfadeEnabled => _settings.value.crossfadeMode != CrossfadeMode.off;

  @override
  Duration get effectiveCrossfadeDuration {
    if (_settings.value.crossfadeMode == CrossfadeMode.custom) {
      return _settings.value.customCrossfadeDuration;
    }
    return _settings.value.crossfadeMode.duration;
  }

  @override
  Future<void> setCrossfadeMode(CrossfadeMode mode) async {
    _settings.value = _settings.value.copyWith(crossfadeMode: mode);
    await saveSettings();
  }

  @override
  Future<void> setCustomCrossfadeDuration(Duration duration) async {
    _settings.value = _settings.value.copyWith(
      crossfadeMode: CrossfadeMode.custom,
      customCrossfadeDuration: duration,
    );
    await saveSettings();
  }

  // ============ Gapless ============

  @override
  GaplessMode get gaplessMode => _settings.value.gaplessMode;

  @override
  bool get isGaplessEnabled => _settings.value.gaplessMode != GaplessMode.off;

  @override
  Future<void> setGaplessMode(GaplessMode mode) async {
    _settings.value = _settings.value.copyWith(gaplessMode: mode);
    await saveSettings();
  }

  // ============ Normalization ============

  @override
  NormalizationMode get normalizationMode => _settings.value.normalizationMode;

  @override
  bool get isNormalizationEnabled => _settings.value.normalizationMode != NormalizationMode.off;

  @override
  Future<void> setNormalizationMode(NormalizationMode mode) async {
    _settings.value = _settings.value.copyWith(normalizationMode: mode);
    await saveSettings();
  }

  @override
  double get currentLoudness => _currentLoudness.value;

  /// Update current loudness (called from audio analysis)
  void updateLoudness(double loudness) {
    _currentLoudness.value = loudness;
  }

  // ============ Sleep Timer ============

  @override
  bool get isSleepTimerActive => _isSleepTimerActive.value;

  @override
  Duration get sleepTimerRemaining => _sleepTimerRemaining.value;

  @override
  SleepTimerPreset? get activeSleepTimerPreset => _activeSleepTimerPreset.value;

  @override
  bool get sleepTimerFadeOut => _settings.value.sleepTimerFadeOut;

  @override
  Duration get sleepTimerFadeOutDuration => _settings.value.sleepTimerFadeOutDuration;

  @override
  Stream<Duration> get sleepTimerStream => _sleepTimerStreamController.stream;

  @override
  Future<void> setSleepTimer(SleepTimerPreset preset, {bool fadeOut = true}) async {
    if (preset == SleepTimerPreset.endOfTrack) {
      await setSleepTimerEndOfTrack(fadeOut: fadeOut);
      return;
    }

    if (preset == SleepTimerPreset.custom) {
      // For custom, use the stored custom duration
      return;
    }

    _activeSleepTimerPreset.value = preset;
    _startSleepTimer(preset.duration, fadeOut: fadeOut);
  }

  @override
  Future<void> setCustomSleepTimer(
    Duration duration, {
    bool fadeOut = true,
    Duration fadeOutDuration = const Duration(seconds: 30),
  }) async {
    _settings.value = _settings.value.copyWith(
      sleepTimerFadeOut: fadeOut,
      sleepTimerFadeOutDuration: fadeOutDuration,
    );
    await saveSettings();

    _activeSleepTimerPreset.value = SleepTimerPreset.custom;
    _startSleepTimer(duration, fadeOut: fadeOut);
  }

  @override
  Future<void> setSleepTimerEndOfTrack({bool fadeOut = true}) async {
    _activeSleepTimerPreset.value = SleepTimerPreset.endOfTrack;
    _isSleepTimerActive.value = true;
    _sleepTimerRemaining.value = Duration.zero;
    // Actual stopping will be handled by audio handler when track ends
  }

  void _startSleepTimer(Duration duration, {bool fadeOut = true}) {
    _cancelSleepTimer();

    _sleepTimerRemaining.value = duration;
    _isSleepTimerActive.value = true;

    // Update remaining time every second
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _sleepTimerRemaining.value - const Duration(seconds: 1);

      if (remaining <= Duration.zero) {
        _onSleepTimerComplete();
        return;
      }

      _sleepTimerRemaining.value = remaining;
      _sleepTimerStreamController.add(remaining);

      // Start fade out if enabled
      if (fadeOut && remaining <= sleepTimerFadeOutDuration) {
        _startFadeOut(remaining);
      }
    });
  }

  void _startFadeOut(Duration remaining) {
    // Calculate volume based on remaining time
    final progress = remaining.inMilliseconds / sleepTimerFadeOutDuration.inMilliseconds;
    final targetVolume = _originalVolume * progress;

    // Would call audio handler to set volume
    // audioHandler.setVolume(targetVolume);
  }

  void _onSleepTimerComplete() {
    _cancelSleepTimer();
    _isSleepTimerActive.value = false;
    _activeSleepTimerPreset.value = null;
    _sleepTimerRemaining.value = Duration.zero;

    // Would call audio handler to pause
    // audioHandler.pause();

    // Restore volume
    // audioHandler.setVolume(_originalVolume);
  }

  @override
  Future<void> cancelSleepTimer() async {
    _cancelSleepTimer();
    _isSleepTimerActive.value = false;
    _activeSleepTimerPreset.value = null;
    _sleepTimerRemaining.value = Duration.zero;
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _fadeOutTimer?.cancel();
    _fadeOutTimer = null;
  }

  @override
  Future<void> extendSleepTimer(Duration extension) async {
    if (!_isSleepTimerActive.value) return;

    _sleepTimerRemaining.value = _sleepTimerRemaining.value + extension;
    _sleepTimerStreamController.add(_sleepTimerRemaining.value);
  }

  // ============ Car Mode ============

  @override
  bool get isCarModeActive => _isCarModeActive.value;

  @override
  CarModeLayout get carModeLayout => _settings.value.carModeLayout;

  @override
  Future<void> enableCarMode({CarModeLayout layout = CarModeLayout.standard}) async {
    _isCarModeActive.value = true;
    _settings.value = _settings.value.copyWith(carModeLayout: layout);
    await saveSettings();
  }

  @override
  Future<void> disableCarMode() async {
    _isCarModeActive.value = false;
  }

  @override
  Future<void> setCarModeLayout(CarModeLayout layout) async {
    _settings.value = _settings.value.copyWith(carModeLayout: layout);
    await saveSettings();
  }

  @override
  bool get autoCarModeEnabled => _settings.value.autoCarMode;

  @override
  Future<void> setAutoCarMode(bool enabled) async {
    _settings.value = _settings.value.copyWith(autoCarMode: enabled);
    await saveSettings();
  }

  // ============ Playback Speed ============

  @override
  double get playbackSpeed => _settings.value.playbackSpeed;

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    final clampedSpeed = speed.clamp(0.5, 2.0);
    _settings.value = _settings.value.copyWith(playbackSpeed: clampedSpeed);
    await saveSettings();

    // Would call audio handler to set speed
    // audioHandler.setSpeed(clampedSpeed);
  }

  @override
  Future<void> resetPlaybackSpeed() async {
    await setPlaybackSpeed(1.0);
  }

  @override
  List<double> get speedPresets => [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  // ============ Skip Silence ============

  @override
  bool get skipSilenceEnabled => _settings.value.skipSilence;

  @override
  int get skipSilenceThresholdMs => _settings.value.skipSilenceThresholdMs;

  @override
  Future<void> enableSkipSilence({int thresholdMs = 500}) async {
    _settings.value = _settings.value.copyWith(
      skipSilence: true,
      skipSilenceThresholdMs: thresholdMs,
    );
    await saveSettings();
  }

  @override
  Future<void> disableSkipSilence() async {
    _settings.value = _settings.value.copyWith(skipSilence: false);
    await saveSettings();
  }

  // ============ Audio Focus ============

  @override
  AudioFocusMode get audioFocusMode => _settings.value.audioFocusMode;

  @override
  Future<void> setAudioFocusMode(AudioFocusMode mode) async {
    _settings.value = _settings.value.copyWith(audioFocusMode: mode);
    await saveSettings();
  }

  // ============ Persistence ============

  @override
  Future<void> saveSettings() async {
    await _box?.put(_settingsKey, _settings.value.toJson());
  }

  @override
  Future<void> loadSettings() async {
    final data = _box?.get(_settingsKey) as Map?;
    if (data != null) {
      _settings.value = EnhancedPlaybackSettings.fromJson(
        Map<String, dynamic>.from(data),
      );
    }
  }

  @override
  Future<void> resetToDefaults() async {
    _settings.value = const EnhancedPlaybackSettings();
    await saveSettings();
  }

  @override
  void onClose() {
    _cancelSleepTimer();
    _sleepTimerStreamController.close();
    super.onClose();
  }
}
