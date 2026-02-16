import '../../utils/enums/playback_mode.dart';

/// Abstract service for enhanced playback features
/// (Crossfade, Gapless, Normalization, Sleep Timer)
abstract class EnhancedPlaybackService {
  // ============ Crossfade ============

  /// Current crossfade mode
  CrossfadeMode get crossfadeMode;

  /// Custom crossfade duration (if mode is custom)
  Duration get customCrossfadeDuration;

  /// Whether crossfade is enabled
  bool get isCrossfadeEnabled;

  /// Set crossfade mode
  Future<void> setCrossfadeMode(CrossfadeMode mode);

  /// Set custom crossfade duration
  Future<void> setCustomCrossfadeDuration(Duration duration);

  /// Get crossfade duration for current mode
  Duration get effectiveCrossfadeDuration;

  // ============ Gapless ============

  /// Current gapless mode
  GaplessMode get gaplessMode;

  /// Whether gapless playback is enabled
  bool get isGaplessEnabled;

  /// Set gapless mode
  Future<void> setGaplessMode(GaplessMode mode);

  // ============ Normalization ============

  /// Current normalization mode
  NormalizationMode get normalizationMode;

  /// Whether normalization is enabled
  bool get isNormalizationEnabled;

  /// Set normalization mode
  Future<void> setNormalizationMode(NormalizationMode mode);

  /// Get current loudness level (LUFS)
  double get currentLoudness;

  // ============ Sleep Timer ============

  /// Whether sleep timer is active
  bool get isSleepTimerActive;

  /// Remaining time on sleep timer
  Duration get sleepTimerRemaining;

  /// Sleep timer preset (if using preset)
  SleepTimerPreset? get activeSleepTimerPreset;

  /// Whether fade out is enabled for sleep timer
  bool get sleepTimerFadeOut;

  /// Duration of fade out
  Duration get sleepTimerFadeOutDuration;

  /// Stream of sleep timer updates (remaining time)
  Stream<Duration> get sleepTimerStream;

  /// Set sleep timer with preset
  Future<void> setSleepTimer(SleepTimerPreset preset, {bool fadeOut = true});

  /// Set sleep timer with custom duration
  Future<void> setCustomSleepTimer(
    Duration duration, {
    bool fadeOut = true,
    Duration fadeOutDuration = const Duration(seconds: 30),
  });

  /// Set sleep timer to end of current track
  Future<void> setSleepTimerEndOfTrack({bool fadeOut = true});

  /// Cancel sleep timer
  Future<void> cancelSleepTimer();

  /// Extend sleep timer
  Future<void> extendSleepTimer(Duration extension);

  // ============ Car Mode ============

  /// Whether car mode is active
  bool get isCarModeActive;

  /// Current car mode layout
  CarModeLayout get carModeLayout;

  /// Enable car mode
  Future<void> enableCarMode({CarModeLayout layout = CarModeLayout.standard});

  /// Disable car mode
  Future<void> disableCarMode();

  /// Set car mode layout
  Future<void> setCarModeLayout(CarModeLayout layout);

  /// Whether to auto-enable car mode when connected to car Bluetooth
  bool get autoCarModeEnabled;

  /// Set auto car mode
  Future<void> setAutoCarMode(bool enabled);

  // ============ Playback Speed ============

  /// Current playback speed (1.0 = normal)
  double get playbackSpeed;

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed);

  /// Reset playback speed to normal
  Future<void> resetPlaybackSpeed();

  /// Available speed presets
  List<double> get speedPresets;

  // ============ Skip Silence ============

  /// Whether skip silence is enabled
  bool get skipSilenceEnabled;

  /// Minimum silence duration to skip (ms)
  int get skipSilenceThresholdMs;

  /// Enable skip silence
  Future<void> enableSkipSilence({int thresholdMs = 500});

  /// Disable skip silence
  Future<void> disableSkipSilence();

  // ============ Audio Focus ============

  /// How to handle audio focus (duck, pause, etc.)
  AudioFocusMode get audioFocusMode;

  /// Set audio focus handling mode
  Future<void> setAudioFocusMode(AudioFocusMode mode);

  // ============ Persistence ============

  /// Save all settings
  Future<void> saveSettings();

  /// Load saved settings
  Future<void> loadSettings();

  /// Reset all settings to defaults
  Future<void> resetToDefaults();
}

/// How to handle audio focus interruptions
enum AudioFocusMode {
  /// Pause playback when focus lost
  pause('pause', 'Pause'),

  /// Duck (lower volume) when focus lost temporarily
  duck('duck', 'Lower volume'),

  /// Ignore focus changes
  ignore('ignore', 'Ignore');

  final String value;
  final String displayName;

  const AudioFocusMode(this.value, this.displayName);
}

