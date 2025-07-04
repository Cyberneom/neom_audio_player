// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:neom_commons/core/utils/app_utilities.dart';
// import 'package:neom_commons/core/utils/constants/app_assets.dart';
// import 'package:on_audio_query/on_audio_query.dart';
//
// class OfflineAudioQuery {
//   static OnAudioQuery audioQuery = OnAudioQuery();
//   static final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
//
//   Future<void> requestPermission() async {
//     while (!await audioQuery.permissionsStatus()) {
//       await audioQuery.permissionsRequest();
//     }
//   }
//
//   Future<List<SongModel>> getSongs({
//     SongSortType? sortType,
//     OrderType? orderType,
//     String? path,
//   }) async {
//     AppConfig.logger.i(
//       'Getting songs with path: $path, sortType: $sortType, orderType: $orderType',
//     );
//     return audioQuery.querySongs(
//       sortType: sortType ?? SongSortType.DATE_ADDED,
//       orderType: orderType ?? OrderType.DESC_OR_GREATER,
//       uriType: UriType.EXTERNAL,
//       path: path,
//     );
//   }
//
//   Future<List<PlaylistModel>> getPlaylists() async {
//     return audioQuery.queryPlaylists();
//   }
//
//   Future<bool> createPlaylist({required String name}) async {
//     name.replaceAll(avoid, '').replaceAll('  ', ' ');
//     return audioQuery.createPlaylist(name);
//   }
//
//   Future<bool> removePlaylist({required int playlistId}) async {
//     return audioQuery.removePlaylist(playlistId);
//   }
//
//   Future<bool> addToPlaylist({
//     required int playlistId,
//     required int audioId,
//   }) async {
//     return audioQuery.addToPlaylist(playlistId, audioId);
//   }
//
//   Future<bool> removeFromPlaylist({
//     required int playlistId,
//     required int audioId,
//   }) async {
//     return audioQuery.removeFromPlaylist(playlistId, audioId);
//   }
//
//   Future<bool> renamePlaylist({
//     required int playlistId,
//     required String newName,
//   }) async {
//     return audioQuery.renamePlaylist(playlistId, newName);
//   }
//
//   Future<List<SongModel>> getPlaylistSongs(
//     int playlistId, {
//     SongSortType? sortType,
//     OrderType? orderType,
//     String? path,
//   }) async {
//     return audioQuery.queryAudiosFrom(
//       AudiosFromType.PLAYLIST,
//       playlistId,
//       sortType: sortType ?? SongSortType.DATE_ADDED,
//       orderType: orderType ?? OrderType.DESC_OR_GREATER,
//     );
//   }
//
//   Future<List<AlbumModel>> getAlbums({
//     AlbumSortType? sortType,
//     OrderType? orderType,
//   }) async {
//     return audioQuery.queryAlbums(
//       sortType: sortType,
//       orderType: orderType,
//       uriType: UriType.EXTERNAL,
//     );
//   }
//
//   Future<List<ArtistModel>> getArtists({
//     ArtistSortType? sortType,
//     OrderType? orderType,
//   }) async {
//     return audioQuery.queryArtists(
//       sortType: sortType,
//       orderType: orderType,
//       uriType: UriType.EXTERNAL,
//     );
//   }
//
//   Future<List<GenreModel>> getGenres({
//     GenreSortType? sortType,
//     OrderType? orderType,
//   }) async {
//     return audioQuery.queryGenres(
//       sortType: sortType,
//       orderType: orderType,
//       uriType: UriType.EXTERNAL,
//     );
//   }
//
//   static Future<String> queryNSave({
//     required int id,
//     required ArtworkType type,
//     required String tempPath,
//     required String fileName,
//     int size = 500,
//     int quality = 100,
//     ArtworkFormat format = ArtworkFormat.PNG,
//   }) async {
//     final File file = File('$tempPath/$fileName.png');
//
//     if (!await file.exists()) {
//       await file.create();
//       final Uint8List? image = await audioQuery.queryArtwork(
//         id,
//         type,
//         format: format,
//         size: size,
//         quality: quality,
//       );
//       file.writeAsBytesSync(image!);
//     }
//     return file.path;
//   }
//
//   static Widget offlineArtworkWidget({
//     required int id,
//     required ArtworkType type,
//     required String tempPath,
//     required String fileName,
//     int size = 500,
//     int quality = 100,
//     ArtworkFormat format = ArtworkFormat.PNG,
//     ArtworkType artworkType = ArtworkType.AUDIO,
//     BorderRadius? borderRadius,
//     Clip clipBehavior = Clip.antiAlias,
//     BoxFit fit = BoxFit.cover,
//     FilterQuality filterQuality = FilterQuality.low,
//     double height = 50.0,
//     double width = 50.0,
//     double elevation = 5,
//     ImageRepeat imageRepeat = ImageRepeat.noRepeat,
//     bool gaplessPlayback = true,
//     Widget? errorWidget,
//     Widget? placeholder,
//   }) {
//     return FutureBuilder<String>(
//       future: queryNSave(
//         id: id,
//         type: type,
//         format: format,
//         quality: quality,
//         size: size,
//         tempPath: tempPath,
//         fileName: fileName,
//       ),
//       builder: (context, item) {
//         if (item.data != null && item.data!.isNotEmpty) {
//           return Card(
//             elevation: elevation,
//             shape: RoundedRectangleBorder(
//               borderRadius: borderRadius ?? BorderRadius.circular(7.0),
//             ),
//             clipBehavior: clipBehavior,
//             child: Image(
//               image: FileImage(
//                 File(
//                   item.data!,
//                 ),
//               ),
//               gaplessPlayback: gaplessPlayback,
//               repeat: imageRepeat,
//               width: width,
//               height: height,
//               fit: fit,
//               filterQuality: filterQuality,
//               errorBuilder: (context, exception, stackTrace) {
//                 return errorWidget ??
//                     Image(
//                       fit: BoxFit.cover,
//                       height: height,
//                       width: width,
//                       image: const AssetImage(AppAssets.audioPlayerCover),
//                     );
//               },
//             ),
//           );
//         }
//         return Card(
//           elevation: elevation,
//           shape: RoundedRectangleBorder(
//             borderRadius: borderRadius ?? BorderRadius.circular(7.0),
//           ),
//           clipBehavior: clipBehavior,
//           child: placeholder ??
//               Image(
//                 fit: BoxFit.cover,
//                 height: height,
//                 width: width,
//                 image: const AssetImage(AppAssets.audioPlayerCover),
//               ),
//         );
//       },
//     );
//   }
// }
