import '../../domain/models/lrc_entry.dart';

const int maxLrcInputChars = 512 * 1024;
const int maxLrcLineChars = 2048;
const int maxLrcEntries = 5000;

final RegExp _lrcLine =
    RegExp(r'^\s*((?:\[\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?\]\s*)+)(.*)$');
final RegExp _lrcStamp =
    RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
final RegExp _unsafeLrcTextChars = RegExp(
  r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u0085\u061C\u200B\u200C\u200E\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
);
final RegExp _lrcPairedPromptBlocks = RegExp(
  r'<\s*(memory_recall|auto_memory|system_context)\b[^>]*>[\s\S]*?<\s*/\s*\1\s*>|\[\s*(BIOCHIP|MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT)\b[^\]]*\](?:(?!\[\s*/?\s*\2\b)[\s\S])*?\[\s*/\s*\2\b[^\]]*\]',
  caseSensitive: false,
);
final RegExp _lrcLlmArtifacts = RegExp(
  r'<\|(?:channel|turn)\s*>\s*thought\b[\s\S]*?(?:<(?:channel|turn)\s*\|>|$)|<\|tool_call>[\s\S]*?(?:<tool_call\|>|$)|<think\b[^>]*>[\s\S]*?(?:</think\s*>|$)|<\|/?(?:turn|channel|tool_call|eot)\|?>?|<(?:turn|channel|tool_call)\s*\|>|<\s*/?\s*(?:think|thought|memory_recall|auto_memory|system_context)\b[^>]*>|\[\s*/?\s*(?:MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT|BIOCHIP)\b[^\]]*\]',
  caseSensitive: false,
);
final RegExp _lrcClosingContentTag = RegExp(
  r'</\s*content\s*>',
  caseSensitive: false,
);

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
  final bounded = raw.length <= maxLrcInputChars
      ? raw
      : raw.substring(0, maxLrcInputChars);
  final result = <LrcEntry>[];
  for (final rawLine in bounded.split('\n')) {
    if (result.length >= maxLrcEntries) break;
    var line = rawLine.endsWith('\r')
        ? rawLine.substring(0, rawLine.length - 1)
        : rawLine;
    if (line.length > maxLrcLineChars) {
      line = line.substring(0, maxLrcLineChars);
    }
    if (!line.contains('[')) continue;
    final match = _lrcLine.firstMatch(line);
    if (match == null) continue;
    final stampsBlock = match.group(1) ?? '';
    final text = (match.group(2) ?? '')
        .replaceAll(_lrcPairedPromptBlocks, ' ')
        .replaceAll(_lrcLlmArtifacts, ' ')
        .replaceAll(_lrcClosingContentTag, '[content_end]')
        .replaceAll(_unsafeLrcTextChars, '')
        .trim();
    for (final stamp in _lrcStamp.allMatches(stampsBlock)) {
      if (result.length >= maxLrcEntries) break;
      final minutes = int.tryParse(stamp.group(1) ?? '') ?? 0;
      final seconds = int.tryParse(stamp.group(2) ?? '') ?? 0;
      final fracStr = stamp.group(3);
      int ms = 0;
      if (fracStr != null && fracStr.isNotEmpty) {
        final frac = int.tryParse(fracStr) ?? 0;
        ms = switch (fracStr.length) {
          1 => frac * 100,
          2 => frac * 10,
          _ => frac,
        };
      }
      result.add(LrcEntry(
        timestamp: Duration(minutes: minutes, seconds: seconds, milliseconds: ms),
        text: text,
      ));
    }
  }
  result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return result;
}
