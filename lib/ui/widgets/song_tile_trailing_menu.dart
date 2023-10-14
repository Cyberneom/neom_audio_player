/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';
import 'package:neom_itemlists/itemlists/ui/search/app_media_item_search_controller.dart';
import 'package:neom_music_player/domain/use_cases/ytmusic/youtube_services.dart';
import 'package:neom_music_player/to_delete/search/search_page.dart';
import 'package:neom_music_player/ui/widgets/add_to_playlist.dart';
import 'package:neom_music_player/ui/widgets/song_list.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:neom_music_player/utils/helpers/add_mediaitem_to_queue.dart';
import 'package:neom_music_player/utils/helpers/media_item_mapper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
        if(widget.showAddToPlaylist) PopupMenuItem(
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
        if (widget.isPlaylist && widget.deleteLiked != null)
          PopupMenuItem(
            value: 6,
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
        if(widget.appMediaItem.mediaSource == AppMediaSource.internal) PopupMenuItem(
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
          case 6:
            widget.deleteLiked!(widget.appMediaItem);
          default:
            // Navigator.push(
            //   context,
            //   PageRouteBuilder(
            //     opaque: false,
            //     pageBuilder: (_, __, ___) => AlbumSearchPage(
            //       query: value.toString(),
            //       type: 'Artists',
            //     ),
            //   ),
            // );
            break;
        // PopupMenuItem(
        //   value: 4,
        //   child: Row(
        //     children: [
        //       Icon(
        //         Icons.album_rounded,
        //         color: Theme.of(context).iconTheme.color,
        //       ),
        //       const SizedBox(width: 10.0),
        //       Text(PlayerTranslationConstants.viewAlbum.tr),
        //     ],
        //   ),
        // ),
        // if (mediaItem.artist != null)
        //   ...mediaItem.artist.toString().split(', ').map(
        //         (artist) => PopupMenuItem(
        //           value: artist,
        //           child: SingleChildScrollView(
        //             scrollDirection: Axis.horizontal,
        //             child: Row(
        //               children: [
        //                 Icon(
        //                   Icons.person_rounded,
        //                   color: Theme.of(context).iconTheme.color,
        //                 ),
        //                 const SizedBox(width: 10.0),
        //                 Text(
        //                   '${PlayerTranslationConstants.viewArtist.tr} ($artist)',
        //                 ),
        //               ],
        //             ),
        //           ),
        //         ),
        //   ),
        }
      },
    );
  }
}

class YtSongTileTrailingMenu extends StatefulWidget {
  final Map data;
  const YtSongTileTrailingMenu({super.key, required this.data});

  @override
  _YtSongTileTrailingMenuState createState() => _YtSongTileTrailingMenuState();
}

class _YtSongTileTrailingMenuState extends State<YtSongTileTrailingMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
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
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.search,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(
                width: 10.0,
              ),
              Text(
                PlayerTranslationConstants.searchHome.tr,
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
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
          value: 2,
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
        PopupMenuItem(
          value: 3,
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
        PopupMenuItem(
          value: 4,
          child: Row(
            children: [
              Icon(
                Icons.video_library_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(PlayerTranslationConstants.watchVideo.tr),
            ],
          ),
        ),
        PopupMenuItem(
          value: 5,
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
      ],
      onSelected: (int? value) {
        if (value == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchPage(
                query: widget.data['title'].toString(),
              ),
            ),
          );
        }
        if (value == 1 || value == 2 || value == 3) {
          YouTubeServices().formatVideoFromId(
            id: widget.data['id'].toString(), data: widget.data,
          ).then((songMap) {
            final MediaItem mediaItem = MediaItemMapper.appMediaItemToMediaItem(appMediaItem: songMap!);
            if (value == 1) {
              playNext(mediaItem, context);
            }
            if (value == 2) {
              addToNowPlaying(context: context, mediaItem: mediaItem);
            }
            if (value == 3) {
              // AddToPlaylist().addToPlaylist(context, mediaItem);
            }
          });
        }
        if (value == 4) {
          launchUrl(Uri.parse('https://youtube.com/watch?v=${widget.data["id"]}'),
            mode: LaunchMode.externalApplication,
          );
        }
        if (value == 5) {
          Share.share('https://youtube.com/watch?v=${widget.data["id"]}');
        }
      },
    );
  }
}
