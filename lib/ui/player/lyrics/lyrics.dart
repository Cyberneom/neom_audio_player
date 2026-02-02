import 'package:sint/sint.dart';
import 'package:http/http.dart' as http;
import 'package:neom_core/app_config.dart';

import '../../../domain/models/media_lyrics.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/enums/lyrics_source.dart';



class Lyrics {

  static Future<MediaLyrics> getLyrics({required String id, required String title, required String artist}) async {
    MediaLyrics mediaLyrics = MediaLyrics(mediaId: id);
    AppConfig.logger.i('Getting Synced Lyrics');
    if (mediaLyrics.lyrics.isEmpty) {
      //TODO Implement to get lyrics from gigmeout blog entries
    }

    return mediaLyrics;
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
      return AudioPlayerTranslationConstants.noLyricsAvailable.tr;
    } catch (e) {
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
    } catch (e) {
      AppConfig.logger.e('Error in getMusixMatchLyrics ${e.toString()}');
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
