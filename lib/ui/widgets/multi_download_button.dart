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
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_music_player/domain/use_cases/download.dart';
import 'package:neom_music_player/to_delete/APIs/saavn_api.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';

class MultiDownloadButton extends StatefulWidget {
  final List data;
  final String playlistName;
  const MultiDownloadButton({
    super.key,
    required this.data,
    required this.playlistName,
  });

  @override
  _MultiDownloadButtonState createState() => _MultiDownloadButtonState();
}

class _MultiDownloadButtonState extends State<MultiDownloadButton> {
  late Download down;
  int done = 0;

  @override
  void initState() {
    super.initState();
    down = Download(widget.data.first['id'].toString());
    down.addListener(() {
      setState(() {});
    });
  }

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox();
    }
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: (down.lastDownloadId == widget.data.last['id'])
            ? IconButton(
                icon: const Icon(
                  Icons.download_done_rounded,
                ),
                color: Theme.of(context).colorScheme.secondary,
                iconSize: 25.0,
                tooltip: PlayerTranslationConstants.downDone.tr,
                onPressed: () {},
              )
            : down.progress == 0
                ? Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                      ),
                      iconSize: 25.0,
                      tooltip: PlayerTranslationConstants.down.tr,
                      onPressed: () async {
                        for (final items in widget.data) {
                          AppMediaItem appMediaItem = AppMediaItem.fromJSON(items);
                          down.prepareDownload(
                            context,
                            appMediaItem,
                            createFolder: true,
                            folderName: widget.playlistName,
                          );
                          await _waitUntilDone(appMediaItem.id);
                          setState(() {
                            done++;
                          });
                        }
                      },
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Text(
                          down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%',
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 35,
                          width: 35,
                          child: CircularProgressIndicator(
                            value: down.progress == 1 ? null : down.progress,
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            value: done / widget.data.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class AlbumDownloadButton extends StatefulWidget {
  final String albumId;
  final String albumName;
  const AlbumDownloadButton({
    super.key,
    required this.albumId,
    required this.albumName,
  });

  @override
  _AlbumDownloadButtonState createState() => _AlbumDownloadButtonState();
}

class _AlbumDownloadButtonState extends State<AlbumDownloadButton> {
  late Download down;
  int done = 0;
  List data = [];
  bool finished = false;

  @override
  void initState() {
    super.initState();
    down = Download(widget.albumId);
    down.addListener(() {
      setState(() {});
    });
  }

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: finished
            ? IconButton(
                icon: const Icon(
                  Icons.download_done_rounded,
                ),
                color: Theme.of(context).colorScheme.secondary,
                iconSize: 25.0,
                tooltip: PlayerTranslationConstants.downDone.tr,
                onPressed: () {},
              )
            : down.progress == 0
                ? Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                      ),
                      iconSize: 25.0,
                      color: Theme.of(context).iconTheme.color,
                      tooltip: PlayerTranslationConstants.down.tr,
                      onPressed: () async {
                        ShowSnackBar().showSnackBar(
                          context,
                          '${PlayerTranslationConstants.downingAlbum.tr} "${widget.albumName}"',
                        );

                        data = (await SaavnAPI()
                            .fetchAlbumSongs(widget.albumId))['songs'] as List;
                        for (final items in data) {
                          AppMediaItem appMediaItem = AppMediaItem.fromJSON(items);
                          down.prepareDownload(context,
                            appMediaItem,
                            createFolder: true,
                            folderName: widget.albumName,
                          );
                          await _waitUntilDone(appMediaItem.id);
                          setState(() {
                            done++;
                          });
                        }
                        finished = true;
                      },
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Text(
                          down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%',
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 35,
                          width: 35,
                          child: CircularProgressIndicator(
                            value: down.progress == 1 ? null : down.progress,
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            value: data.isEmpty ? 0 : done / data.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
