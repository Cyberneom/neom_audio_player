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
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
//
// import 'package:hive/hive.dart';
// import 'package:neom_commons/core/app_flavour.dart';
// import 'package:neom_commons/core/domain/model/item_list.dart';
// import 'package:neom_commons/core/utils/app_color.dart';
// import 'package:neom_commons/core/utils/constants/app_assets.dart';
// import 'package:neom_music_player/domain/entities/app_media_item.dart';
// import 'package:neom_music_player/ui/widgets/collage.dart';
// import 'package:neom_music_player/ui/widgets/custom_physics.dart';
// import 'package:neom_music_player/ui/widgets/data_search.dart';
// import 'package:neom_music_player/ui/widgets/download_button.dart';
// import 'package:neom_music_player/ui/widgets/empty_screen.dart';
// import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
// import 'package:neom_music_player/ui/widgets/image_card.dart';
// import 'package:neom_music_player/ui/widgets/like_button.dart';
// import 'package:neom_music_player/ui/widgets/playlist_head.dart';
// import 'package:neom_music_player/ui/widgets/song_tile_trailing_menu.dart';
// import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
// import 'package:neom_music_player/utils/helpers/songs_count.dart' as songs_count;
// import 'package:neom_music_player/neom_player_invoke.dart';
// import 'package:neom_music_player/ui/drawer/library/show_songs.dart';
// import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
// // import 'package:path_provider/path_provider.dart';
// import 'package:get/get.dart';
// import 'package:neom_music_player/utils/neom_audio_utilities.dart';
//
//
// class AlbumsTab extends StatefulWidget {
//   final Map<String, List> albums;
//   final List sortedAlbumKeysList;
//   // final String? tempPath;
//   final String type;
//   final bool offline;
//   final String? playlistName;
//   const AlbumsTab({
//     super.key,
//     required this.albums,
//     required this.offline,
//     required this.sortedAlbumKeysList,
//     required this.type,
//     this.playlistName,
//     // this.tempPath,
//   });
//
//   @override
//   State<AlbumsTab> createState() => _AlbumsTabState();
// }
//
// class _AlbumsTabState extends State<AlbumsTab>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true;
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return widget.sortedAlbumKeysList.isEmpty
//         ? emptyScreen(
//       context,
//       3,
//       PlayerTranslationConstants.nothingTo.tr,
//       15.0,
//       PlayerTranslationConstants.showHere.tr,
//       50,
//       PlayerTranslationConstants.addSomething.tr,
//       23.0,
//     )
//         : ListView.builder(
//       physics: const BouncingScrollPhysics(),
//       padding: const EdgeInsets.only(bottom: 10.0),
//       shrinkWrap: true,
//       itemExtent: 70.0,
//       itemCount: widget.sortedAlbumKeysList.length,
//       itemBuilder: (context, index) {
//         final List imageList = widget
//             .albums[widget.sortedAlbumKeysList[index]]!.length >= 4
//             ? widget.albums[widget.sortedAlbumKeysList[index]]!.sublist(0, 4)
//             : widget.albums[widget.sortedAlbumKeysList[index]]!.sublist(0,
//           widget.albums[widget.sortedAlbumKeysList[index]]!.length,
//         );
//         return ListTile(
//           leading: (widget.offline)
//               ? OfflineCollage(
//             imageList: imageList,
//             showGrid: widget.type == 'genre',
//             placeholderImage: widget.type == 'artist'
//                 ? AppAssets.musicPlayerArtist
//                 : AppAssets.musicPlayerAlbum,
//           )
//               : Collage(
//             imageList: [AppFlavour.getAppLogoUrl()],//itemlist.getImgUrls(),
//             showGrid: widget.type == 'genre',
//             placeholderImage: widget.type == 'artist'
//                 ? AppAssets.musicPlayerArtist
//                 : AppAssets.musicPlayerAlbum,
//           ),
//           title: Text(
//             '${widget.sortedAlbumKeysList[index]}',
//             overflow: TextOverflow.ellipsis,
//           ),
//           subtitle: Text(
//             widget.albums[widget.sortedAlbumKeysList[index]]!.length == 1
//                 ? '${widget.albums[widget.sortedAlbumKeysList[index]]!.length} ${PlayerTranslationConstants.song.tr}'
//                 : '${widget.albums[widget.sortedAlbumKeysList[index]]!.length} ${PlayerTranslationConstants.songs.tr}',
//             style: TextStyle(
//               color: Theme.of(context).textTheme.bodySmall!.color,
//             ),
//           ),
//           onTap: () {
//             Navigator.of(context).push(
//               PageRouteBuilder(
//                 opaque: false,
//                 pageBuilder: (_, __, ___) => widget.offline
//                     ? SongsList(
//                   data: AppMediaItem.listFromList(widget.albums[widget.sortedAlbumKeysList[index]]!),
//                   offline: widget.offline,
//                 )
//                     : LikedSongs(
//                   alternativeName: widget.playlistName!,
//                   appMediaItems: AppMediaItem.listFromList(widget.albums[widget.sortedAlbumKeysList[index]]),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }