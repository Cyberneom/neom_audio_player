import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';

import 'package:neom_commons/core/utils/app_utilities.dart';

import '../../utils/constants/player_translation_constants.dart';
import '../player/widgets/add_to_playlist.dart';

class AddToPlaylistButton extends StatefulWidget {

  final double size;
  final EdgeInsets? padding;
  final AppMediaItem? appMediaItem;
  final Itemlist? playlist;

  const AddToPlaylistButton({
    super.key,
    this.size = 25,
    this.padding,
    this.appMediaItem,
    this.playlist,
  });

  @override
  AddToPlaylistButtonState createState() => AddToPlaylistButtonState();
}

class AddToPlaylistButtonState extends State<AddToPlaylistButton> {

  bool inPlaylist = false;

  @override
  void initState() {
    super.initState();
    inPlaylist = widget.playlist != null;
  }

  @override
  Widget build(BuildContext context) {
    try {
    } catch (e) {
      AppUtilities.logger.e('Error in likeButton: $e');
    }
    return IconButton(
        padding: widget.padding,
        icon: Icon(
          inPlaylist ? Icons.playlist_add_check_outlined : Icons.playlist_add,
          color: Theme.of(context).iconTheme.color,
        ),
        iconSize: widget.size,
        onPressed: () async {
          String itemId = widget.appMediaItem?.id ?? '';

          if(itemId.isEmpty) return;

          try {
            if(inPlaylist) {
              //TODO remove from itemlist in database
              //TODO Remove from profile.itemlists list item
              if(await ItemlistFirestore().deleteItem(itemlistId: widget.playlist!.id, appMediaItem: widget.appMediaItem!)){
                widget.playlist?.appMediaItems?.removeWhere((item) => item.id == widget.appMediaItem?.id);
                Get.find<UserController>().user.profiles.first.itemlists?[widget.playlist!.id] = widget.playlist!;
              }

              setState(() {
                inPlaylist = false;
              });

              AppUtilities.showSnackBar(
                  title: '${widget.appMediaItem?.name}',
                  message: "${inPlaylist ? PlayerTranslationConstants.addedTo.tr : PlayerTranslationConstants.removedFrom.tr} ${widget.playlist?.name}"
              );
            } else {
              await AddToPlaylist().addToPlaylist(context, widget.appMediaItem!, goHome: false);
              //TODO Add to profile.itemlists list item
              setState(() {
                inPlaylist = true;
              });
            }

            // AppMediaItemFirestore().existsOrInsert(widget.appMediaItem!);
          } catch(e) {
            AppUtilities.logger.e(e.toString());
          }
        },
    );
  }
}
