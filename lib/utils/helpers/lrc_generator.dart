/// Converts timestamped text data to LRC format strings.
///
/// Works with generic input (seconds + text) so it has zero dependency
/// on Whisper-specific types. The caller (e.g. [WhisperLyricsController])
/// maps provider-specific responses to these simple inputs.
///
/// Output is compatible with [parseLrc] and the `WebLyricsPanel` karaoke UI.
class LrcGenerator {
  LrcGenerator._();

  /// Default gap (seconds) between words that triggers a new LRC line.
  static const double lineGapThreshold = 0.5;

  /// Generate LRC from segment-level data.
  ///
  /// Each entry in [segments] is a `{start: double, text: String}` map.
  static String generateFromSegments(
    List<Map<String, dynamic>> segments,
  ) {
    if (segments.isEmpty) return '';
    final buffer = StringBuffer();
    for (final seg in segments) {
      final start = (seg['start'] as num?)?.toDouble() ?? 0.0;
      final text = (seg['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) continue;
      buffer.writeln('${_formatTimestamp(start)}$text');
    }
    return buffer.toString().trimRight();
  }

  /// Generate LRC from word-level data.
  ///
  /// Each entry in [words] is a `{word: String, start: double, end: double}` map.
  /// Groups words into lines based on natural pauses (gaps > [lineGapThreshold]).
  static String generateFromWords(
    List<Map<String, dynamic>> words,
  ) {
    if (words.isEmpty) return '';

    final buffer = StringBuffer();
    final lineWords = <String>[];
    double? lineStart;
    double lastEnd = 0;

    for (var i = 0; i < words.length; i++) {
      final word = (words[i]['word'] as String?) ?? '';
      final start = (words[i]['start'] as num?)?.toDouble() ?? 0.0;
      final end = (words[i]['end'] as num?)?.toDouble() ?? start;

      if (lineWords.isEmpty) {
        lineStart = start;
      }

      lineWords.add(word);
      lastEnd = end;

      final isLast = i == words.length - 1;
      final nextStart = isLast
          ? 0.0
          : (words[i + 1]['start'] as num?)?.toDouble() ?? 0.0;
      final hasGap = !isLast && (nextStart - lastEnd) > lineGapThreshold;

      if (isLast || hasGap) {
        final text = lineWords.join(' ').trim();
        if (text.isNotEmpty && lineStart != null) {
          buffer.writeln('${_formatTimestamp(lineStart)}$text');
        }
        lineWords.clear();
        lineStart = null;
      }
    }

    return buffer.toString().trimRight();
  }

  /// Format seconds to LRC timestamp `[mm:ss.xx]`.
  static String _formatTimestamp(double seconds) {
    if (seconds < 0) seconds = 0;
    final totalMs = (seconds * 1000).round();
    final mm = (totalMs ~/ 60000).toString().padLeft(2, '0');
    final ss = ((totalMs % 60000) ~/ 1000).toString().padLeft(2, '0');
    final xx = ((totalMs % 1000) ~/ 10).toString().padLeft(2, '0');
    return '[$mm:$ss.$xx]';
  }
}
