import 'package:flutter/material.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_itemlists/ui/widgets/add_to_itemlist_sheet.dart';

class AddToPlaylist {

  Future<bool> addToPlaylist(BuildContext context, AppMediaItem appMediaItem, {List<Itemlist>? playlists, bool fromSearch = false, bool goHome = true}) async {
    return AddToItemlistSheet.show(
      context,
      item: appMediaItem,
      listType: ItemlistType.playlist,
    );
  }

}
