/// A single timestamped line of LRC-formatted lyrics.
///
/// Produced by [LrcParser.parse] when at least one `[mm:ss.xx]` timestamp
/// is found. Used by both the mobile synced lyrics widget and the web
/// lyrics panel for karaoke-style highlight and auto-scroll behaviour.
class LrcEntry {

  /// Playback position at which this line should become active.
  final Duration timestamp;

  /// Lyric text (already trimmed; may be empty for stamp-only lines).
  final String text;

  const LrcEntry({required this.timestamp, required this.text});

  /// Timestamp in milliseconds — used as key in [SplayTreeMap] lookups.
  int get timestampMs => timestamp.inMilliseconds;

}
