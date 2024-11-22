// import 'package:flutter/material.dart';
// import 'package:neom_commons/core/utils/app_utilities.dart';
//
//
// import '../../neom_player_invoker.dart';
// import '../../ui/player/media_player_page.dart';
// import 'audio_query.dart';
//
// class OfflinePlayHandler extends StatelessWidget {
//
//   final String id;
//   const OfflinePlayHandler({super.key, required this.id});
//
//   Future<List> playOfflineSong(String id) async {
//     final OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
//     await offlineAudioQuery.requestPermission();
//
//     final List<SongModel> songs = await offlineAudioQuery.getSongs();
//     final int index = songs.indexWhere((i) => i.id.toString() == id);
//
//     return [index, songs];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     playOfflineSong(id).then((value) {
//       NeomPlayerInvoker.init(
//         appMediaItems: [],
//         // appMediaItems: AppMediaItem.listFromSongModel(value[1] as List<SongModel>),
//         index: value[0] as int,
//         isOffline: true,
//         recommend: false,
//       );
//       Navigator.pushReplacement(
//         context,
//         PageRouteBuilder(
//           opaque: false,
//           pageBuilder: (_, __, ___) => MediaPlayerPage(),
//         ),
//       );
//     });
//     return const SizedBox.shrink();
//   }
// }
