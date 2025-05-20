import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../../data/implementations/playlist_hive_controller.dart';
import 'package:neom_media_player/utils/constants/player_translation_constants.dart';

class LikeButton extends StatefulWidget {

  final double size;
  final EdgeInsets? padding;
  final AppMediaItem? appMediaItem;

  const LikeButton({
    super.key,
    this.size = 25,
    this.padding,
    this.appMediaItem,
  });

  @override
  LikeButtonState createState() => LikeButtonState();
}

class LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  bool liked = false;
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
    AppProfile profile = playlistHiveController.userController.profile;
    try {
      liked = profile.favoriteItems?.contains(widget.appMediaItem?.id) ?? false;
    } catch (e) {
      AppUtilities.logger.e('Error in likeButton: $e');
    }
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        padding: widget.padding,
        icon: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: liked ? Colors.redAccent : Theme.of(context).iconTheme.color,
        ),
        iconSize: widget.size,
        tooltip: liked ? PlayerTranslationConstants.unlike.tr : PlayerTranslationConstants.like.tr,
        onPressed: () async {
          String itemId = widget.appMediaItem?.id ?? '';

          if(itemId.isEmpty) return;

          try {
            if(liked) {
              profile.favoriteItems?.remove(itemId);
              ProfileFirestore().removeFavoriteItem(profile.id, itemId);
            } else {
              profile.favoriteItems?.add(itemId);
              ProfileFirestore().addFavoriteItem(profile.id, itemId);
            }
          } catch(e) {
            AppUtilities.logger.e(e.toString());
          }

          if (!liked) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
          setState(() {
            liked = !liked;
          });
          AppUtilities.showSnackBar(
            title: '${widget.appMediaItem?.name}',
            message: liked ? PlayerTranslationConstants.addedToFav.tr : PlayerTranslationConstants.removedFromFav.tr
          );
        },
      ),
    );
  }
}
