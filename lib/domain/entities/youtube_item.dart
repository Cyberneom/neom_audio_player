// /*
//  *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
//  * 
//  * BlackHole is free software: you can redistribute it and/or modify
//  * it under the terms of the GNU Lesser General Public License as published by
//  * the Free Software Foundation, either version 3 of the License, or
//  * (at your option) any later version.
//  *
//  * BlackHole is distributed in the hope that it will be useful,
//  * but WITHOUT ANY WARRANTY; without even the implied warranty of
//  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  * GNU Lesser General Public License for more details.
//  *
//  * You should have received a copy of the GNU Lesser General Public License
//  * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
//  * 
//  * Copyright (c) 2021-2023, Ankit Sangwan
//  */
//
// import 'dart:convert';
//
// class AppMediaItem {
//
//   String id;
//   String album;
//   Duration duration;
//   String title;
//   String? subtitle;
//   String artist;
//   String image;
//   String secondImage;
//   String genre;
//   bool hasLyrics;
//   String? language;
//   String? lyrics;
//   String url;
//   String? lowUrl;
//   String? highUrl;
//   int expireAt;
//   int year;
//   bool kbps320;
//   String releaseDate;
//   String albumId;
//   String permaUrl;
//
//   AppMediaItem({
//     this.id = "",
//     this.album = "",
//     this.duration = Duration.zero,
//     this.title = "",
//     this.subtitle,
//     this.artist = "",
//     this.image = "",
//     this.secondImage = "",
//     this.genre = "",
//     this.hasLyrics = false,
//     this.language,
//     this.lyrics,
//     this.url = "",
//     this.lowUrl,
//     this.highUrl,
//     this.expireAt = 0,
//     this.year = 0,
//     this.kbps320 = false,
//     this.releaseDate = "",
//     this.albumId = "",
//     this.permaUrl = "",
//   });
//
//   AppMediaItem.fromJSON(json):
//     id = json['id'].toString(),
//       album = json['album'].toString(),
//       duration= Duration(seconds: json['duration'] as int),
//       title= json['title'].toString(),
//       subtitle= json['subtitle'].toString(),
//       artist= json['artist'].toString(),
//       image= json['image'].toString(),
//       secondImage= json['secondImage'].toString(),
//       genre= json['genre'].toString(),
//       hasLyrics= json['hasLyrics'] as bool,
//       language= json['language'].toString(),
//       lyrics= json['lyrics'].toString(),
//       url= json['url'].toString(),
//       lowUrl= json['lowUrl'].toString(),
//       highUrl= json['highUrl'].toString(),
//       expireAt= json['expireAt'] as int,
//       year= json['year'] as int,
//       kbps320= json['kbps320'] as bool,
//       releaseDate= json['releaseDate'].toString(),
//       albumId= json['albumId'].toString(),
//       permaUrl= json['permaUrl'].toString();
//
//
//   Map<String, dynamic> toJSON() {
//     return {
//       'id': id,
//       'album': album,
//       'duration': duration.inSeconds,
//       'title': title,
//       'subtitle': subtitle,
//       'artist': artist,
//       'image': image,
//       'secondImage': secondImage,
//       'genre': genre,
//       'hasLyrics': hasLyrics,
//       'language': language,
//       'lyrics': lyrics,
//       'url': url,
//       'lowUrl': lowUrl,
//       'highUrl': highUrl,
//       'expireAt': expireAt,
//       'year': year,
//       'kbps320': kbps320,
//       'releaseDate': releaseDate,
//       'albumId': albumId,
//       'permaUrl': permaUrl,
//     };
//   }
// }
