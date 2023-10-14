/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_music_player/data/api_services/spotify/spotify_api_calls.dart';
import 'package:neom_music_player/data/implementations/playlist_hive_controller.dart';
import 'package:neom_music_player/domain/use_cases/ytmusic/youtube_services.dart';
import 'package:neom_music_player/to_delete/APIs/saavn_api.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// ignore: avoid_classes_with_only_static_members
class SearchAddPlaylist {
  static Future<Map> addYtPlaylist(String inLink) async {
    final String link = '$inLink&';
    try {
      final RegExpMatch? id = RegExp(r'.*list\=(.*?)&').firstMatch(link);
      if (id != null) {
        final Playlist metadata =
            await YouTubeServices().getPlaylistDetails(id[1]!);
        final List<Video> tracks =
            await YouTubeServices().getPlaylistSongs(id[1]!);
        return {
          'title': metadata.title,
          'image': metadata.thumbnails.standardResUrl,
          'author': metadata.author,
          'description': metadata.description,
          'tracks': tracks,
          'count': tracks.length,
        };
      }
      return {};
    } catch (e) {
      AppUtilities.logger.e('Error while adding YT playlist: $e');
      return {};
    }
  }

  static Future<Map> addSpotifyPlaylist(
    String title,
    String accessToken,
    String playlistId,
  ) async {
    try {
      final List tracks =
          await SpotifyApiCalls().getAllTracksOfPlaylist(accessToken, playlistId);
      return {
        'title': title,
        'count': tracks.length,
        'tracks': tracks,
      };
    } catch (e) {
      AppUtilities.logger.e('Error while adding Spotify playlist: $e');
      return {};
    }
  }

  static Future<Map> addRessoPlaylist(String inLink) async {
    try {
      final RegExpMatch? id = RegExp(r'.*?id\=(.*)&').firstMatch('$inLink&');
      if (id != null) {
        final List tracks = await getRessoSongs(playlistId: id[1]!);
        return {
          'title': 'Resso Playlist',
          'count': tracks.length,
          'tracks': tracks,
        };
      } else {
        final Request req = Request('Get', Uri.parse(inLink))
          ..followRedirects = false;
        final Client baseClient = Client();
        final StreamedResponse response = await baseClient.send(req);
        final Uri redirectUri =
            Uri.parse(response.headers['location'].toString());
        baseClient.close();
        final RegExpMatch? id2 =
            RegExp(r'.*?id\=(.*)&').firstMatch('$redirectUri&');
        if (id2 != null) {
          final List tracks = await getRessoSongs(playlistId: id2[1]!);
          return {
            'title': 'Resso Playlist',
            'count': tracks.length,
            'tracks': tracks,
          };
        }
      }
      return {};
    } catch (e) {
      AppUtilities.logger.e('Error while adding Resso playlist: $e');
      return {};
    }
  }

  static Future<List> getRessoSongs({required String playlistId}) async {
    const url = 'https://api.resso.app/resso/playlist/detail?playlist_id=';
    final Uri link = Uri.parse(url + playlistId);
    final http.Response response = await get(link);
    if (response.statusCode != 200) {
      return [];
    }
    final res = await jsonDecode(response.body);
    return res['tracks'] as List;
  }

  static Future<Map> addJioSaavnPlaylist(String inLink) async {
    try {
      final String id = inLink.split('/').last;
      if (id != '') {
        final Map data =
            await SaavnAPI().getSongFromToken(id, 'playlist', n: -1);
        return {
          'title': data['title'],
          'count': data['list'].length,
          'tracks': data['list'],
        };
      }
      return {};
    } catch (e) {
      AppUtilities.logger.e('Error while adding JioSaavn playlist: $e');
      return {};
    }
  }

  static Stream<Map> ytSongsAdder(String playName, List tracks) async* {
    int done = 0;
    for (final track in tracks) {
      String? trackName;
      try {
        trackName = (track as Video).title;
        yield {'done': ++done, 'name': trackName};
      } catch (e) {
        yield {'done': ++done, 'name': ''};
      }
      try {
        final List result =
            await SaavnAPI().fetchTopSearchResult(trackName!.split('|')[0]);
        PlaylistHiveController().addMapToPlaylist(playName, result[0] as Map);
      } catch (e) {
        AppUtilities.logger.e('Error in $done: $e');
      }
    }
  }

  static Stream<Map> spotifySongsAdder(String playName, List tracks) async* {
    int done = 0;
    for (final track in tracks) {
      String? trackName;
      String? artistName;
      try {
        trackName = track['track']['name'].toString();
        artistName = (track['track']['artists'] as List)
            .map((e) => e['name'])
            .toList()
            .join(', ');
        yield {'done': ++done, 'name': '$trackName - $artistName'};
      } catch (e) {
        yield {'done': ++done, 'name': ''};
      }
      try {
        final List result =
            await SaavnAPI().fetchTopSearchResult('$trackName by $artistName');
        PlaylistHiveController().addMapToPlaylist(playName, result[0] as Map);
      } catch (e) {
        AppUtilities.logger.e('Error in $done: $e');
      }
    }
  }

  static Stream<Map> ressoSongsAdder(String playName, List tracks) async* {
    int done = 0;
    for (final track in tracks) {
      String? trackName;
      String? artistName;
      try {
        trackName = track['name'].toString();
        artistName = (track['artists'] as List)
            .map((e) => e['name'])
            .toList()
            .join(', ');

        yield {'done': ++done, 'name': '$trackName - $artistName'};
      } catch (e) {
        yield {'done': ++done, 'name': ''};
      }
      try {
        final List result =
            await SaavnAPI().fetchTopSearchResult('$trackName by $artistName');
        PlaylistHiveController().addMapToPlaylist(playName, result[0] as Map);
      } catch (e) {
        AppUtilities.logger.e('Error in $done: $e');
      }
    }
  }

  static Future<void> showProgress(
    int total,
    BuildContext cxt,
    Stream songAdd,
  ) async {
    if (total != 0) {
      await showModalBottomSheet(
        isDismissible: false,
        backgroundColor: AppColor.main75,
        context: cxt,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStt) {
              return BottomGradientContainer(
                child: SizedBox(
                  height: 300,
                  width: 300,
                  child: StreamBuilder<Object>(
                    stream: songAdd as Stream<Object>?,
                    builder: (ctxt, AsyncSnapshot snapshot) {
                      final Map? data = snapshot.data as Map?;
                      final int done = (data ?? const {})['done'] as int? ?? 0;
                      final String name =
                          (data ?? const {})['name'] as String? ?? '';
                      if (done == total) Navigator.pop(ctxt);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Center(
                            child: Text(
                              PlayerTranslationConstants.convertingSongs.tr,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            height: 80,
                            width: 80,
                            child: Stack(
                              children: [
                                Center(
                                  child: Text('$done / $total'),
                                ),
                                Center(
                                  child: SizedBox(
                                    height: 77,
                                    width: 77,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(ctxt).colorScheme.secondary,
                                      ),
                                      value: done / total,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }
}
