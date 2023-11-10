// import 'dart:io';
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:hive/hive.dart';
// import 'package:neom_commons/core/domain/model/app_media_item.dart';
// import 'package:neom_commons/core/utils/app_color.dart';
// import 'package:neom_commons/core/utils/app_utilities.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:path_provider/path_provider.dart';
//
// import '../../../utils/constants/app_hive_constants.dart';
// import '../../../utils/constants/player_translation_constants.dart';
// import '../../../utils/helpers/audio_query.dart';
// import '../../widgets/custom_physics.dart';
//
// import '../downloads/data_search.dart';
// import 'widgets/songs_tab.dart';
//
// class DownloadedSongs extends StatefulWidget {
//   final List<SongModel>? cachedSongs;
//   final String? title;
//   final int? playlistId;
//   final bool showPlaylists;
//   const DownloadedSongs({
//     super.key,
//     this.cachedSongs,
//     this.title,
//     this.playlistId,
//     this.showPlaylists = false,
//   });
//   @override
//   _DownloadedSongsState createState() => _DownloadedSongsState();
// }
//
// class _DownloadedSongsState extends State<DownloadedSongs> with TickerProviderStateMixin {
//   List<SongModel> _songs = [];
//   String? tempPath = Hive.box(AppHiveConstants.settings).get('tempDirPath')?.toString();
//   final Map<String, List<SongModel>> _albums = {};
//   final Map<String, List<SongModel>> _artists = {};
//   final Map<String, List<SongModel>> _genres = {};
//   final Map<String, List<SongModel>> _folders = {};
//
//   final List<String> _sortedAlbumKeysList = [];
//   final List<String> _sortedArtistKeysList = [];
//   final List<String> _sortedGenreKeysList = [];
//   final List<String> _sortedFolderKeysList = [];
//   // final List<String> _videos = [];
//
//   bool added = false;
//   int sortValue = Hive.box(AppHiveConstants.settings).get('sortValue', defaultValue: 1) as int;
//   int orderValue = Hive.box(AppHiveConstants.settings).get('orderValue', defaultValue: 1) as int;
//   int albumSortValue = Hive.box(AppHiveConstants.settings).get('albumSortValue', defaultValue: 2) as int;
//   List dirPaths = Hive.box(AppHiveConstants.settings).get('searchPaths', defaultValue: []) as List;
//   int minDuration = Hive.box(AppHiveConstants.settings).get('minDuration', defaultValue: 10) as int;
//   bool includeOrExclude = Hive.box(AppHiveConstants.settings).get('includeOrExclude', defaultValue: false) as bool;
//   List includedExcludedPaths = Hive.box(AppHiveConstants.settings).get('includedExcludedPaths', defaultValue: []) as List;
//   TabController? _tcontroller;
//   int _currentTabIndex = 0;
//   OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
//   List<PlaylistModel> playlistDetails = [];
//
//   final Map<int, SongSortType> songSortTypes = {
//     0: SongSortType.DISPLAY_NAME,
//     1: SongSortType.DATE_ADDED,
//     2: SongSortType.ALBUM,
//     3: SongSortType.ARTIST,
//     4: SongSortType.DURATION,
//     5: SongSortType.SIZE,
//   };
//
//   final Map<int, OrderType> songOrderTypes = {
//     0: OrderType.ASC_OR_SMALLER,
//     1: OrderType.DESC_OR_GREATER,
//   };
//
//   @override
//   void initState() {
//     _tcontroller = TabController(length: 1, //widget.showPlaylists ? 6 : 5,
//         vsync: this,);
//     _tcontroller!.addListener(() {
//       if ((_tcontroller!.previousIndex != 0 && _tcontroller!.index == 0) ||
//           (_tcontroller!.previousIndex == 0)) {
//         setState(() => _currentTabIndex = _tcontroller!.index);
//       }
//     });
//     getData();
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _tcontroller!.dispose();
//   }
//
//   bool checkIncludedOrExcluded(SongModel song) {
//     for (final path in includedExcludedPaths) {
//       if (song.data.contains(path.toString())) return true;
//     }
//     return false;
//   }
//
//   Future<void> getData() async {
//     try {
//       AppUtilities.logger.i('Requesting permission to access local songs');
//       await offlineAudioQuery.requestPermission();
//       tempPath ??= (await getTemporaryDirectory()).path;
//       if (Platform.isAndroid) {
//         AppUtilities.logger.i('Getting local playlists');
//         playlistDetails = await offlineAudioQuery.getPlaylists();
//       }
//       if (widget.cachedSongs == null) {
//         AppUtilities.logger.i('Cache empty, calling audioQuery');
//         final receivedSongs = await offlineAudioQuery.getSongs(
//           sortType: songSortTypes[sortValue],
//           orderType: songOrderTypes[orderValue],
//         );
//         AppUtilities.logger.i('Received ${receivedSongs.length} songs, filtering');
//         _songs = receivedSongs.where(
//               (i) => (i.duration ?? 60000) > 1000 * minDuration && (i.isMusic! || i.isPodcast! || i.isAudioBook!) &&
//                   (includeOrExclude ? checkIncludedOrExcluded(i) : !checkIncludedOrExcluded(i)),).toList();
//       } else {
//         AppUtilities.logger.i('Setting songs to cached songs');
//         _songs = widget.cachedSongs!;
//       }
//       added = true;
//       AppUtilities.logger.i('got ${_songs.length} songs');
//       setState(() {});
//       AppUtilities.logger.i('setting albums and artists');
//       for (int i = 0; i < _songs.length; i++) {
//         try {
//           if (_albums.containsKey(_songs[i].album ?? 'Unknown')) {
//             _albums[_songs[i].album ?? 'Unknown']!.add(_songs[i]);
//           } else {
//             _albums[_songs[i].album ?? 'Unknown'] = [_songs[i]];
//             _sortedAlbumKeysList.add(_songs[i].album ?? 'Unknown');
//           }
//
//           if (_artists.containsKey(_songs[i].artist ?? 'Unknown')) {
//             _artists[_songs[i].artist ?? 'Unknown']!.add(_songs[i]);
//           } else {
//             _artists[_songs[i].artist ?? 'Unknown'] = [_songs[i]];
//             _sortedArtistKeysList.add(_songs[i].artist ?? 'Unknown');
//           }
//
//           if (_genres.containsKey(_songs[i].genre ?? 'Unknown')) {
//             _genres[_songs[i].genre ?? 'Unknown']!.add(_songs[i]);
//           } else {
//             _genres[_songs[i].genre ?? 'Unknown'] = [_songs[i]];
//             _sortedGenreKeysList.add(_songs[i].genre ?? 'Unknown');
//           }
//
//           final tempPath = _songs[i].data.split('/');
//           tempPath.removeLast();
//           final dirPath = tempPath.join('/');
//
//           if (_folders.containsKey(dirPath)) {
//             _folders[dirPath]!.add(_songs[i]);
//           } else {
//             _folders[dirPath] = [_songs[i]];
//             _sortedFolderKeysList.add(dirPath);
//           }
//         } catch (e) {
//           AppUtilities.logger.e('Error in sorting songs ${e.toString()}');
//         }
//       }
//       AppUtilities.logger.i('albums, artists, genre & folders set');
//     } catch (e) {
//       AppUtilities.logger.e('Error in getData ${e.toString()}');
//       added = true;
//     }
//   }
//
//   Future<void> sortSongs(int sortVal, int order) async {
//     AppUtilities.logger.i('Sorting songs');
//     switch (sortVal) {
//       case 0:
//         _songs.sort(
//           (a, b) => a.displayName.compareTo(b.displayName),
//         );
//       case 1:
//         _songs.sort(
//           (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
//         );
//       case 2:
//         _songs.sort(
//           (a, b) => a.album.toString().compareTo(b.album.toString()),
//         );
//       case 3:
//         _songs.sort(
//           (a, b) => a.artist.toString().compareTo(b.artist.toString()),
//         );
//       case 4:
//         _songs.sort(
//           (a, b) => a.duration.toString().compareTo(b.duration.toString()),
//         );
//       case 5:
//         _songs.sort(
//           (a, b) => a.size.toString().compareTo(b.size.toString()),
//         );
//       default:
//         _songs.sort(
//           (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
//         );
//         break;
//     }
//
//     if (order == 1) {
//       _songs = _songs.reversed.toList();
//     }
//     AppUtilities.logger.i('Done Sorting songs');
//   }
//
//   Future<void> deleteSong(SongModel song) async {
//     final audioFile = File(song.data);
//     if (_albums[song.album]!.length == 1) {
//       _sortedAlbumKeysList.remove(song.album);
//     }
//     _albums[song.album]!.remove(song);
//
//     if (_artists[song.artist]!.length == 1) {
//       _sortedArtistKeysList.remove(song.artist);
//     }
//     _artists[song.artist]!.remove(song);
//
//     if (_genres[song.genre]!.length == 1) {
//       _sortedGenreKeysList.remove(song.genre);
//     }
//     _genres[song.genre]!.remove(song);
//
//     if (_folders[audioFile.parent.path]!.length == 1) {
//       _sortedFolderKeysList.remove(audioFile.parent.path);
//     }
//     _folders[audioFile.parent.path]!.remove(song);
//
//     _songs.remove(song);
//     try {
//       await audioFile.delete();
//       AppUtilities.showSnackBar(
//         message: '${PlayerTranslationConstants.deleted.tr} ${song.title}',
//       );
//     } catch (e) {
//       AppUtilities.logger.e('Failed to delete $audioFile.path ${e.toString()}');
//       AppUtilities.showSnackBar(
//         duration: const Duration(seconds: 5),
//         message: '${PlayerTranslationConstants.failedDelete.tr}: ${audioFile.path}\nError: $e',
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//         length: 1, //widget.showPlaylists ? 6 : 5,
//         child: Scaffold(
//           backgroundColor: AppColor.main50,
//           appBar: AppBar(
//             title: Text(widget.title ?? PlayerTranslationConstants.myMusic.tr,),
//             bottom: TabBar(
//               isScrollable: widget.showPlaylists,
//               controller: _tcontroller,
//               indicatorSize: TabBarIndicatorSize.label,
//               tabs: [
//                 Tab(
//                   text: PlayerTranslationConstants.songs.tr,
//                 ),
//                 // Tab(
//                 //   text: PlayerTranslationConstants.albums.tr,
//                 // ),
//                 // Tab(
//                 //   text: PlayerTranslationConstants.artists.tr,
//                 // ),
//                 // Tab(
//                 //   text: PlayerTranslationConstants.genres.tr,
//                 // ),
//                 // Tab(
//                 //   text: PlayerTranslationConstants.folders.tr,
//                 // ),
//                 // if (widget.showPlaylists)
//                 //   Tab(
//                 //     text: PlayerTranslationConstants.playlists.tr,
//                 //   ),
//               ],
//             ),
//             actions: [
//               IconButton(
//                 icon: const Icon(CupertinoIcons.search),
//                 tooltip: PlayerTranslationConstants.search.tr,
//                 onPressed: () {
//                   showSearch(
//                     context: context,
//                     delegate: DataSearch(
//                       data: _songs,
//                       tempPath: tempPath!,
//                     ),
//                   );
//                 },
//               ),
//               if (_currentTabIndex == 0)
//                 PopupMenuButton(
//                   icon: const Icon(Icons.sort_rounded),
//                   shape: const RoundedRectangleBorder(
//                     borderRadius: BorderRadius.all(Radius.circular(15.0)),
//                   ),
//                   onSelected: (int value) async {
//                     if (value < 6) {
//                       sortValue = value;
//                       Hive.box(AppHiveConstants.settings).put('sortValue', value);
//                     } else {
//                       orderValue = value - 6;
//                       Hive.box(AppHiveConstants.settings).put('orderValue', orderValue);
//                     }
//                     await sortSongs(sortValue, orderValue);
//                     setState(() {});
//                   },
//                   itemBuilder: (context) {
//                     final List<String> sortTypes = [
//                       PlayerTranslationConstants.displayName.tr,
//                       PlayerTranslationConstants.dateAdded.tr,
//                       PlayerTranslationConstants.album.tr,
//                       PlayerTranslationConstants.artist.tr,
//                       PlayerTranslationConstants.duration.tr,
//                       PlayerTranslationConstants.size.tr,
//                     ];
//                     final List<String> orderTypes = [
//                       PlayerTranslationConstants.inc.tr,
//                       PlayerTranslationConstants.dec.tr,
//                     ];
//                     final menuList = <PopupMenuEntry<int>>[];
//                     menuList.addAll(
//                       sortTypes
//                           .map(
//                             (e) => PopupMenuItem(
//                               value: sortTypes.indexOf(e),
//                               child: Row(
//                                 children: [
//                                   if (sortValue == sortTypes.indexOf(e))
//                                     Icon(
//                                       Icons.check_rounded,
//                                       color: Theme.of(context).brightness ==
//                                               Brightness.dark
//                                           ? Colors.white
//                                           : Colors.grey[700],
//                                     )
//                                   else
//                                     const SizedBox(),
//                                   const SizedBox(width: 10),
//                                   Text(e,),
//                                 ],
//                               ),
//                             ),
//                           )
//                           .toList(),
//                     );
//                     menuList.add(
//                       const PopupMenuDivider(height: 10,),
//                     );
//                     menuList.addAll(
//                       orderTypes
//                           .map(
//                             (e) => PopupMenuItem(
//                               value: sortTypes.length + orderTypes.indexOf(e),
//                               child: Row(
//                                 children: [
//                                   if (orderValue == orderTypes.indexOf(e))
//                                     Icon(
//                                       Icons.check_rounded,
//                                       color: Theme.of(context).brightness ==
//                                               Brightness.dark
//                                           ? Colors.white
//                                           : Colors.grey[700],
//                                     )
//                                   else
//                                     const SizedBox(),
//                                   const SizedBox(width: 10),
//                                   Text(
//                                     e,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           )
//                           .toList(),
//                     );
//                     return menuList;
//                   },
//                 ),
//             ],
//             centerTitle: true,
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//           ),
//           body: !added
//               ? const Center(
//                   child: CircularProgressIndicator(),
//                 )
//               : TabBarView(
//                   physics: const CustomPhysics(),
//                   controller: _tcontroller,
//                   children: [
//                     SongsTab(
//                       songs: _songs.map((e) => AppMediaItem.fromSongModel(e),).toList(),
//                       playlistId: widget.playlistId,
//                       playlistName: widget.title,
//                       tempPath: tempPath!,
//                       deleteSong: deleteSong,
//                     ),
//                   ],
//                 ),
//         ),
//     );
//   }
//
// }