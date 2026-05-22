import 'package:audio_service/audio_service.dart';

/// Pure helpers backing the web bottom player UI.
///
/// Extracted as top-level functions so the seek-bar maths, duration formatting,
/// repeat-mode cycling and volume clamping can be unit-tested without booting
/// the audio handler.

/// Returns a slider value in [0.0, 1.0] for the given playback [position] and
/// total [duration]. Handles all the edge cases the raw division would
/// otherwise blow up on:
///
/// * `duration <= 0`            → 0.0  (track not loaded yet)
/// * `position < 0`             → 0.0
/// * `position >= duration`     → 1.0  (end-of-track / overshoot)
double computeSliderValue(Duration position, Duration duration) {
  final totalMs = duration.inMilliseconds;
  if (totalMs <= 0) return 0.0;
  final posMs = position.inMilliseconds;
  if (posMs <= 0) return 0.0;
  if (posMs >= totalMs) return 1.0;
  return posMs / totalMs;
}

/// Compact `M:SS` / `H:MM:SS` formatter for the seek-bar timestamps.
///
/// Negative durations clamp to `0:00`. Anything ≥ 1h gets a leading hour
/// segment so the time display does not overflow.
String formatPlayerDuration(Duration d) {
  if (d.isNegative) return '0:00';
  final totalSeconds = d.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    final mm = minutes.toString().padLeft(2, '0');
    return '$hours:$mm:$ss';
  }
  return '$minutes:$ss';
}

/// Returns the next [AudioServiceRepeatMode] in the standard cycle:
/// `none → all → one → none`.
AudioServiceRepeatMode cycleRepeatMode(AudioServiceRepeatMode current) {
  switch (current) {
    case AudioServiceRepeatMode.none:
      return AudioServiceRepeatMode.all;
    case AudioServiceRepeatMode.all:
      return AudioServiceRepeatMode.one;
    case AudioServiceRepeatMode.one:
    case AudioServiceRepeatMode.group:
      return AudioServiceRepeatMode.none;
  }
}

/// Clamps a raw volume value to the legal range `[0.0, 1.0]`. NaN inputs
/// fall back to the [fallback] (default `1.0`) so the UI never enters an
/// undefined slider state.
double clampVolume(double raw, {double fallback = 1.0}) {
  if (raw.isNaN) return fallback;
  if (raw <= 0.0) return 0.0;
  if (raw >= 1.0) return 1.0;
  return raw;
}

/// Inverse of [computeSliderValue]: maps a slider value back to a
/// [Duration] within `[Duration.zero, duration]`. Used by the seek-bar's
/// drag-end handler to compute the target position before calling
/// `audioHandler.seek(...)`.
Duration sliderValueToPosition(double value, Duration duration) {
  final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
  final ms = (clamped * duration.inMilliseconds).round();
  if (ms <= 0) return Duration.zero;
  if (ms >= duration.inMilliseconds) return duration;
  return Duration(milliseconds: ms);
}
