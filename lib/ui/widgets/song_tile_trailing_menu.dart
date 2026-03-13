import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/content_moderation_helper.dart';
import 'package:neom_commons/utils/share_utilities.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';

import '../../utils/constants/audio_player_translation_constants.dart';
import '../../utils/helpers/add_mediaitem_to_queue.dart';
import '../../utils/mappers/media_item_mapper.dart';
import '../library/playlist_player_page.dart';
import '../player/widgets/add_to_playlist.dart';

class SongTileTrailingMenu extends StatefulWidget {
  final AppMediaItem appMediaItem;
  final Itemlist? itemlist;
  final bool isPlaylist;
  final bool showAddToPlaylist;
  final Function(AppMediaItem)? deleteLiked;

  const SongTileTrailingMenu({
    super.key,
    required this.appMediaItem,
    required this.itemlist,
    this.isPlaylist = false,
    this.showAddToPlaylist = true,
    this.deleteLiked,
  });

  @override
  SongTileTrailingMenuState createState() => SongTileTrailingMenuState();
}

class SongTileTrailingMenuState extends State<SongTileTrailingMenu> {

  @override
  Widget build(BuildContext context) {
    final MediaItem mediaItem = MediaItemMapper.fromAppMediaItem(item: widget.appMediaItem);
    return PopupMenuButton(
      color: AppColor.getMain(),
      icon: Icon(
        Icons.more_vert_rounded,
        color: Theme.of(context).iconTheme.color,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(15.0),
        ),
      ),
      itemBuilder: (context) => [
        if(widget.showAddToPlaylist)
          PopupMenuItem(
            value: 0,
            child: Row(
              children: [
                Icon(
                  Icons.playlist_add_rounded,
                  color: Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 10.0),
                Text(AudioPlayerTranslationConstants.addToPlaylist.tr),
              ],
            ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                Icons.queue_music_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(AudioPlayerTranslationConstants.addToQueue.tr),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(
                Icons.playlist_play_rounded,
                color: Theme.of(context).iconTheme.color,
                size: 26.0,
              ),
              const SizedBox(width: 10.0),
              Text(AudioPlayerTranslationConstants.playNext.tr),
            ],
          ),
        ),
        PopupMenuItem(
          value: 3,
          child: Row(
            children: [
              Icon(
                Icons.share_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(AppTranslationConstants.toShare.tr),
            ],
          ),
        ),
        if (widget.isPlaylist && widget.deleteLiked != null)
          PopupMenuItem(
            value: 4,
            child: Row(
              children: [
                const Icon(Icons.delete_rounded,),
                const SizedBox(width: 10.0,),
                Text(AppTranslationConstants.toRemove.tr,),
              ],
            ),
          ),
        if (ContentModerationHelper.canModerate(Sint.find<UserService>().user.userRole)) ...[
          PopupMenuItem(
            value: 10,
            child: Row(
              children: [
                Icon(
                  widget.appMediaItem.isSuspended ? Icons.play_arrow : Icons.pause_circle_outline,
                  color: Colors.orange[300],
                ),
                const SizedBox(width: 10.0),
                Text(widget.appMediaItem.isSuspended
                    ? CommonTranslationConstants.unsuspendContent.tr
                    : CommonTranslationConstants.suspendContent.tr),
              ],
            ),
          ),
          PopupMenuItem(
            value: 11,
            child: Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.red[300]),
                const SizedBox(width: 10.0),
                Text(CommonTranslationConstants.deleteContent.tr,
                  style: TextStyle(color: Colors.red[300]),
                ),
              ],
            ),
          ),
        ],
      ],
      onSelected: (value) {
        AuthGuard.protect(context, () {
          switch (value) {
            case 0:
              AddToPlaylist().addToPlaylist(context, widget.appMediaItem);
            case 1:
              addToNowPlaying(context: context, mediaItem: mediaItem);
            case 2:
              playNext(mediaItem, context);
            case 3:
              ShareUtilities.shareAppWithMediaItem(widget.appMediaItem);
            case 4:
              widget.deleteLiked!(widget.appMediaItem);
            case 5:
              if(widget.itemlist != null) {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (_, _, _) => PlaylistPlayerPage(
                      itemlist: widget.itemlist!,
                    ),
                  ),
                );
              }

            case 10:
              if (widget.appMediaItem.isSuspended) {
                ContentModerationHelper.unsuspendMediaItem(widget.appMediaItem.id);
              } else {
                ContentModerationHelper.showSuspendContentDialog(
                  context,
                  contentName: widget.appMediaItem.name,
                  onConfirm: (reason) async {
                    return await ContentModerationHelper.suspendMediaItem(
                      widget.appMediaItem.id,
                      Sint.find<UserService>().profile.id,
                      reason: reason,
                    );
                  },
                );
              }
            case 11:
              ContentModerationHelper.showDeleteContentDialog(
                context,
                contentName: widget.appMediaItem.name,
                onConfirm: () async {
                  return await ContentModerationHelper.deleteMediaItem(widget.appMediaItem);
                },
              );

            default:
              break;
          }
        });
      },
    );
  }
}
