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
// import 'package:flutter/material.dart';
//
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// import 'package:neom_commons/core/app_flavour.dart';
// import 'package:neom_commons/core/utils/app_color.dart';
// import 'package:neom_commons/core/utils/constants/app_assets.dart';
// import 'package:neom_music_player/ui/widgets/collage.dart';
// import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
// import 'package:neom_music_player/ui/widgets/snackbar.dart';
// import 'package:neom_music_player/ui/widgets/textinput_dialog.dart';
// import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
// import 'package:neom_music_player/utils/helpers/import_export_playlist.dart';
// import 'package:neom_music_player/ui/drawer/library/import.dart';
// import 'package:neom_music_player/ui/drawer/library/liked.dart';
// import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
// import 'package:get/get.dart';
//
// class PlaylistPage extends StatelessWidget {
//
//   @override
//   Widget build(BuildContext context) {
//
//     final Box settingsBox = Hive.box(AppHiveConstants.settings);
//     final List playlistNames = Hive.box(AppHiveConstants.settings).get('playlistNames')?.toList() as List? ?? [AppHiveConstants.favoriteSongs];
//     Map playlistDetails = Hive.box(AppHiveConstants.settings).get('playlistDetails', defaultValue: {}) as Map;
//
//     if (!playlistNames.contains(AppHiveConstants.favoriteSongs)) {
//       playlistNames.insert(0, AppHiveConstants.favoriteSongs);
//       settingsBox.put('playlistNames', playlistNames);
//     }
//
//     return GradientContainer(
//       child: Scaffold(
//         backgroundColor: AppColor.main75,
//         appBar: AppBar(
//           title: Text(
//             PlayerTranslationConstants.playlists.tr,
//           ),
//           centerTitle: true,
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//         ),
//         body: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(height: 5),
//               ListTile(
//                 title: Text(PlayerTranslationConstants.createPlaylist.tr),
//                 leading: SizedBox.square(
//                   dimension: 50,
//                   child: Center(
//                     child: Icon(
//                       Icons.add_rounded,
//                       color: Theme.of(context).iconTheme.color,
//                     ),
//                   ),
//                 ),
//                 onTap: () async {
//                   showTextInputDialog(
//                     context: context,
//                     title: PlayerTranslationConstants.createNewPlaylist.tr,
//                     initialText: '',
//                     keyboardType: TextInputType.name,
//                     onSubmitted: (String value, BuildContext context) async {
//                       final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
//                       value.replaceAll(avoid, '').replaceAll('  ', ' ');
//                       if (value.trim() == '') {
//                         value = 'Playlist ${playlistNames.length}';
//                       }
//                       while (playlistNames.contains(value) ||
//                           await Hive.boxExists(value)) {
//                         // ignore: use_string_buffers
//                         value = '$value (1)';
//                       }
//                       playlistNames.add(value);
//                       settingsBox.put('playlistNames', playlistNames);
//                       Navigator.pop(context);
//                     },
//                   );
//                 },
//               ),
//               ListTile(
//                 title: Text(PlayerTranslationConstants.importPlaylist.tr),
//                 leading: SizedBox.square(
//                   dimension: 50,
//                   child: Center(
//                     child: Icon(
//                       MdiIcons.import,
//                       color: Theme.of(context).iconTheme.color,
//                     ),
//                   ),
//                 ),
//                 onTap: () async {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ImportPlaylist(),
//                     ),
//                   );
//                 },
//               ),
//               ValueListenableBuilder(
//                 valueListenable: settingsBox.listenable(),
//                 builder: (
//                   BuildContext context,
//                   Box box,
//                   Widget? child,
//                 ) {
//                   final List playlistNamesValue = box.get(
//                         'playlistNames',
//                         defaultValue: [AppHiveConstants.favoriteSongs],
//                       )?.toList() as List? ??
//                       [AppHiveConstants.favoriteSongs];
//                   return ListView.builder(
//                     physics: const NeverScrollableScrollPhysics(),
//                     shrinkWrap: true,
//                     itemCount: playlistNamesValue.length,
//                     itemBuilder: (context, index) {
//                       final String name = playlistNamesValue[index].toString();
//                       final String showName = playlistDetails.containsKey(name)
//                           ? playlistDetails[name]['name']?.toString() ?? name
//                           : name;
//                       return ListTile(
//                         leading: (playlistDetails[name] == null ||
//                                 playlistDetails[name]['imagesList'] == null ||
//                                 (playlistDetails[name]['imagesList'] as List)
//                                     .isEmpty)
//                             ? Card(
//                                 elevation: 5,
//                                 color: Colors.transparent,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(7.0),
//                                 ),
//                                 clipBehavior: Clip.antiAlias,
//                                 child: SizedBox(
//                                   height: 50,
//                                   width: 50,
//                                   child: name == AppHiveConstants.favoriteSongs
//                                       ? const Image(image: AssetImage(AppAssets.musicPlayerCover,),)
//                                       : const Image(image: AssetImage(AppAssets.musicPlayerAlbum),),
//                                 ),
//                               )
//                             : Collage(
//                                 imageList: [AppFlavour.getAppLogoUrl()],//playlistDetails[name]['imagesList'] as List,
//                                 showGrid: true,
//                                 placeholderImage: AppAssets.musicPlayerCover,
//                               ),
//                         title: Text(
//                           showName,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         subtitle: playlistDetails[name] == null ||
//                                 playlistDetails[name]['count'] == null ||
//                                 playlistDetails[name]['count'] == 0
//                             ? null
//                             : Text(
//                                 '${playlistDetails[name]['count']} ${PlayerTranslationConstants.songs.tr}',
//                               ),
//                         trailing: PopupMenuButton(
//                           icon: const Icon(Icons.more_vert_rounded),
//                           shape: const RoundedRectangleBorder(
//                             borderRadius: BorderRadius.all(
//                               Radius.circular(15.0),
//                             ),
//                           ),
//                           onSelected: (int? value) async {
//                             if (value == 1) {
//                               exportPlaylist(
//                                 context,
//                                 name,
//                                 playlistDetails.containsKey(name)
//                                     ? playlistDetails[name]['name']?.toString() ?? name : name,
//                               );
//                             }
//                             if (value == 2) {
//                               sharePlaylist(
//                                 context,
//                                 name,
//                                 playlistDetails.containsKey(name)
//                                     ? playlistDetails[name]['name']
//                                     ?.toString() ?? name : name,
//                               );
//                             }
//                             if (value == 0) {
//                               ShowSnackBar().showSnackBar(
//                                 context,
//                                 '${PlayerTranslationConstants.deleted.tr} $showName',
//                               );
//                               playlistDetails.remove(name);
//                               await settingsBox.put(
//                                 'playlistDetails',
//                                 playlistDetails,
//                               );
//                               await playlistNames.removeAt(index);
//                               await settingsBox.put(
//                                 'playlistNames',
//                                 playlistNames,
//                               );
//                               await Hive.openBox(name);
//                               await Hive.box(name).deleteFromDisk();
//                             }
//                             if (value == 3) {
//                               showDialog(
//                                 context: context,
//                                 builder: (BuildContext context) {
//                                   final controller = TextEditingController(
//                                     text: showName,
//                                   );
//                                   return AlertDialog(
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(15.0),
//                                     ),
//                                     content: Column(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             Text(
//                                               PlayerTranslationConstants.rename.tr,
//                                               style: TextStyle(
//                                                 color: Theme.of(context)
//                                                     .colorScheme
//                                                     .secondary,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         TextField(
//                                           autofocus: true,
//                                           textAlignVertical:
//                                               TextAlignVertical.bottom,
//                                           controller: controller,
//                                           onSubmitted: (value) async {
//                                             Navigator.pop(context);
//                                             playlistDetails[name] == null
//                                                 ? playlistDetails.addAll({
//                                                     name: {'name': value.trim()}
//                                                   })
//                                                 : playlistDetails[name].addAll({
//                                                     'name': value.trim(),
//                                                   });
//
//                                             await settingsBox.put(
//                                               'playlistDetails',
//                                               playlistDetails,
//                                             );
//                                           },
//                                         ),
//                                       ],
//                                     ),
//                                     actions: [
//                                       TextButton(
//                                         style: TextButton.styleFrom(
//                                           foregroundColor:
//                                               Theme.of(context).iconTheme.color,
//                                         ),
//                                         onPressed: () {
//                                           Navigator.pop(context);
//                                         },
//                                         child: Text(
//                                           PlayerTranslationConstants.cancel.tr,
//                                         ),
//                                       ),
//                                       TextButton(
//                                         style: TextButton.styleFrom(
//                                           foregroundColor: Colors.white,
//                                           backgroundColor: Theme.of(context)
//                                               .colorScheme
//                                               .secondary,
//                                         ),
//                                         onPressed: () async {
//                                           Navigator.pop(context);
//                                           playlistDetails[name] == null
//                                               ? playlistDetails.addAll({
//                                                   name: {
//                                                     'name':
//                                                         controller.text.trim()
//                                                   }
//                                                 })
//                                               : playlistDetails[name].addAll({
//                                                   'name': controller.text.trim()
//                                                 });
//
//                                           await settingsBox.put(
//                                             'playlistDetails',
//                                             playlistDetails,
//                                           );
//                                         },
//                                         child: Text(
//                                           PlayerTranslationConstants.ok.tr,
//                                           style: TextStyle(
//                                             color: Theme.of(context)
//                                                         .colorScheme
//                                                         .secondary ==
//                                                     Colors.white
//                                                 ? Colors.black
//                                                 : null,
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(
//                                         width: 5,
//                                       ),
//                                     ],
//                                   );
//                                 },
//                               );
//                             }
//                           },
//                           itemBuilder: (context) => [
//                             if (name != AppHiveConstants.favoriteSongs)
//                               PopupMenuItem(
//                                 value: 3,
//                                 child: Row(
//                                   children: [
//                                     const Icon(Icons.edit_rounded),
//                                     const SizedBox(width: 10.0),
//                                     Text(
//                                       PlayerTranslationConstants.rename.tr,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             if (name != AppHiveConstants.favoriteSongs)
//                               PopupMenuItem(
//                                 value: 0,
//                                 child: Row(
//                                   children: [
//                                     const Icon(Icons.delete_rounded),
//                                     const SizedBox(width: 10.0),
//                                     Text(
//                                       PlayerTranslationConstants.delete.tr,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             PopupMenuItem(
//                               value: 1,
//                               child: Row(
//                                 children: [
//                                   const Icon(MdiIcons.export),
//                                   const SizedBox(width: 10.0),
//                                   Text(
//                                     PlayerTranslationConstants.export.tr,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             PopupMenuItem(
//                               value: 2,
//                               child: Row(
//                                 children: [
//                                   const Icon(MdiIcons.share),
//                                   const SizedBox(width: 10.0),
//                                   Text(
//                                     PlayerTranslationConstants.share.tr,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         onTap: () async {
//                           await Hive.openBox(name);
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => LikedSongs(
//                                 playlistName: name,
//                                 showName: playlistDetails.containsKey(name)
//                                     ? playlistDetails[name]['name']
//                                             ?.toString() ??
//                                         name
//                                     : name,
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
