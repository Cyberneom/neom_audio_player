import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/widgets/images/neom_image_card.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';

import '../../player/audio_player_controller.dart';
import '../../widgets/custom_physics.dart';
import '../../widgets/song_tile_trailing_menu.dart';

class HorizontalAlbumsListSeparated extends StatelessWidget {
  final List<AppMediaItem> songsList;
  final Itemlist? itemlist;
  final Function(int) onTap;
  const HorizontalAlbumsListSeparated({
    super.key,
    required this.songsList,
    required this.onTap,
    this.itemlist,
  });

  String formatString(String? text) {
    return text == null ? '' : text.replaceAll('&amp;', '&').replaceAll('&#039;', "'")
        .replaceAll('&quot;', '"').trim();
  }

  ///DEPRECATED
  // String getSubTitle(Map item) {
  //   final type = item['type'];
  //   if (type == 'charts') {
  //     return '';
  //   } else if (type == 'playlist' || type == 'radio_station') {
  //     return formatString(item['subtitle']?.toString());
  //   } else if (type == 'song') {
  //     return formatString(item['ownerName']?.toString());
  //   } else {
  //     if (item['subtitle'] != null) {
  //       return formatString(item['subtitle']?.toString());
  //     }
  //     final artists = item['more_info']?['artistMap']?['artists']
  //         .map((ownerName) => ownerName['name'])
  //         .toList();
  //     if (artists != null) {
  //       return formatString(artists?.join(', ')?.toString());
  //     }
  //     if (item['ownerName'] != null) {
  //       return formatString(item['ownerName']?.toString());
  //     }
  //     return '';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final bool rotated = MediaQuery.of(context).size.height < MediaQuery.of(context).size.width;
    final bool biggerScreen = MediaQuery.of(context).size.width > 1050;
    final double portion = (songsList.length <= 4) ? 1.0 : 0.875;
    final double listSize = rotated ? biggerScreen
        ? MediaQuery.of(context).size.width * portion / 3
        : MediaQuery.of(context).size.width * portion / 2
        : MediaQuery.of(context).size.width * portion;
    return SizedBox(
      height: songsList.length < 4 ? songsList.length * 74 : 74 * 4,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ListView.builder(
          physics: PagingScrollPhysics(itemDimension: listSize),
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemExtent: listSize,
          itemCount: (songsList.length / 4).ceil(),
          itemBuilder: (context, index) {
            final itemGroup = songsList.skip(index * 4).take(4);
            return SizedBox(
              height: 72 * 4,
              width: listSize,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: itemGroup.map((item) {
// getSubTitle(item as Map);
                  return ListTile(
                    title: Text(
                      formatString(item.name),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.ownerName,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: NeomImageCard(
                      imageUrl: item.imgUrl,
                      placeholderImage: (itemlist?.type == ItemlistType.playlist ||
                              itemlist?.type == ItemlistType.album)
                          ? const AssetImage(AppAssets.audioPlayerAlbum,)
                          : item.ownerName.isNotEmpty ? const AssetImage(AppAssets.audioPlayerArtist,)
                              : const AssetImage(AppAssets.audioPlayerCover,),
                    ),
                    trailing: SongTileTrailingMenu(
                      appMediaItem: item,//.getTotalItems() > 0 ? AppMediaItem.mapItemsFromItemlist(item).first : AppMediaItem(),
                      itemlist: itemlist ?? Itemlist(),
                      showAddToPlaylist: false,
                    ),
                    onTap: () => onTap(songsList.indexOf(item)),
                    onLongPress: () {
                      if (Sint.isRegistered<AudioPlayerController>()) {
                        Sint.delete<AudioPlayerController>();
                        Sint.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [item]);
                      } else {
                        Sint.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [item]);
                      }
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
