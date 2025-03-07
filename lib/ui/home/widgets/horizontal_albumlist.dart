// import 'package:flutter/material.dart';
// import 'package:neom_commons/core/domain/model/app_media_item.dart';
// import 'package:neom_commons/core/domain/model/item_list.dart';
// import 'package:neom_commons/core/utils/app_color.dart';
// import 'package:neom_commons/core/utils/constants/app_assets.dart';
// import 'package:neom_commons/core/utils/enums/itemlist_type.dart';
//
// import '../../utils/enums/image_quality.dart';
// import 'image_card.dart';
// import 'like_button.dart';
// import '../home/widgets/hover_box.dart';
// import 'song_tile_trailing_menu.dart';
//
// class HorizontalAlbumsList extends StatelessWidget {
//   final Itemlist itemlist;
//   final Function(int) onTap;
//   const HorizontalAlbumsList({
//     super.key,
//     required this.itemlist,
//     required this.onTap,
//   });
//
//   String formatString(String? text) {
//     return text == null
//         ? ''
//         : text
//             .replaceAll('&amp;', '&')
//             .replaceAll('&#039;', "'")
//             .replaceAll('&quot;', '"')
//             .trim();
//   }
//
//   String getSubTitle(AppMediaItem item, {ItemlistType type = ItemlistType.single}) {
//
//     if (type == ItemlistType.album) {
//       return '';
//     } else if (type == ItemlistType.playlist || type == ItemlistType.radioStation) {
//       return formatString(item.name);
//     } else if (type == ItemlistType.single) {
//       return formatString(item.artist);
//     } else {
//       if (item.album.isNotEmpty) {
//         return formatString(item.imgUrl);
//       }
//       String artist = item.artist;
//       return formatString(artist);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double boxSize =
//         MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
//             ? MediaQuery.of(context).size.width / 2
//             : MediaQuery.of(context).size.height / 2.5;
//     if (boxSize > 250) boxSize = 250;
//     return SizedBox(
//       height: boxSize + 15,
//       child: ListView.builder(
//         physics: const BouncingScrollPhysics(),
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         itemCount: itemlist.appMediaItems?.length ?? 0,
//         itemBuilder: (context, index) {
//           final AppMediaItem appMediaItem = AppMediaItem.mapItemsFromItemlist(itemlist).elementAt(index);
//           final subTitle = getSubTitle(appMediaItem);
//           return GestureDetector(
//             onLongPress: () {
//               Feedback.forLongPress(context);
//               showDialog(
//                 context: context,
//                 builder: (context) {
//                   return AlertDialog(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15.0),
//                     ),
//                     backgroundColor: AppColor.main75,
//                     contentPadding: EdgeInsets.zero,
//                     content: imageCard(
//                       borderRadius: 15, //appMediaItem['type'] == 'radio_station' ? 1000.0 : 15.0,
//                       imageUrl: appMediaItem.imgUrl,
//                       boxDimension: MediaQuery.of(context).size.width * 0.8,
//                       imageQuality: ImageQuality.high,
//                       placeholderImage: const AssetImage(AppAssets.audioPlayerAlbum,),
//                       // (appMediaItem['type'] == 'playlist' || appMediaItem['type'] == 'album')
//                       //     ? const AssetImage(AppAssets.audioPlayerAlbum,)
//                       //     : appMediaItem['type'] == 'artist'
//                       //     ? const AssetImage(AppAssets.audioPlayerArtist,)
//                       //     : const AssetImage(AppAssets.audioPlayerCover,),
//                     ),
//                   );
//                 },
//               );
//             },
//             onTap: () {
//               onTap(index);
//             },
//             child: SizedBox(
//               width: boxSize - 30,
//               child: HoverBox(
//                 child: imageCard(
//                   margin: const EdgeInsets.all(4.0),
//                   borderRadius: 10,
//                   // appMediaItem['type'] == 'radio_station' || appMediaItem['type'] == 'artist' ? 1000.0 : 10.0,
//                   imageUrl: appMediaItem.imgUrl,
//                   boxDimension: double.infinity,
//                   imageQuality: ImageQuality.medium,
//                   placeholderImage: const AssetImage(AppAssets.audioPlayerAlbum,),
//                       // (appMediaItem['type'] == 'playlist' || appMediaItem['type'] == 'album')
//                       //     ? const AssetImage(AppAssets.audioPlayerAlbum,)
//                       //     : appMediaItem['type'] == 'artist' ? const AssetImage(AppAssets.audioPlayerArtist,
//                       // ) : const AssetImage(AppAssets.audioPlayerCover,),
//                 ),
//                 builder: ({
//                   required BuildContext context,
//                   required bool isHover,
//                   Widget? child,
//                 }) {
//                   return Card(
//                     color: isHover ? null : Colors.transparent,
//                     elevation: 0,
//                     margin: EdgeInsets.zero,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(
//                         10.0,
//                       ),
//                     ),
//                     clipBehavior: Clip.antiAlias,
//                     child: Column(
//                       children: [
//                         Stack(
//                           children: [
//                             SizedBox.square(
//                               dimension: isHover ? boxSize - 25 : boxSize - 30,
//                               child: child,
//                             ),
//                             if (isHover
//                                 // && (appMediaItem['type'] == 'song' || appMediaItem['type'] == 'radio_station' || appMediaItem['duration'] != null)
//                             )
//                               Positioned.fill(
//                                 child: Container(
//                                   margin: const EdgeInsets.all(
//                                     4.0,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black54,
//                                     borderRadius: BorderRadius.circular(10,
//                                       // appMediaItem['type'] == 'radio_station' ? 1000.0 : 10.0,
//                                     ),
//                                   ),
//                                   child: Center(
//                                     child: DecoratedBox(
//                                       decoration: BoxDecoration(
//                                         color: Colors.black87,
//                                         borderRadius:
//                                             BorderRadius.circular(1000.0),
//                                       ),
//                                       child: const Icon(
//                                         Icons.play_arrow_rounded,
//                                         size: 50.0,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             if (isHover
//                                 // && (appMediaItem['type'] == 'song' || appMediaItem['duration'] != null)
//                             )
//                               Align(
//                                 alignment: Alignment.topRight,
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     const LikeButton(),
//                                     SongTileTrailingMenu(
//                                       appMediaItem: appMediaItem, //appMediaItem,
//                                       itemlist: itemlist,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                           ],
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 10.0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(formatString(appMediaItem.name),
//                                 textAlign: TextAlign.center,
//                                 softWrap: false,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               if (subTitle.isNotEmpty)
//                                 Text(
//                                   subTitle,
//                                   textAlign: TextAlign.center,
//                                   softWrap: false,
//                                   overflow: TextOverflow.ellipsis,
//                                   style: TextStyle(
//                                     fontSize: 11,
//                                     color: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall!
//                                         .color,
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
