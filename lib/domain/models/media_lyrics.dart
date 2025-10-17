import '../../utils/enums/lyrics_source.dart';
import '../../utils/enums/lyrics_type.dart';

class MediaLyrics {

  String mediaId;
  String lyrics;
  LyricsSource source;
  LyricsType type;

  MediaLyrics({
    this.mediaId = '',
    this.lyrics = '',
    this.source = LyricsSource.internal,
    this.type = LyricsType.text,
  });

}
