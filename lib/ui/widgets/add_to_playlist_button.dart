import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../../data/implementations/playlist_hive_controller.dart';
import '../../utils/constants/player_translation_constants.dart';
import '../player/widgets/add_to_playlist.dart';

class AddToPlaylistButton extends StatefulWidget {

  final double size;
  final EdgeInsets? padding;
  final AppMediaItem? appMediaItem;
  final bool inPlaylist;

  const AddToPlaylistButton({
    super.key,
    this.inPlaylist = false,
    this.size = 25,
    this.padding,
    this.appMediaItem,
  });

  @override
  AddToPlaylistButtonState createState() => AddToPlaylistButtonState();
}

class AddToPlaylistButtonState extends State<AddToPlaylistButton>
    with SingleTickerProviderStateMixin {
  bool inPlaylist = false;
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _curve;
  PlaylistHiveController playlistHiveController = PlaylistHiveController();
  AppProfile profile = AppProfile();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _curve = CurvedAnimation(parent: _controller, curve: Curves.slowMiddle);

    _scale = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 50,
      ),
    ]).animate(_curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
    } catch (e) {
      AppUtilities.logger.e('Error in likeButton: $e');
    }
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
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
            } else {
              AddToPlaylist().addToPlaylist(context, widget.appMediaItem!);
              //TODO Add to profile.itemlists list item
            }

            AppMediaItemFirestore().existsOrInsert(widget.appMediaItem!);
          } catch(e) {
            AppUtilities.logger.e(e.toString());
          }

          if (!inPlaylist) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
          setState(() {
            inPlaylist = !inPlaylist;
          });
          AppUtilities.showSnackBar(
            title: '${widget.appMediaItem?.name}',
            message: inPlaylist ? PlayerTranslationConstants.addedToFav.tr : PlayerTranslationConstants.removedFromFav.tr
          );
        },
      ),
    );
  }
}
