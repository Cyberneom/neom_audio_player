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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:hive/hive.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_music_player/domain/entities/app_media_item.dart';
import 'package:neom_music_player/ui/drawer/library/liked_media_items.dart';
import 'package:neom_music_player/ui/widgets/collage.dart';
import 'package:neom_music_player/ui/widgets/custom_physics.dart';
import 'package:neom_music_player/ui/widgets/data_search.dart';
import 'package:neom_music_player/ui/widgets/download_button.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/widgets/like_button.dart';
import 'package:neom_music_player/ui/widgets/playlist_head.dart';
import 'package:neom_music_player/ui/widgets/song_tile_trailing_menu.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/helpers/songs_count.dart' as songs_count;
import 'package:neom_music_player/neom_player_invoke.dart';
import 'package:neom_music_player/ui/drawer/library/show_songs.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:neom_music_player/utils/neom_audio_utilities.dart';


class SongsPageTab extends StatelessWidget {
  final List<AppMediaItem> appMediaItems;
  final String playlistName;
  final Function(AppMediaItem item) onDelete;
  final ScrollController scrollController;
  const SongsPageTab({
    super.key,
    required this.appMediaItems,
    required this.onDelete,
    required this.playlistName,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {    
    return (appMediaItems.isEmpty)
        ? emptyScreen(
      context,
      3,
      PlayerTranslationConstants.nothingTo.tr,
      15.0,
      PlayerTranslationConstants.showHere.tr,
      50,
      PlayerTranslationConstants.addSomething.tr,
      23.0,
    ) : Column(
      children: [
        PlaylistHead(
          songsList: appMediaItems,
          offline: false,
          fromDownloads: false,
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 10),
            shrinkWrap: true,
            itemCount: appMediaItems.length,
            itemExtent: 70.0,
            itemBuilder: (context, index) {
              AppMediaItem item = appMediaItems[index];
              return ValueListenableBuilder(
                valueListenable: selectMode,
                builder: (context, value, child) {
                  final bool selected = selectedItems.contains(item.id);
                  return ListTile(
                    leading: imageCard(
                      imageUrl: item.image,
                      selected: selected,
                    ),
                    onTap: () {
                      if (selectMode.value) {
                        selectMode.value = false;
                        if (selected) {
                          selectedItems.remove(item.id,);
                          selectMode.value = true;
                          if (selectedItems.isEmpty) {
                            selectMode.value = false;
                          }
                        } else {
                          selectedItems.add(item.id);
                          selectMode.value = true;
                        }
                      } else {
                        NeomPlayerInvoke.init(
                          appMediaItems: appMediaItems,
                          index: index,
                          isOffline: false,
                          recommend: false,
                          playlistBox: playlistName,
                        );
                      }
                    },
                    onLongPress: () {
                      selectMode.value = false;
                      if (selected) {
                        selectedItems.remove(item.id);
                        selectMode.value = true;
                        if (selectedItems.isEmpty) {
                          selectMode.value = false;
                        }
                      } else {
                        selectedItems.add(item.id);
                        selectMode.value = true;
                      }
                    },
                    selected: selected,
                    selectedTileColor: Colors.white10,
                    title: Text('${item.title}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${item.artist ?? 'Unknown'} - ${item.album ?? 'Unknown'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (playlistName != AppHiveConstants.favoriteSongs)
                          LikeButton(
                            mediaItem: null,
                            data: item.toMap(),
                          ),
                        DownloadButton(
                          data: item.toMap(),
                          icon: 'download',
                        ),
                        SongTileTrailingMenu(
                          appMediaItem: item,
                          itemlist: Itemlist(),
                          isPlaylist: true,
                          deleteLiked: onDelete,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}