// import 'dart:io';
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// import 'package:hive/hive.dart';
// import 'package:logging/logging.dart';
// import 'package:neom_commons/core/utils/app_color.dart';
// import 'package:neom_commons/core/utils/app_utilities.dart';
// import 'package:neom_commons/core/domain/model/app_media_item.dart';
// import 'package:neom_music_player/ui/drawer/local_music/downloaded_songs.dart';
// import 'package:neom_music_player/ui/widgets/add_playlist.dart';
// import 'package:neom_music_player/ui/widgets/custom_physics.dart';
// import 'package:neom_music_player/ui/widgets/data_search.dart';
// import 'package:neom_music_player/ui/widgets/empty_screen.dart';
// import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
// import 'package:neom_music_player/ui/widgets/playlist_head.dart';
// import 'package:neom_music_player/ui/widgets/snackbar.dart';
// import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
// import 'package:neom_music_player/utils/helpers/audio_query.dart';
// import 'package:neom_music_player/neom_player_invoke.dart';
// import 'package:neom_music_player/ui/drawer/local_music/localplaylists.dart';
// import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:get/get.dart';
//
//
// class AlbumsTab extends StatefulWidget {
//   final Map<String, List<SongModel>> albums;
//   final List<String> albumsList;
//   final String tempPath;
//   final bool isFolder;
//   const AlbumsTab({
//     super.key,
//     required this.albums,
//     required this.albumsList,
//     required this.tempPath,
//     this.isFolder = false,
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
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void dispose() {
//     super.dispose();
//     _scrollController.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return widget.albumsList.isEmpty
//         ? emptyScreen(
//       context,
//       3,
//       PlayerTranslationConstants.nothingTo.tr,
//       15.0,
//       PlayerTranslationConstants.showHere.tr,
//       45,
//       PlayerTranslationConstants.downloadSomething.tr,
//       23.0,
//     )
//         : Scrollbar(
//       controller: _scrollController,
//       thickness: 8,
//       thumbVisibility: true,
//       radius: const Radius.circular(10),
//       interactive: true,
//       child: ListView.builder(
//         physics: const BouncingScrollPhysics(),
//         padding: const EdgeInsets.only(top: 20, bottom: 10),
//         controller: _scrollController,
//         shrinkWrap: true,
//         itemExtent: 70.0,
//         itemCount: widget.albumsList.length,
//         itemBuilder: (context, index) {
//           String title = widget.albumsList[index];
//           if (widget.isFolder && title.length > 35) {
//             final splits = title.split('/');
//             title = '${splits.first}/.../${splits.last}';
//           }
//           return ListTile(
//             leading: OfflineAudioQuery.offlineArtworkWidget(
//               id: widget.albums[widget.albumsList[index]]![0].id,
//               type: ArtworkType.AUDIO,
//               tempPath: widget.tempPath,
//               fileName: widget
//                   .albums[widget.albumsList[index]]![0].displayNameWOExt,
//             ),
//             title: Text(
//               title,
//               overflow: TextOverflow.ellipsis,
//             ),
//             subtitle: Text(
//               '${widget.albums[widget.albumsList[index]]!.length} ${PlayerTranslationConstants.songs.tr}',
//             ),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => DownloadedSongs(
//                     title: widget.albumsList[index],
//                     cachedSongs: widget.albums[widget.albumsList[index]],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