/// Enhanced playback settings model
class EnhancedPlaybackSettings {
  final CrossfadeMode crossfadeMode;
  final Duration customCrossfadeDuration;
  final GaplessMode gaplessMode;
  final NormalizationMode normalizationMode;
  final bool sleepTimerFadeOut;
  final Duration sleepTimerFadeOutDuration;
  final CarModeLayout carModeLayout;
  final bool autoCarMode;
  final double playbackSpeed;
  final bool skipSilence;
  final int skipSilenceThresholdMs;
  final AudioFocusMode audioFocusMode;

  const EnhancedPlaybackSettings({
    this.crossfadeMode = CrossfadeMode.off,
    this.customCrossfadeDuration = const Duration(seconds: 5),
    this.gaplessMode = GaplessMode.off,
    this.normalizationMode = NormalizationMode.off,
    this.sleepTimerFadeOut = true,
    this.sleepTimerFadeOutDuration = const Duration(seconds: 30),
    this.carModeLayout = CarModeLayout.standard,
    this.autoCarMode = false,
    this.playbackSpeed = 1.0,
    this.skipSilence = false,
    this.skipSilenceThresholdMs = 500,
    this.audioFocusMode = AudioFocusMode.duck,
  });

  EnhancedPlaybackSettings copyWith({
    CrossfadeMode? crossfadeMode,
    Duration? customCrossfadeDuration,
    GaplessMode? gaplessMode,
    NormalizationMode? normalizationMode,
    bool? sleepTimerFadeOut,
    Duration? sleepTimerFadeOutDuration,
    CarModeLayout? carModeLayout,
    bool? autoCarMode,
    double? playbackSpeed,
    bool? skipSilence,
    int? skipSilenceThresholdMs,
    AudioFocusMode? audioFocusMode,
  }) {
    return EnhancedPlaybackSettings(
      crossfadeMode: crossfadeMode ?? this.crossfadeMode,
      customCrossfadeDuration: customCrossfadeDuration ?? this.customCrossfadeDuration,
      gaplessMode: gaplessMode ?? this.gaplessMode,
      normalizationMode: normalizationMode ?? this.normalizationMode,
      sleepTimerFadeOut: sleepTimerFadeOut ?? this.sleepTimerFadeOut,
      sleepTimerFadeOutDuration: sleepTimerFadeOutDuration ?? this.sleepTimerFadeOutDuration,
      carModeLayout: carModeLayout ?? this.carModeLayout,
      autoCarMode: autoCarMode ?? this.autoCarMode,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      skipSilence: skipSilence ?? this.skipSilence,
      skipSilenceThresholdMs: skipSilenceThresholdMs ?? this.skipSilenceThresholdMs,
      audioFocusMode: audioFocusMode ?? this.audioFocusMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crossfadeMode': crossfadeMode.value,
      'customCrossfadeDuration': customCrossfadeDuration.inMilliseconds,
      'gaplessMode': gaplessMode.value,
      'normalizationMode': normalizationMode.value,
      'sleepTimerFadeOut': sleepTimerFadeOut,
      'sleepTimerFadeOutDuration': sleepTimerFadeOutDuration.inMilliseconds,
      'carModeLayout': carModeLayout.value,
      'autoCarMode': autoCarMode,
      'playbackSpeed': playbackSpeed,
      'skipSilence': skipSilence,
      'skipSilenceThresholdMs': skipSilenceThresholdMs,
      'audioFocusMode': audioFocusMode.value,
    };
  }

  factory EnhancedPlaybackSettings.fromJson(Map<String, dynamic> json) {
    return EnhancedPlaybackSettings(
      crossfadeMode: CrossfadeMode.values.firstWhere(
        (e) => e.value == json['crossfadeMode'],
        orElse: () => CrossfadeMode.off,
      ),
      customCrossfadeDuration: Duration(
        milliseconds: json['customCrossfadeDuration'] as int? ?? 5000,
      ),
      gaplessMode: GaplessMode.values.firstWhere(
        (e) => e.value == json['gaplessMode'],
        orElse: () => GaplessMode.off,
      ),
      normalizationMode: NormalizationMode.values.firstWhere(
        (e) => e.value == json['normalizationMode'],
        orElse: () => NormalizationMode.off,
      ),
      sleepTimerFadeOut: json['sleepTimerFadeOut'] as bool? ?? true,
      sleepTimerFadeOutDuration: Duration(
        milliseconds: json['sleepTimerFadeOutDuration'] as int? ?? 30000,
      ),
      carModeLayout: CarModeLayout.values.firstWhere(
        (e) => e.value == json['carModeLayout'],
        orElse: () => CarModeLayout.standard,
      ),
      autoCarMode: json['autoCarMode'] as bool? ?? false,
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      skipSilence: json['skipSilence'] as bool? ?? false,
      skipSilenceThresholdMs: json['skipSilenceThresholdMs'] as int? ?? 500,
      audioFocusMode: AudioFocusMode.values.firstWhere(
        (e) => e.value == json['audioFocusMode'],
        orElse: () => AudioFocusMode.duck,
      ),
    );
  }
}
