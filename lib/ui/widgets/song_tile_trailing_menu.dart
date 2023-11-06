import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';
import 'package:neom_itemlists/itemlists/ui/search/app_media_item_search_controller.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/constants/player_translation_constants.dart';
import '../../utils/helpers/add_mediaitem_to_queue.dart';
import '../../utils/helpers/media_item_mapper.dart';
import 'add_to_playlist.dart';
import 'song_list.dart';

class SongTileTrailingMenu extends StatefulWidget {
  final AppMediaItem appMediaItem;
  final Itemlist? itemlist;
  final bool isPlaylist;
  final bool showAddToPlaylist;
  final Function(AppMediaItem)? deleteLiked;
  final AppMediaItemSearchController? searchController;

  const SongTileTrailingMenu({
    super.key,
    required this.appMediaItem,
    required this.itemlist,
    this.isPlaylist = false,
    this.showAddToPlaylist = true,
    this.deleteLiked,
    this.searchController,
  });

  @override
  _SongTileTrailingMenuState createState() => _SongTileTrailingMenuState();
}

class _SongTileTrailingMenuState extends State<SongTileTrailingMenu> {
  @override
  Widget build(BuildContext context) {
    final MediaItem mediaItem = MediaItemMapper.appMediaItemToMediaItem(appMediaItem: widget.appMediaItem);
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
                Text(PlayerTranslationConstants.addToPlaylist.tr),
              ],
            ),
        ),
        if(widget.appMediaItem.mediaSource == AppMediaSource.internal) PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                Icons.queue_music_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(PlayerTranslationConstants.addToQueue.tr),
            ],
          ),
        ),
        if(widget.appMediaItem.mediaSource == AppMediaSource.internal)
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
                Text(PlayerTranslationConstants.playNext.tr),
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
              Text(PlayerTranslationConstants.share.tr),
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
                Text(
                  PlayerTranslationConstants.remove.tr,
                ),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 0:
            AddToPlaylist().addToPlaylist(context, widget.appMediaItem);
          case 1:
            addToNowPlaying(context: context, mediaItem: mediaItem);
          case 2:
            playNext(mediaItem, context);
          case 3:
            Share.share(widget.appMediaItem.permaUrl);
          case 4:
            widget.deleteLiked!(widget.appMediaItem);
          case 5:
            if(widget.itemlist != null) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) => SongsListPage(
                    itemlist: widget.itemlist!,
                  ),
                ),
              );
            }

          default:
            break;
        }
      },
    );
  }
}
