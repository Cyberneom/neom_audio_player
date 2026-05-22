import '../../domain/models/lrc_entry.dart';

final RegExp _lrcLine =
    RegExp(r'^\s*((?:\[\d{1,2}:\d{1,2}(?:[.:]\d{1,3})?\]\s*)+)(.*)$');
final RegExp _lrcStamp =
    RegExp(r'\[(\d{1,2}):(\d{1,2})(?:[.:](\d{1,3}))?\]');

/// Parses LRC-formatted lyrics into a sorted list of [LrcEntry].
///
/// Each line may carry one or more timestamps; every stamp produces a
/// separate [LrcEntry] sharing the same text. Results are sorted in
/// ascending chronological order.
///
/// Returns an empty list when [raw] contains no LRC-style timestamps —
/// callers fall back to a plain-text view in that case.
List<LrcEntry> parseLrc(String raw) {
  if (raw.isEmpty) return const [];
  final result = <LrcEntry>[];
  for (final line in raw.split('\n')) {
    final match = _lrcLine.firstMatch(line);
    if (match == null) continue;
    final stampsBlock = match.group(1) ?? '';
    final text = (match.group(2) ?? '').trim();
    for (final stamp in _lrcStamp.allMatches(stampsBlock)) {
      final minutes = int.tryParse(stamp.group(1) ?? '') ?? 0;
      final seconds = int.tryParse(stamp.group(2) ?? '') ?? 0;
      final fracStr = stamp.group(3) ?? '0';
      final frac = int.tryParse(fracStr) ?? 0;
      final ms = fracStr.length == 2 ? frac * 10 : frac;
      result.add(LrcEntry(
        timestamp: Duration(minutes: minutes, seconds: seconds, milliseconds: ms),
        text: text,
      ));
    }
  }
  result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return result;
}
