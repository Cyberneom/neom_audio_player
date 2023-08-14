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
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_music_player/domain/entities/playlist_item.dart';
import 'package:neom_music_player/domain/entities/playlist_section.dart';
import 'package:neom_music_player/domain/entities/youtube_music_home.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/enums/playlist_type.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeServices {
  static const String searchAuthority = 'www.youtube.com';
  static const Map paths = {
    'search': '/results',
    'channel': '/channel',
    'music': '/music',
    'playlist': '/playlist'
  };
  static const Map<String, String> headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; rv:96.0) Gecko/20100101 Firefox/96.0'
  };
  final YoutubeExplode yt = YoutubeExplode();

  static const playlistLength = 20;

  Future<List<Video>> getPlaylistSongs(String id) async {
    final List<Video> results = await yt.playlists.getVideos(id).toList();
    return results;
  }

  Future<Video?> getVideoFromId(String id) async {
    try {
      final Video result = await yt.videos.get(id);
      return result;
    } catch (e) {
      AppUtilities.logger.e('Error while getting video from id', e);
      return null;
    }
  }

  Future<Map?> formatVideoFromId({
    required String id,
    Map? data,
    bool? getUrl,
  }) async {
    final Video? vid = await getVideoFromId(id);
    if (vid == null) {
      return null;
    }
    final Map? response = await formatVideo(
      video: vid,
      quality: Hive.box(AppHiveConstants.settings).get('ytQuality', defaultValue: 'Low',).toString(),
      data: data,
      getUrl: getUrl ?? true,
    );
    return response;
  }

  Future<Map?> refreshLink(String id) async {
    final Video? res = await getVideoFromId(id);
    if (res == null) {
      return null;
    }
    String quality;
    try {
      quality = Hive.box(AppHiveConstants.settings).get('quality', defaultValue: 'Low').toString();
    } catch (e) {
      quality = 'Low';
    }
    final Map? data = await formatVideo(video: res, quality: quality);
    return data;
  }

  Future<Playlist> getPlaylistDetails(String id) async {
    final Playlist metadata = await yt.playlists.get(id);
    return metadata;
  }

  Future<YoutubeMusicHome> getMusicHome() async {

    final YoutubeMusicHome musicHome = YoutubeMusicHome();
    final Uri link = Uri.https(searchAuthority,
      paths['music'].toString(),
    );
    
    try {
      final Response response = await get(link);

      if (response.statusCode == 200) {
        final String searchResults = RegExp(r'(\"contents\":{.*?}),\"metadata\"',
            dotAll: true).firstMatch(response.body)![1]!;
        final Map data = json.decode('{$searchResults}') as Map;

        final List result = data['contents']['twoColumnBrowseResultsRenderer']
        ['tabs'][0]['tabRenderer']['content']['sectionListRenderer']
        ['contents'] as List;

        final List headResult = data['header']['carouselHeaderRenderer']
        ['contents'][0]['carouselItemRenderer']['carouselItems'] as List;

        final List shelfRenderer = result.map((element) {
          return element['itemSectionRenderer']['contents'][0]['shelfRenderer'];
        }).toList();

        final List<PlaylistSection> bodySection = shelfRenderer.map((element) {
          String resultTitle = element['title']['runs'][0]['text'].toString().trim();
          List shelfRendererItems = element['content']['horizontalListRenderer']['items'] as List;

          final playlistItems = resultTitle == 'Charts' || resultTitle == 'Classements' || resultTitle.contains('Las más escuchadas')
              ? formatItems(shelfRendererItems, type: PlaylistType.chart)
              : resultTitle.contains('Music Videos') || resultTitle.contains('Nouveaux clips')
              || resultTitle.contains('En Musique Avec Moi') || resultTitle.contains('Performances Uniques')
              || resultTitle.contains('Nuevos Videos Musicales') || resultTitle.contains('Actuaciones Únicas')
              ? formatItems(shelfRendererItems, type: PlaylistType.video)
              : formatItems(shelfRendererItems,);
          if (playlistItems.isNotEmpty) {
            AppUtilities.logger.i("Got info successfully for '$resultTitle'",);
            return PlaylistSection(
              title: resultTitle,
              playlistItems: playlistItems,
            );
          } else {
            AppUtilities.logger.w("Got null in getMusicHome for '$resultTitle'",);
            return PlaylistSection(title: resultTitle,);
          }
        }).toList();

        PlaylistSection headSection = PlaylistSection(
          playlistItems: formatItems(headResult, isHead: true)
        );

        musicHome.body = bodySection;
        musicHome.head = headSection;
      }
    } catch (e) {
      AppUtilities.logger.e('Error in getMusicHome: $e');
    }

    return musicHome;
  }

  Future<List> getSearchSuggestions({required String query}) async {
    const baseUrl = 'https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=';
    final Uri link = Uri.parse(baseUrl + query);
    try {
      final Response response = await get(link, headers: headers);
      if (response.statusCode != 200) {
        return [];
      }
      final unescape = HtmlUnescape();
      final List res = (jsonDecode(response.body) as List)[1] as List;
      return res.map((e) => unescape.convert(e.toString())).toList();
    } catch (e) {
      AppUtilities.logger.e('Error in getSearchSuggestions: $e');
      return [];
    }
  }

  List<PlaylistItem> formatItems(List itemsList, {PlaylistType type = PlaylistType.playlist, bool isHead = false}) {

    List<PlaylistItem> playlistItems = [];
    String typeRenderer = "";

    try {

      if(isHead) {
        typeRenderer = 'defaultPromoPanelRenderer';
        type = PlaylistType.video;
      } else {
        switch(type) {
          case PlaylistType.video:
            typeRenderer = "gridVideoRenderer";
            break;
          case PlaylistType.chart:
            typeRenderer = "gridPlaylistRenderer";
            break;
          case PlaylistType.playlist:
            typeRenderer = "compactStationRenderer";
            break;
          case PlaylistType.audio:
            break;
          default:
            typeRenderer = "compactStationRenderer";
            break;
        }
      }

      itemsList.forEach((e) {
        String eTitle = "";
        if(e[typeRenderer]['title']['simpleText'] != null) {
           eTitle = e[typeRenderer]['title']['simpleText'].toString();
        } else {
          eTitle = e[typeRenderer]['title']['runs'][0]['text'].toString();
        }


        String eDescription = "";
        if(e[typeRenderer]['description'] != null) {
          eDescription = isHead ? (e[typeRenderer]['description']['runs'] as List)
              .map((e) => e['text']).toList().join() : e[typeRenderer]['description']['simpleText'] != null
              ? e[typeRenderer]['description']['simpleText'].toString() : e[typeRenderer]['shortBylineText']['runs'][0]['text'].toString();
        }

        String eImgUrl = isHead ? e[typeRenderer]['largeFormFactorBackgroundThumbnail']
          ['thumbnailLandscapePortraitRenderer']['landscape']['thumbnails'].last['url'].toString()
            : e[typeRenderer]['thumbnail']['thumbnails'][0]['url'].toString();

        int eCount = 0;
        if(isHead) {
          eCount = 0;
        } else if(e[typeRenderer]['videoCountText'] != null && e[typeRenderer]['videoCountText']['runs'] != null) {
          eCount = int.parse(e[typeRenderer]['videoCountText']['runs'][0]['text'].toString());
        } else if(e[typeRenderer]['viewCountText'] != null && e[typeRenderer]['viewCountText']['simpleText'] != null) {
          eDescription = eDescription + e[typeRenderer]['viewCountText']['simpleText'].toString();
        }

        String eId = type == PlaylistType.video ? (isHead ? e[typeRenderer]['navigationEndpoint']['watchEndpoint']['videoId'].toString()
            : e[typeRenderer]['videoId'].toString())
            : e[typeRenderer]['navigationEndpoint']['watchEndpoint']['playlistId'].toString();

        String eFirstItemId = type == PlaylistType.video ? (isHead ? e[typeRenderer]['navigationEndpoint']['watchEndpoint']['videoId'].toString()
            : e[typeRenderer]['videoId'].toString())
            : e[typeRenderer]['navigationEndpoint']['watchEndpoint']['videoId'].toString();

        playlistItems.add(
          PlaylistItem(
            title: eTitle,
            type: type,
            description: eDescription,
            imgUrl: eImgUrl,
            count: eCount,
            id: eId,
            firstItemId: eFirstItemId,
          ),
        );
      });
    } catch (e) {
      AppUtilities.logger.e('Error in formatItems: $e');
    }

    return playlistItems;
  }

  Future<Map?> formatVideo({
    required Video video,
    required String quality,
    Map? data,
    bool getUrl = true,
    // bool preferM4a = true,
  }) async {
    if (video.duration?.inSeconds == null) return null;
    List<String> urls = [];
    String finalUrl = '';
    String expireAt = '0';
    if (getUrl) {
      // check cache first
      if (Hive.box(AppHiveConstants.ytLinkCache).containsKey(video.id.value)) {
        final Map cachedData = Hive.box(AppHiveConstants.ytLinkCache).get(video.id.value) as Map;
        final int cachedExpiredAt =
            int.parse(cachedData['expire_at'].toString());
        if ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 350 >
            cachedExpiredAt) {
          // cache expired
          urls = await getUri(video);
        } else {
          // giving cache link
          AppUtilities.logger.i('cache found for ${video.id.value}');
          urls = [cachedData['url'].toString()];
        }
      } else {
        //cache not present
        urls = await getUri(video);
      }

      finalUrl = quality == 'High' ? urls.last : urls.first;
      expireAt = RegExp('expire=(.*?)&').firstMatch(finalUrl)!.group(1) ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600 * 5.5)
              .toString();

      try {
        await Hive.box(AppHiveConstants.ytLinkCache).put(
          video.id.value,
          {
            'url': finalUrl,
            'expire_at': expireAt,
            'lowUrl': urls.first,
            'highUrl': urls.last,
          },
        ).onError(
          (error, stackTrace) => AppUtilities.logger.e(
            'Hive Error in formatVideo, you probably forgot to open box.\nError: $error',
          ),
        );
      } catch (e) {
        AppUtilities.logger.e(
          'Hive Error in formatVideo, you probably forgot to open box.\nError: $e',
        );
      }
    }
    return {
      'id': video.id.value,
      'album': (data?['album'] ?? '') != ''
          ? data!['album']
          : video.author.replaceAll('- Topic', '').trim(),
      'duration': video.duration?.inSeconds.toString(),
      'title':
          (data?['title'] ?? '') != '' ? data!['title'] : video.title.trim(),
      'artist': (data?['artist'] ?? '') != ''
          ? data!['artist']
          : video.author.replaceAll('- Topic', '').trim(),
      'image': video.thumbnails.maxResUrl,
      'secondImage': video.thumbnails.highResUrl,
      'language': 'YouTube',
      'genre': 'YouTube',
      'expire_at': expireAt,
      'url': finalUrl,
      'lowUrl': urls.isNotEmpty ? urls.first : '',
      'highUrl': urls.isNotEmpty ? urls.last : '',
      'year': video.uploadDate?.year.toString(),
      '320kbps': 'false',
      'has_lyrics': 'false',
      'release_date': video.publishDate.toString(),
      'album_id': video.channelId.value,
      'subtitle':
          (data?['subtitle'] ?? '') != '' ? data!['subtitle'] : video.author,
      'perma_url': video.url,
    };
  }

  Future<List<Map>> fetchSearchResults(String query) async {
    final List<Video> searchResults = await yt.search.search(query);
    final List<Map> videoResult = [];
    for (final Video vid in searchResults) {
      final res = await formatVideo(video: vid, quality: 'High', getUrl: false);
      if (res != null) videoResult.add(res);
    }
    return [
      {
        'title': 'Videos',
        'items': videoResult,
      }
    ];
  }

  Future<List<String>> getUri(Video video,) async {
    final StreamManifest manifest =
        await yt.videos.streamsClient.getManifest(video.id);
    final List<AudioOnlyStreamInfo> sortedStreamInfo =
        manifest.audioOnly.sortByBitrate();
    if (Platform.isIOS || Platform.isMacOS) {
      final List<AudioOnlyStreamInfo> m4aStreams = sortedStreamInfo
          .where((element) => element.audioCodec.contains('mp4'))
          .toList();

      if (m4aStreams.isNotEmpty) {
        return [
          m4aStreams.first.url.toString(),
          m4aStreams.last.url.toString(),
        ];
      }
    }
    return [
      sortedStreamInfo.first.url.toString(),
      sortedStreamInfo.last.url.toString(),
    ];
  }

}
