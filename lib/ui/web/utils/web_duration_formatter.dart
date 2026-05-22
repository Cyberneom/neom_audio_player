/// Formats a [Duration] into a compact "remaining queue" label used by the
/// web queue panel header. Examples:
///
///   45m  → "~45 min"
///   60m  → "~1h"
///   83m  → "~1h 23min"
///
/// Negative or zero durations return `~0 min` so the caller does not need
/// to special-case empty queues.
String formatRemainingDuration(Duration d) {
  final totalMinutes = d.inMinutes;
  if (totalMinutes <= 0) return '~0 min';
  if (totalMinutes < 60) return '~$totalMinutes min';
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return m == 0 ? '~${h}h' : '~${h}h ${m}min';
}
