import 'dart:convert';
import 'dart:typed_data' show BytesBuilder;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:neom_core/app_config.dart';

import '../../domain/models/media_lyrics.dart';
import '../../ui/player/lyrics/matcher.dart';
import '../enums/lyrics_source.dart';
import '../enums/lyrics_type.dart';

/// Fetches time-synced (LRC) or plain-text lyrics from a Spotify lyrics proxy.
///
/// Uses a public Spotify lyrics API to search for the track and retrieve
/// LINE_SYNCED lyrics in LRC format when available, falling back to
/// plain UNSYNCED text.
class SpotifyLyricsHelper {

  static const String _apiHost = 'spotify-lyric-api-984e7b4face0.herokuapp.com';
  static const int _maxResponseBytes = 2 * 1024 * 1024;
  static const int _maxLines = 5000;
  static final RegExp _safeSpotifyTrackId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  static final RegExp _safeTimeTag = RegExp(
    r'^[0-9]{1,3}:[0-9]{2}(?:\.[0-9]{1,3})?$',
  );
  static final RegExp _controlOrBidi = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060\u2066-\u2069\uFEFF]',
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
  static final RegExp _htmlTags = RegExp(r'<[^>]*>');

  static String _sliceSafe(String s, int maxChars) {
    if (maxChars <= 0 || s.isEmpty) return '';
    if (s.length <= maxChars) return s;
    var end = maxChars;
    final cu = s.codeUnitAt(end - 1);
    if (cu >= 0xD800 && cu <= 0xDBFF) end -= 1;
    return end <= 0 ? '' : s.substring(0, end);
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

  static String _sanitizeLyricLine(Object? raw, {int maxChars = 1024}) {
    if (raw == null) return '';
    final cleaned = raw
        .toString()
        .replaceAll(_gemmaThoughtBlock, '')
        .replaceAll(_internalControlTags, '')
        .replaceAll(_contentCloseTag, '[content_end]')
        .replaceAll(_htmlTags, '')
        .replaceAll(_controlOrBidi, '')
        .trim();
    return _sliceSafe(cleaned, maxChars);
  }

  @visibleForTesting
  static Future<http.Response> Function(Uri uri, {Map<String, String>? headers})?
      debugHttpGet;

  static Future<http.Response> _boundedGet(
    Uri uri, {
    Map<String, String>? headers,
    required Duration timeout,
  }) async {
    final override = debugHttpGet;
    if (override != null) {
      return override(uri, headers: headers).timeout(timeout);
    }
    final client = http.Client();
    try {
      final req = http.Request('GET', uri)..followRedirects = false;
      if (headers != null) req.headers.addAll(headers);
      final streamed = await client.send(req).timeout(timeout);
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
      await for (final chunk in streamed.stream.timeout(timeout)) {
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

  /// Searches for the track on Spotify and retrieves its lyrics.
  ///
  /// Returns a [MediaLyrics] with [LyricsType.lrc] when synced lyrics
  /// are available, or [LyricsType.text] for unsynced. Returns empty
  /// lyrics when the track is not found or has no lyrics.
  static Future<MediaLyrics> fetchLyrics({
    required String title,
    required String artist,
  }) async {
    final mediaLyrics = MediaLyrics(source: LyricsSource.spotify);
    final cleanTitle = _sanitizeQueryInput(title);
    final cleanArtist = _sanitizeQueryInput(artist);
    if (cleanTitle.isEmpty && cleanArtist.isEmpty) return mediaLyrics;

    try {
      final trackId = await _searchTrackId(cleanTitle, cleanArtist);
      if (trackId == null || trackId.isEmpty) return mediaLyrics;

      final lyricsUrl = Uri.https(_apiHost, '/', {
        'trackid': trackId,
        'format': 'lrc',
      });

      final res = await _boundedGet(
        lyricsUrl,
        headers: const {'Accept': 'application/json'},
        timeout: const Duration(seconds: 10),
      );

      if (res.statusCode != 200 || res.bodyBytes.length > _maxResponseBytes) {
        return mediaLyrics;
      }

      final decoded = json.decode(res.body);
      if (decoded is! Map) return mediaLyrics;
      final data = Map<String, dynamic>.from(decoded);
      if (data['error'] == true) return mediaLyrics;

      final lines = (data['lines'] as List?)
              ?.whereType<Map>()
              .take(_maxLines)
              .toList() ??
          [];
      if (lines.isEmpty) return mediaLyrics;

      if (data['syncType'] == 'LINE_SYNCED') {
        mediaLyrics.lyrics = lines.map((e) {
          final rawTag = e['timeTag']?.toString().trim() ?? '';
          final tag = _safeTimeTag.hasMatch(rawTag) ? rawTag : '00:00.00';
          return '[$tag]${_sanitizeLyricLine(e['words'])}';
        }).join('\n');
        mediaLyrics.type = LyricsType.lrc;
      } else {
        mediaLyrics.lyrics = lines
            .map((e) => _sanitizeLyricLine(e['words']))
            .join('\n');
        mediaLyrics.type = LyricsType.text;
      }
    } catch (e) {
      AppConfig.logger.w('SpotifyLyricsHelper.fetchLyrics failed: $e');
    }

    return mediaLyrics;
  }

  /// Searches Spotify for a matching track and returns its track ID.
  static Future<String?> _searchTrackId(String title, String artist) async {
    try {
      final cleanTitle = _sanitizeQueryInput(title);
      final cleanArtist = _sanitizeQueryInput(artist);
      if (cleanTitle.isEmpty && cleanArtist.isEmpty) return null;
      // Try without auth first via public search proxy
      final proxyUrl = Uri.https(_apiHost, '/search', {
        'q': '$cleanTitle - $cleanArtist',
      });

      final res = await _boundedGet(
        proxyUrl,
        headers: const {'Accept': 'application/json'},
        timeout: const Duration(seconds: 8),
      );

      if (res.statusCode != 200 || res.bodyBytes.length > _maxResponseBytes) {
        return null;
      }

      final decoded = json.decode(res.body);
      if (decoded is! Map) return null;
      final tracks = decoded['tracks'];
      if (tracks is! Map) return null;
      final items = (tracks['items'] as List?)?.whereType<Map>().toList();
      if (items == null || items.isEmpty) return null;

      // Verify match quality
      for (final item in items) {
        final trackTitle = item['name']?.toString() ?? '';
        final artistsList = item['artists'];
        final firstArtist = (artistsList is List && artistsList.isNotEmpty && artistsList.first is Map)
            ? (artistsList.first as Map)['name']?.toString() ?? ''
            : '';

        if (matchSongs(
          title: cleanTitle,
          artist: cleanArtist,
          title2: trackTitle,
          artist2: firstArtist,
        )) {
          final candidateId = item['id']?.toString().trim() ?? '';
          if (_safeSpotifyTrackId.hasMatch(candidateId)) return candidateId;
        }
      }

      // Fallback: return first result if no match verified
      final fallbackId = items.first['id']?.toString().trim() ?? '';
      return _safeSpotifyTrackId.hasMatch(fallbackId) ? fallbackId : null;
    } catch (e) {
      AppConfig.logger.w('SpotifyLyricsHelper._searchTrackId failed: $e');
      return null;
    }
  }

}
