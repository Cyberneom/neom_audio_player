import 'dart:typed_data' show BytesBuilder;

import 'package:flutter/foundation.dart' show visibleForTesting;
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
  static const Duration _httpTimeout = Duration(seconds: 10);
  static const int _maxResponseBytes = 2 * 1024 * 1024;
  static const int _maxLyricsOutputChars = 256 * 1024;
  static final RegExp _controlOrBidi = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060\u2066-\u2069\uFEFF]',
  );
  static final RegExp _unsafeInlineControls = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060\u2066-\u2069\uFEFF]',
  );
  static final RegExp _forbiddenScrapePathChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060\u2066-\u2069\uFEFF\u3002\uFF0E\uFF61]',
  );
  static final RegExp _gemmaThoughtBlock = RegExp(
    r'<(?:(?:\|channel>|\|turn>)thought[\s\S]*?(?:<(?:channel|turn)\|>|$)|think>[\s\S]*?</think>)',
    caseSensitive: false,
  );
  static final RegExp _internalControlTags = RegExp(
    r'<\|/?(?:turn|channel)\|?>?|<\|eot\|>|\[MEMORY_RECALL\]|<memory_recall>[\s\S]*?</memory_recall>|<auto_memory>[\s\S]*?</auto_memory>|<system_context>[\s\S]*?</system_context>|\[BIOCHIP:[^\]]*\]',
    caseSensitive: false,
  );
  static final RegExp _contentCloseTag = RegExp(
    r'</\s*content\s*>',
    caseSensitive: false,
  );
  static final RegExp _scriptOrStyleBlock = RegExp(
    r'<(?:script|style)\b[^>]*>[\s\S]*?</(?:script|style)>',
    caseSensitive: false,
  );
  static final RegExp _brTag = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final RegExp _htmlTags = RegExp(r'<[^>]*>');

  static String _sliceSafe(String s, int maxChars) {
    if (maxChars <= 0 || s.isEmpty) return '';
    if (s.length <= maxChars) return s;
    var end = maxChars;
    final cu = s.codeUnitAt(end - 1);
    if (cu >= 0xD800 && cu <= 0xDBFF) end -= 1;
    return end <= 0 ? '' : s.substring(0, end);
  }

  static String sanitizeLyricsOutput(
    String raw, {
    int maxChars = _maxLyricsOutputChars,
  }) {
    if (raw.isEmpty || maxChars <= 0) return '';
    final cleaned = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_gemmaThoughtBlock, '')
        .replaceAll(_internalControlTags, '')
        .replaceAll(_contentCloseTag, '[content_end]')
        .replaceAll(_scriptOrStyleBlock, '')
        .replaceAll(_brTag, '\n')
        .replaceAll(_htmlTags, '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(_unsafeInlineControls, '')
        .trim();
    return _sliceSafe(cleaned, maxChars);
  }

  static String _sanitizeQueryInput(String raw, {int maxChars = 200}) {
    final cleaned = raw
        .replaceAll(_gemmaThoughtBlock, '')
        .replaceAll(_internalControlTags, '')
        .replaceAll(_contentCloseTag, '')
        .replaceAll(_controlOrBidi, '')
        .trim();
    return _sliceSafe(cleaned, maxChars);
  }

  @visibleForTesting
  static Future<http.Response> Function(Uri uri)? debugHttpGet;

  static Future<http.Response> _safeGet(Uri uri) async {
    final override = debugHttpGet;
    if (override != null) {
      return override(uri).timeout(_httpTimeout);
    }
    final client = http.Client();
    try {
      final req = http.Request('GET', uri)..followRedirects = false;
      final streamed = await client.send(req).timeout(_httpTimeout);
      final declaredLen = streamed.contentLength;
      if (declaredLen != null &&
          (declaredLen < 0 || declaredLen > _maxResponseBytes)) {
        await streamed.stream.drain<void>().catchError((_) {});
        return http.Response.bytes(
          const <int>[],
          413,
          headers: streamed.headers,
        );
      }
      final builder = BytesBuilder(copy: false);
      var total = 0;
      await for (final chunk in streamed.stream.timeout(_httpTimeout)) {
        total += chunk.length;
        if (total > _maxResponseBytes) {
          return http.Response.bytes(
            const <int>[],
            413,
            headers: streamed.headers,
          );
        }
        builder.add(chunk);
      }
      return http.Response.bytes(
        builder.takeBytes(),
        streamed.statusCode,
        headers: streamed.headers,
      );
    } finally {
      client.close();
    }
  }

  static String? _extractGoogleSnippet(
    String body,
    String delimiter1,
    String delimiter2,
  ) {
    if (!body.contains(delimiter1)) return null;
    final afterStart = body.split(delimiter1).last;
    if (!afterStart.contains(delimiter2)) return null;
    final candidate = afterStart.split(delimiter2).first.trim();
    if (candidate.isEmpty) return null;
    final lower = candidate.toLowerCase();
    if (lower.contains('<meta ') ||
        lower.contains('<!doctype') ||
        lower.contains('<html')) {
      return null;
    }
    final sanitized = sanitizeLyricsOutput(candidate);
    return sanitized.isEmpty ? null : sanitized;
  }

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
    final cleanTitle = _sanitizeQueryInput(title);
    final cleanArtist = _sanitizeQueryInput(artist);
    AppConfig.logger.i('Getting Synced Lyrics for "$cleanTitle" by "$cleanArtist"');

    // 0. Pre-generated Whisper LRC from the release (highest priority).
    if (lyricsLrc != null && lyricsLrc.isNotEmpty) {
      final safeLrc = sanitizeLyricsOutput(lyricsLrc);
      if (safeLrc.isNotEmpty) {
        return MediaLyrics(
          mediaId: id,
          lyrics: safeLrc,
          source: LyricsSource.whisper,
          type: LyricsType.lrc,
        );
      }
    }

    // 1. Spotify synced lyrics
    MediaLyrics result = await SpotifyLyricsHelper.fetchLyrics(
      title: cleanTitle,
      artist: cleanArtist,
    );
    if (result.lyrics.isNotEmpty) {
      result.mediaId = id;
      return result;
    }

    // 2. Musixmatch
    result = await getMusixMatchLyrics(title: cleanTitle, artist: cleanArtist);
    if (result.lyrics.isNotEmpty) {
      result.mediaId = id;
      return result;
    }

    // 3. Google
    result = await getGoogleLyrics(title: cleanTitle, artist: cleanArtist);
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
    final MediaLyrics mediaLyrics = MediaLyrics(source: LyricsSource.google);
    final trimmedTitle = _sanitizeQueryInput(title);
    final trimmedArtist = _sanitizeQueryInput(artist);
    if (trimmedTitle.isEmpty && trimmedArtist.isEmpty) return mediaLyrics;

    const String delimiter1 = '</div></div></div></div><div class="hwc"><div class="BNeawe tAd8D AP7Wnd"><div><div class="BNeawe tAd8D AP7Wnd">';
    const String delimiter2 = '</div></div></div></div></div><div><span class="hwc"><div class="BNeawe uEec3 AP7Wnd">';

    final queries = <String>[
      '$trimmedTitle by $trimmedArtist lyrics',
      '$trimmedTitle by $trimmedArtist song lyrics',
      '${trimmedTitle.split('-').first.trim()} by $trimmedArtist lyrics',
    ];

    for (final query in queries) {
      try {
        final uri = Uri.https('www.google.com', '/search', <String, String>{
          'client': 'safari',
          'rls': 'en',
          'ie': 'UTF-8',
          'oe': 'UTF-8',
          'q': query,
        });
        final res = await _safeGet(uri);
        if (res.statusCode != 200 || res.bodyBytes.length > _maxResponseBytes) {
          continue;
        }
        final extracted = _extractGoogleSnippet(res.body, delimiter1, delimiter2);
        if (extracted != null) {
          mediaLyrics.lyrics = extracted;
          return mediaLyrics;
        }
      } catch (_) {
        // Continue to next query variant.
      }
    }

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
    final MediaLyrics mediaLyrics = MediaLyrics(source: LyricsSource.musicMatch);
    final cleanTitle = _sanitizeQueryInput(title);
    final cleanArtist = _sanitizeQueryInput(artist);
    if (cleanTitle.isEmpty && cleanArtist.isEmpty) return mediaLyrics;
    try {
      final String link = await getLyricsLink(cleanTitle, cleanArtist);
      if (link.isEmpty) return mediaLyrics;
      AppConfig.logger.i('Found Musixmatch Lyrics Link: $link');
      mediaLyrics.lyrics = await scrapLink(link);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'getMusixMatchLyrics');
    }

    return mediaLyrics;
  }

  static Future<String> getLyricsLink(String song, String artist) async {
    final cleanSong = _sanitizeQueryInput(song);
    final cleanArtist = _sanitizeQueryInput(artist);
    if (cleanSong.isEmpty && cleanArtist.isEmpty) return '';
    const String authority = 'www.musixmatch.com';
    final String unEncodedPath = '/search/$cleanSong $cleanArtist';
    final http.Response res = await _safeGet(Uri.https(authority, unEncodedPath));
    if (res.statusCode != 200 || res.bodyBytes.length > _maxResponseBytes) return '';
    final RegExpMatch? result =
        RegExp(r'href=\"(\/lyrics\/[^\"?#\s]+)\"').firstMatch(res.body);
    return result == null ? '' : result[1]!;
  }

  static Future<String> scrapLink(String unencodedPath) async {
    final trimmedPath = unencodedPath.trim();
    if (trimmedPath.length > 512 ||
        !trimmedPath.startsWith('/lyrics/') ||
        trimmedPath.startsWith('//') ||
        trimmedPath.contains('..') ||
        trimmedPath.contains(r'\') ||
        trimmedPath.contains(';') ||
        _forbiddenScrapePathChars.hasMatch(trimmedPath)) {
      return '';
    }
    try {
      final decoded = Uri.decodeComponent(trimmedPath);
      if (decoded.length > 512 ||
          !decoded.startsWith('/lyrics/') ||
          decoded.startsWith('//') ||
          decoded.contains('..') ||
          decoded.contains(r'\') ||
          decoded.contains(';') ||
          _forbiddenScrapePathChars.hasMatch(decoded)) {
        return '';
      }
    } catch (_) {
      return '';
    }
    AppConfig.logger.i('Trying to scrap lyrics from $trimmedPath');
    const String authority = 'www.musixmatch.com';
    final http.Response res = await _safeGet(Uri.https(authority, trimmedPath));
    if (res.statusCode != 200 || res.bodyBytes.length > _maxResponseBytes) return '';
    final List<String?> lyrics = RegExp(
      r'<span class=\"lyrics__content__ok\">(.*?)<\/span>',
      dotAll: true,
    ).allMatches(res.body).map((m) => m[1]).toList();

    if (lyrics.isEmpty) return '';
    return sanitizeLyricsOutput(lyrics.whereType<String>().join('\n'));
  }
}
