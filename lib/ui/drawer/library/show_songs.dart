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

import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/neom_player_invoke.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:get/get.dart';
import 'package:neom_music_player/utils/neom_audio_utilities.dart';

class SongsList extends StatefulWidget {
  final List<AppMediaItem> data;
  final bool offline;
  final String? title;
  const SongsList({
    super.key,
    required this.data,
    required this.offline,
    this.title,
  });
  @override
  _SongsListState createState() => _SongsListState();
}

class _SongsListState extends State<SongsList> {
  List<AppMediaItem> _songs = [];
  List original = [];
  bool offline = false;
  bool added = false;
  bool processStatus = false;
  int sortValue = Hive.box(AppHiveConstants.settings).get('sortValue', defaultValue: 1) as int;
  int orderValue =
      Hive.box(AppHiveConstants.settings).get('orderValue', defaultValue: 1) as int;

  Future<void> getSongs() async {
    added = true;
    _songs = widget.data;
    offline = widget.offline;
    if (!offline) original = List.from(_songs);

    _songs = NeomAudioUtilities.sortSongs(_songs, sortVal: sortValue, order: orderValue);

    processStatus = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!added) {
      getSongs();
    }
    return GradientContainer(
      child: Scaffold(
        backgroundColor: AppColor.main75,
        appBar: AppBar(
          title: Text(widget.title ?? PlayerTranslationConstants.songs.tr),
          actions: [
            PopupMenuButton(
              icon: const Icon(Icons.sort_rounded),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15.0)),
              ),
              onSelected: (int value) {
                if (value < 5) {
                  sortValue = value;
                  Hive.box(AppHiveConstants.settings).put('sortValue', value);
                } else {
                  orderValue = value - 5;
                  Hive.box(AppHiveConstants.settings).put('orderValue', orderValue);
                }
                _songs = NeomAudioUtilities.sortSongs(_songs, sortVal: sortValue, order: orderValue);
                setState(() {});
              },
              itemBuilder: (context) {
                final List<String> sortTypes = [
                  PlayerTranslationConstants.displayName.tr,
                  PlayerTranslationConstants.dateAdded.tr,
                  PlayerTranslationConstants.album.tr,
                  PlayerTranslationConstants.artist.tr,
                  PlayerTranslationConstants.duration.tr,
                ];
                final List<String> orderTypes = [
                  PlayerTranslationConstants.inc.tr,
                  PlayerTranslationConstants.dec.tr,
                ];
                final menuList = <PopupMenuEntry<int>>[];
                menuList.addAll(
                  sortTypes
                      .map(
                        (e) => PopupMenuItem(
                          value: sortTypes.indexOf(e),
                          child: Row(
                            children: [
                              if (sortValue == sortTypes.indexOf(e))
                                Icon(
                                  Icons.check_rounded,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.grey[700],
                                )
                              else
                                const SizedBox(),
                              const SizedBox(width: 10),
                              Text(
                                e,
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
                menuList.add(
                  const PopupMenuDivider(
                    height: 10,
                  ),
                );
                menuList.addAll(
                  orderTypes
                      .map(
                        (e) => PopupMenuItem(
                          value: sortTypes.length + orderTypes.indexOf(e),
                          child: Row(
                            children: [
                              if (orderValue == orderTypes.indexOf(e))
                                Icon(
                                  Icons.check_rounded,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.grey[700],
                                )
                              else
                                const SizedBox(),
                              const SizedBox(width: 10),
                              Text(
                                e,
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
                return menuList;
              },
            ),
          ],
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: !processStatus
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                shrinkWrap: true,
                itemCount: _songs.length,
                itemExtent: 70.0,
                itemBuilder: (context, index) {
                  return _songs.isEmpty
                      ? const SizedBox()
                      : ListTile(
                          leading: imageCard(
                            localImage: offline,
                            imageUrl: offline
                                ? _songs[index].imgUrl.toString()
                                : _songs[index].imgUrl.toString(),
                          ),
                          title: Text(
                            '${_songs[index].name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_songs[index].artist}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            NeomPlayerInvoke.init(
                              appMediaItems: _songs,
                              index: index,
                              isOffline: offline,
                              fromDownloads: offline,
                              recommend: !offline,
                            );
                          },
                        );
                },
              ),
      ),
    );
  }
}
