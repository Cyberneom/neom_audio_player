import '../models/media_lyrics.dart';

/// Interface for AI-powered lyrics transcription and forced alignment.
///
/// Two scenarios:
/// 1. **With lyrics** — the artist provided plain-text lyrics at upload.
///    Whisper aligns the text to the audio → produces LRC with precise
///    timestamps (forced alignment via the `prompt` parameter).
/// 2. **Without lyrics** — no text available. Whisper transcribes from
///    scratch → produces LRC (more error-prone but still valuable).
///
/// Returns a [MediaLyrics] with `type: LyricsType.lrc` and
/// `source: LyricsSource.whisper`.
abstract class WhisperLyricsService {
  /// Transcribe audio and optionally align with existing lyrics.
  ///
  /// * [audioUrl] — URL to the audio file (Firebase Storage, CDN, etc.)
  /// * [existingLyrics] — plain-text lyrics from the release. When
  ///   provided, Whisper uses them as a prompt for forced alignment,
  ///   producing much more accurate timestamps.
  /// * [language] — ISO 639-1 language code (e.g. 'es', 'en'). If null,
  ///   Whisper auto-detects.
  /// * [mediaId] — track identifier for caching.
  Future<MediaLyrics> transcribeAndAlign({
    required String audioUrl,
    String? existingLyrics,
    String? language,
    String? mediaId,
  });
}
