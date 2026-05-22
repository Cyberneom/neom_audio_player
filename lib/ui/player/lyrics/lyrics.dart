import 'package:sint/sint.dart';
import 'package:http/http.dart' as http;
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/neom_error_logger.dart';

import '../../../domain/models/media_lyrics.dart';
import '../../../domain/use_cases/whisper_lyrics_service.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/enums/lyrics_source.dart';
import '../../../utils/enums/lyrics_type.dart';
import '../../../utils/helpers/spotify_lyrics_helper.dart';



class Lyrics {

  /// Resolves lyrics for a given track using a multi-source fallback cascade:
  ///
  /// 0. Firestore `lyricsLrc` field (Whisper-generated, highest priority)
  /// 1. Spotify (synced LRC preferred)
  /// 2. Musixmatch (web scraping)
  /// 3. Google (web scraping fallback)
  /// 4. Whisper on-demand (AI transcription from audio URL)
  ///
  /// Returns an empty [MediaLyrics] when no source is available —
  /// callers fall back to the plain-text view.
  static Future<MediaLyrics> getLyrics({
    required String id,
    required String title,
    required String artist,
    String? lyricsLrc,
    String? audioUrl,
    String? existingLyrics,
    String? language,
  }) async {
    AppConfig.logger.i('Getting Synced Lyrics for "$title" by "$artist"');

    // 0. Pre-generated Whisper LRC from the release (highest priority).
    if (lyricsLrc != null && lyricsLrc.isNotEmpty) {
      return MediaLyrics(
        mediaId: id,
        lyrics: lyricsLrc,
        source: LyricsSource.whisper,
        type: LyricsType.lrc,
      );
    }

    // 1. Spotify synced lyrics
    MediaLyrics result = await SpotifyLyricsHelper.fetchLyrics(
      title: title,
      artist: artist,
    );
    if (result.lyrics.isNotEmpty) {
      result.mediaId = id;
      return result;
    }

    // 2. Musixmatch
    result = await getMusixMatchLyrics(title: title, artist: artist);
    if (result.lyrics.isNotEmpty) {
      result.mediaId = id;
      return result;
    }

    // 3. Google
    result = await getGoogleLyrics(title: title, artist: artist);
    if (result.lyrics.isNotEmpty) {
      result.mediaId = id;
      return result;
    }

    // 4. Whisper on-demand transcription (last resort, requires audio URL).
    //    WhisperLyricsService impl lives in neom_audio_platform — the
    //    player only depends on the interface. If no impl is registered,
    //    this step is silently skipped.
    if (audioUrl != null && audioUrl.isNotEmpty) {
      try {
        if (Sint.isRegistered<WhisperLyricsService>()) {
          final whisper = Sint.find<WhisperLyricsService>();
          result = await whisper.transcribeAndAlign(
            audioUrl: audioUrl,
            existingLyrics: existingLyrics,
            language: language,
            mediaId: id,
          );
          if (result.lyrics.isNotEmpty) return result;
        }
      } catch (e) {
        AppConfig.logger.w('Whisper on-demand lyrics failed: $e');
      }
    }

    return MediaLyrics(mediaId: id);
  }

  static Future<MediaLyrics> getGoogleLyrics({required String title, required String artist,}) async {

    MediaLyrics mediaLyrics = MediaLyrics(source: LyricsSource.google);

    const String url = 'https://www.google.com/search?client=safari&rls=en&ie=UTF-8&oe=UTF-8&q=';
    const String delimiter1 = '</div></div></div></div><div class="hwc"><div class="BNeawe tAd8D AP7Wnd"><div><div class="BNeawe tAd8D AP7Wnd">';
    const String delimiter2 = '</div></div></div></div></div><div><span class="hwc"><div class="BNeawe uEec3 AP7Wnd">';
    String lyrics = '';
    try {
      lyrics = (await http.get(Uri.parse(Uri.encodeFull('$url$title by $artist lyrics')),)).body;
      lyrics = lyrics.split(delimiter1).last;
      lyrics = lyrics.split(delimiter2).first;
      if (lyrics.contains('<meta charset="UTF-8">')) throw Error();
    } catch (_) {
      try {
        lyrics = (await http.get(
          Uri.parse(
            Uri.encodeFull('$url$title by $artist song lyrics'),
          ),
        )).body;
        lyrics = lyrics.split(delimiter1).last;
        lyrics = lyrics.split(delimiter2).first;
        if (lyrics.contains('<meta charset="UTF-8">')) throw Error();
      } catch (_) {
        try {
          lyrics = (await http.get(
            Uri.parse(
              Uri.encodeFull(
                '$url${title.split("-").first} by $artist lyrics',
              ),
            ),
          )).body;
          lyrics = lyrics.split(delimiter1).last;
          lyrics = lyrics.split(delimiter2).first;
          if (lyrics.contains('<meta charset="UTF-8">')) throw Error();
        } catch (_) {
          lyrics = '';
        }
      }
    }
    mediaLyrics.lyrics = lyrics;

    return mediaLyrics;
  }

  /// Returns embedded lyrics for an offline media [path].
  ///
  /// ROADMAP: read lyrics from on-disk metadata (ID3 USLT, Vorbis LYRICS,
  /// MP4 ©lyr) once `metadata_god` is wired into the offline cache.
  static Future<String> getOffLyrics(String path) async {
    try {
      return AudioPlayerTranslationConstants.noLyricsAvailable.tr;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'getOffLyrics');
      return '';
    }
  }

  static Future<MediaLyrics> getMusixMatchLyrics({required String title, required String artist,}) async {

    MediaLyrics mediaLyrics = MediaLyrics(source: LyricsSource.musicMatch);
    String lyrics = '';
    try {
      final String link = await getLyricsLink(title, artist);
      AppConfig.logger.i('Found Musixmatch Lyrics Link: $link');
      lyrics = await scrapLink(link);
      mediaLyrics.lyrics = lyrics;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'getMusixMatchLyrics');
    }

    return mediaLyrics;
  }

  static Future<String> getLyricsLink(String song, String artist) async {
    const String authority = 'www.musixmatch.com';
    final String unEncodedPath = '/search/$song $artist';
    final http.Response res = await http.get(Uri.https(authority, unEncodedPath));
    if (res.statusCode != 200) return '';
    final RegExpMatch? result =
    RegExp(r'href=\"(\/lyrics\/.*?)\"').firstMatch(res.body);
    return result == null ? '' : result[1]!;
  }

  static Future<String> scrapLink(String unencodedPath) async {
    AppConfig.logger.i('Trying to scrap lyrics from $unencodedPath');
    const String authority = 'www.musixmatch.com';
    final http.Response res = await http.get(Uri.https(authority, unencodedPath));
    if (res.statusCode != 200) return '';
    final List<String?> lyrics = RegExp(
      r'<span class=\"lyrics__content__ok\">(.*?)<\/span>',
      dotAll: true,
    ).allMatches(res.body).map((m) => m[1]).toList();

    return lyrics.isEmpty ? '' : lyrics.join('\n');
  }
}
