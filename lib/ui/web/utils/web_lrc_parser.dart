/// Public LRC parser used by [WebLyricsPanel].
///
/// Re-exports the shared [LrcEntry] model and [parseLrc] function so
/// existing imports from web widgets continue to work.
library;

export '../../../domain/models/lrc_entry.dart';
export '../../../utils/helpers/lrc_parser.dart';
