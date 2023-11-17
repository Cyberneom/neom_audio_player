import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';

import '../../../domain/entities/media_lyrics.dart';
import '../../../utils/enums/lyrics_source.dart';
import '../../../utils/enums/lyrics_type.dart';


// ignore: avoid_classes_with_only_static_members
class Lyrics {

  static Future<MediaLyrics> getLyrics({required String id, required String title, required String artist}) async {
    MediaLyrics mediaLyrics = MediaLyrics(mediaId: id);
    AppUtilities.logger.i('Getting Synced Lyrics');
    mediaLyrics = await getSpotifyLyricsFromId(id);
    if (mediaLyrics.lyrics.isEmpty) {
      AppUtilities.logger.d('Lyrics not found on Spotify, searching on Google');
      mediaLyrics = await getGoogleLyrics(title: title, artist: artist);
      if (mediaLyrics.lyrics.isEmpty) {
        AppUtilities.logger.d('Lyrics not available on Google, finding on Musixmatch');
        mediaLyrics = await getMusixMatchLyrics(title: title, artist: artist);
      }
    }

    return mediaLyrics;
  }

  static Future<MediaLyrics> getSpotifyLyricsFromId(String trackId) async {

    MediaLyrics mediaLyrics = MediaLyrics(mediaId: trackId, source: LyricsSource.spotify);

    try {
      String urlPath = 'spotify-lyric-api-984e7b4face0.herokuapp.com';
      final Uri lyricsUrl = Uri.https(urlPath, '/', {
        'trackid': trackId,
        'format': 'lrc',
      });
      final http.Response res = await http.get(lyricsUrl, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final Map lyricsData = await json.decode(res.body) as Map;
        if (lyricsData['error'] == false) {
          final List lines = await lyricsData['lines'] as List;
          if (lyricsData['syncType'] == 'LINE_SYNCED') {
            mediaLyrics.lyrics = lines.map((e) => '[${e["timeTag"]}]${e["words"]}').toList().join('\n');
            mediaLyrics.type = LyricsType.lrc;
          } else {
            mediaLyrics.lyrics = lines.map((e) => e['words']).toList().join('\n');
          }
        }
      } else {
        AppUtilities.logger.e('getSpotifyLyricsFromId returned ${res.statusCode}');
      }
      return mediaLyrics;
    } catch (e) {
      AppUtilities.logger.e('Error in getSpotifyLyrics ${e.toString()}');
      return mediaLyrics;
    }
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

  static Future<String> getOffLyrics(String path) async {
    try {
      //TODO
      return AppTranslationConstants.noLyricsAvailable.tr;
    } catch (e) {
      return '';
    }
  }

  static Future<MediaLyrics> getMusixMatchLyrics({required String title, required String artist,}) async {

    MediaLyrics mediaLyrics = MediaLyrics(source: LyricsSource.musicMatch);
    String lyrics = '';
    try {
      final String link = await getLyricsLink(title, artist);
      AppUtilities.logger.i('Found Musixmatch Lyrics Link: $link');
      lyrics = await scrapLink(link);
      mediaLyrics.lyrics = lyrics;
    } catch (e) {
      AppUtilities.logger.e('Error in getMusixMatchLyrics ${e.toString()}');
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
    AppUtilities.logger.i('Trying to scrap lyrics from $unencodedPath');
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
