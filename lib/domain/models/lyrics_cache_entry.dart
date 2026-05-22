import '../../utils/enums/lyrics_source.dart';
import '../../utils/enums/lyrics_type.dart';

/// Hive-persistable lyrics cache record.
///
/// Stored keyed by media item ID so repeated plays do not re-fetch.
/// The [cachedAt] timestamp lets [LyricsController] expire stale entries.
class LyricsCacheEntry {

  String mediaId;
  String lyrics;
  LyricsSource source;
  LyricsType type;
  DateTime cachedAt;

  LyricsCacheEntry({
    this.mediaId = '',
    this.lyrics = '',
    this.source = LyricsSource.internal,
    this.type = LyricsType.text,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  Map<String, dynamic> toJSON() {
    return {
      'mediaId': mediaId,
      'lyrics': lyrics,
      'source': source.name,
      'type': type.name,
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  LyricsCacheEntry.fromJSON(Map<String, dynamic> data)
    : mediaId = data['mediaId'] as String? ?? '',
      lyrics = data['lyrics'] as String? ?? '',
      source = LyricsSource.values.firstWhere(
        (e) => e.name == data['source'],
        orElse: () => LyricsSource.internal,
      ),
      type = LyricsType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => LyricsType.text,
      ),
      cachedAt = DateTime.tryParse(data['cachedAt'] as String? ?? '')
          ?? DateTime.now();

  bool get isExpired {
    return DateTime.now().difference(cachedAt).inHours > 72;
  }

}
