import 'dart:convert';

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

    try {
      final trackId = await _searchTrackId(title, artist);
      if (trackId == null) return mediaLyrics;

      final lyricsUrl = Uri.https(_apiHost, '/', {
        'trackid': trackId,
        'format': 'lrc',
      });

      final res = await http.get(
        lyricsUrl,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return mediaLyrics;

      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['error'] == true) return mediaLyrics;

      final lines = data['lines'] as List<dynamic>? ?? [];
      if (lines.isEmpty) return mediaLyrics;

      if (data['syncType'] == 'LINE_SYNCED') {
        mediaLyrics.lyrics = lines
            .map((e) => '[${e["timeTag"]}]${e["words"]}')
            .join('\n');
        mediaLyrics.type = LyricsType.lrc;
      } else {
        mediaLyrics.lyrics = lines
            .map((e) => e['words'])
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
      final searchUrl = Uri.https('api.spotify.com', '/v1/search', {
        'q': '$title $artist',
        'type': 'track',
        'limit': '3',
      });

      // Try without auth first via public search proxy
      final proxyUrl = Uri.https(_apiHost, '/search', {
        'q': '$title - $artist',
      });

      final res = await http.get(
        proxyUrl,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return null;

      final data = json.decode(res.body) as Map<String, dynamic>;
      final items = data['tracks']?['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) return null;

      // Verify match quality
      for (final item in items) {
        final trackTitle = item['name']?.toString() ?? '';
        final trackArtist = (item['artists'] as List?)
            ?.firstOrNull?['name']?.toString() ?? '';

        if (matchSongs(
          title: title,
          artist: artist,
          title2: trackTitle,
          artist2: trackArtist,
        )) {
          return item['id']?.toString();
        }
      }

      // Fallback: return first result if no match verified
      return items.first['id']?.toString();
    } catch (e) {
      AppConfig.logger.w('SpotifyLyricsHelper._searchTrackId failed: $e');
      return null;
    }
  }

}
