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
import 'package:enum_to_string/enum_to_string.dart';
import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_music_player/utils/enums/app_media_source.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AppMediaItem {
  String id;
  String album;
  String? albumId;
  String artist;
  String artistId;
  List<String>? featArtists;
  List<Map<String, String>>? featArtistsIds;
  String? albumArtist;
  Duration duration;
  String genre;
  String lyrics;
  bool hasLyrics;
  String? language;
  String image;
  List<String>? allImages;
  String? releaseDate;
  String? subtitle;
  String title;
  String? url;
  List<String>? allUrls;
  String permaUrl;
  String? path;
  int? year;
  int expireAt;
  int? trackNumber;
  int? discNumber;
  AppMediaSource mediaSource;
  bool addedByAutoplay;
  int? quality;
  bool kbps320;
  int likes;

  AppMediaItem({
    this.id = '',
    this.album = '',
    this.albumId,
    this.artist = '',
    this.artistId = '',
    this.featArtists,
    this.featArtistsIds,
    this.albumArtist,
    this.duration = Duration.zero,
    this.genre = '',
    this.hasLyrics = false,
    this.image = '',
    this.allImages,
    this.language,
    this.releaseDate,
    this.subtitle,
    this.title = '',
    this.url,
    this.allUrls,
    this.year,
    this.quality,
    this.permaUrl = '',
    this.expireAt = 0,
    this.lyrics = '',
    this.trackNumber,
    this.discNumber,
    this.mediaSource = AppMediaSource.internal,
    this.addedByAutoplay = false,
    this.kbps320 = false,
    this.likes = 0,
    this.path
  });

  factory AppMediaItem.fromMap(map) {
    try {
      final List<String> parts = map['duration'].toString().split(':');
      int dur = 0;
      for (int i = 0; i < parts.length; i++) {
        dur += int.parse(parts[i]) * (60 ^ (parts.length - i - 1));
      }
      final songItem = AppMediaItem(
        id: map['id'].toString() ?? '',
        album: map['album']?.toString() ?? '',
        featArtists: map['artists'] as List<String>? ??
            map['artist']?.split(',') as List<String>? ??
            [],
        duration: Duration(seconds: dur,),
        genre: map['genre'].toString(),
        image: map['image'].toString(),
        allImages: map['allImages'] as List<String>? ??
            map['allImages'] as List<String>? ??
            (map['image']?.toString() != null
                ? [map['image']!.toString()]
                : []),
        language: map['language']?.toString(),
        releaseDate: map['releaseDate']?.toString(),
        subtitle: map['subtitle']?.toString(),
        title: map['title'].toString(),
        url: map['url']?.toString(),
        allUrls: map['allUrls'] as List<String>? ??
            ((map['url'] != null && map['url'] != '')
                ? [map['url'].toString()]
                : []),
        year: int.tryParse(map['year'].toString()),
        quality: int.tryParse(map['quality'].toString()),
        permaUrl: map['permaUrl'].toString(),
        expireAt: int.tryParse(map['expireAt'].toString()) ?? 0,
        lyrics: map['lyrics']?.toString() ?? '',
        trackNumber: int.tryParse(map['trackNumber'].toString()),
        discNumber: int.tryParse(map['discNumber'].toString()),
        addedByAutoplay: map['addedByAutoplay'] as bool? ?? false,
        albumId: map['albumId']?.toString(),
        featArtistsIds: map['artistIds'] as List<Map<String, String>>?,
        mediaSource: EnumToString.fromString(AppMediaSource.values, map["mediaSource"].toString() ?? AppMediaSource.internal.name) ?? AppMediaSource.internal,
        kbps320: map['320kbps'] as bool? ?? false,
        albumArtist: map['albumArtist']?.toString(),
        hasLyrics: map['hasLyrics'] as bool? ?? false,
        likes: int.parse(map['likes']?.toString() ?? '0'),
        path: map['path']?.toString(),
      );
      return songItem;
    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }
  }

  factory AppMediaItem.fromJson(String source) =>
      AppMediaItem.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'album': album,
      'artists': featArtists,
      'duration': duration.inSeconds,
      'genre': genre,
      'image': image,
      'allImages': allImages,
      'language': language,
      'releaseDate': releaseDate,
      'subtitle': subtitle,
      'title': title,
      'url': url,
      'allUrls': allUrls,
      'year': year,
      'quality': quality,
      'permaUrl': permaUrl,
      'expireAt': expireAt,
      'lyrics': lyrics,
      'trackNumber': trackNumber,
      'discNumber': discNumber,
      'addedByAutoplay': addedByAutoplay,
      'albumId': albumId,
      'artistIds': featArtistsIds,
      'mediaSource': mediaSource,
      '320kbps': kbps320,
      'albumArtist': albumArtist,
      'hasLyrics': hasLyrics,
      'likes': likes,
      'path': path,
    };
  }

  String toJson() => json.encode(toMap());

  static List<AppMediaItem> listFromMap(Map<String, List<dynamic>> map) {
    List<AppMediaItem> items = [];
    try {

    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }

    return items;
  }

  static List<AppMediaItem> listFromList(List<dynamic>? list) {
    List<AppMediaItem> items = [];
    try {

    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }

    return items;
  }

  static List<AppMediaItem> listFromSongModel(List<SongModel>? list) {
    List<AppMediaItem> items = [];
    try {

    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }

    return items;
  }

  static AppMediaItem fromAppReleaseItem(AppReleaseItem releaseItem) {
    try {
      return AppMediaItem(
        id: releaseItem.id,
        title: releaseItem.name,
        subtitle: releaseItem.description,
        lyrics: releaseItem.lyrics,
        language: releaseItem.language,
        album: releaseItem.metaName,
        albumId: releaseItem.metaId,
        featArtists: releaseItem.featArtists,
        duration: Duration(seconds: releaseItem.duration,),
        genre: releaseItem.genres.join(', '),
        image: releaseItem.imgUrl,
        allImages: [releaseItem.ownerImgUrl],
        releaseDate: releaseItem.publishedYear.toString(),
        url: releaseItem.previewUrl,
        year: releaseItem.publishedYear,
        permaUrl: releaseItem.previewUrl,
        featArtistsIds: releaseItem.featArtistsIds,
        albumArtist: releaseItem.ownerName,
        hasLyrics: releaseItem.lyrics.isNotEmpty,
        likes: releaseItem.likes,
      );
    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }
  }

  static AppMediaItem fromAppItem(AppItem appItem) {
    try {
      return AppMediaItem(
        id: appItem.id,
        title: appItem.name,
        subtitle: appItem.description,
        lyrics: appItem.lyrics,
        language: appItem.language,
        album: appItem.albumName,
        // albumId: appItem.ur,
        // featArtists: appItem.featArtists,
        duration: Duration(milliseconds: appItem.durationMs,),
        genre: appItem.genres.join(', '),
        image: appItem.albumImgUrl,
        allImages: [appItem.artistImgUrl],
        releaseDate: appItem.publishedDate,
        url: appItem.previewUrl,
        // year: appItem.publishedYear, //TO VERIFY
        permaUrl: appItem.previewUrl,
        // featArtistsIds: appItem.artfeatArtistsIds,
        albumArtist: appItem.artist,
        artist: appItem.artist,
        // hasLyrics: appItem.lyrics.isNotEmpty,
        // likes: appItem.likes,
      );
    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }
  }

  static List<AppMediaItem> mapItemsFromItemlist(Itemlist itemlist) {

    List<AppMediaItem> appMediaItems = [];

    if(itemlist.appItems != null) {
      itemlist.appItems!.forEach((element) {
        appMediaItems.add(AppMediaItem.fromAppItem(element));
      });
    }

    if(itemlist.appReleaseItems != null) {
      itemlist.appReleaseItems!.forEach((element) {
        appMediaItems.add(AppMediaItem.fromAppReleaseItem(element));
      });
    }

    // if(itemlist.chamberPresets != null) {
    //   itemlist.chamberPresets!.forEach((element) {
    //     appMediaItems.add(AppMediaItem.fromAppItem(element));
    //   });
    // }

    AppUtilities.logger.d("Retrieving ${appMediaItems.length} total AppMediaItems.");
    return appMediaItems;
  }


}
