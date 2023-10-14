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
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_music_player/domain/use_cases/ytmusic/youtube_services.dart';
import 'package:neom_music_player/domain/use_cases/ytmusic/yt_music.dart';
import 'package:neom_music_player/neom_player_invoker.dart';
import 'package:neom_music_player/ui/widgets/bouncy_playlist_header_scroll_view.dart';
import 'package:neom_music_player/ui/widgets/copy_clipboard.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/widgets/playlist_popupmenu.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/ui/widgets/song_tile_trailing_menu.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';

class YouTubePlaylist extends StatefulWidget {
  final String playlistId;
  final String type;
  // final String playlistName;
  // final String? playlistSubtitle;
  // final String? playlistSecondarySubtitle;
  // final String playlistImage;
  const YouTubePlaylist({
    super.key,
    required this.playlistId,
    this.type = 'playlist',
    // required this.playlistName,
    // required this.playlistSubtitle,
    // required this.playlistSecondarySubtitle,
    // required this.playlistImage,
  });

  @override
  _YouTubePlaylistState createState() => _YouTubePlaylistState();
}

class _YouTubePlaylistState extends State<YouTubePlaylist> {
  bool status = false;
  List<Map> searchedList = [];
  bool fetched = false;
  bool done = true;
  final ScrollController _scrollController = ScrollController();
  String playlistName = '';
  String playlistSubtitle = '';
  String? playlistSecondarySubtitle;
  String playlistImage = '';

  @override
  void initState() {
    if (!status) {
      status = true;
      if (widget.type == 'playlist') {
        YtMusicService().getPlaylistDetails(widget.playlistId).then((value) {
          setState(() {
            try {
              searchedList = value['songs'] as List<Map>? ?? [];
              playlistName = value['name'] as String? ?? '';
              playlistSubtitle = value['subtitle'] as String? ?? '';
              playlistSecondarySubtitle = value['description'] as String?;
              playlistImage = (value['images'] as List?)?.last as String? ?? '';
              fetched = true;
            } catch (e) {
              AppUtilities.logger.e('Error in fetching playlist details', e);
              fetched = true;
            }
          });
        });
      } else if (widget.type == 'album') {
        YtMusicService().getAlbumDetails(widget.playlistId).then((value) {
          setState(() {
            try {
              searchedList = value['songs'] as List<Map>? ?? [];
              playlistName = value['name'] as String? ?? '';
              playlistSubtitle = value['subtitle'] as String? ?? '';
              playlistSecondarySubtitle = value['description'] as String?;
              playlistImage = (value['images'] as List?)?.last as String? ?? '';
              fetched = true;
            } catch (e) {
              AppUtilities.logger.e('Error in fetching playlist details', e);
              fetched = true;
            }
          });
        });
      } else if (widget.type == 'artist') {
        YtMusicService().getArtistDetails(widget.playlistId).then((value) {
          setState(() {
            try {
              searchedList = value['songs'] as List<Map>? ?? [];
              playlistName = value['name'] as String? ?? '';
              playlistSubtitle = value['subtitle'] as String? ?? '';
              playlistSecondarySubtitle = value['description'] as String?;
              playlistImage = (value['images'] as List?)?.last as String? ?? '';
              fetched = true;
            } catch (e) {
              AppUtilities.logger.e('Error in fetching playlist details', e);
              fetched = true;
            }
          });
        });
      }
      // YouTubeServices().getPlaylistSongs(widget.playlistId).then((value) {
      //   if (value.isNotEmpty) {
      //     setState(() {
      //       searchedList = value;
      //       fetched = true;
      //     });
      //   } else {
      //     status = false;
      //   }
      // });
    }
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext cntxt) {
    return GradientContainer(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColor.main75,
        body: Stack(
          children: [
            if (!fetched)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              BouncyPlaylistHeaderScrollView(
                scrollController: _scrollController,
                title: playlistName,
                subtitle: playlistSubtitle,
                secondarySubtitle: playlistSecondarySubtitle,
                imageUrl: playlistImage,
                actions: [
                  PlaylistPopupMenu(
                    data: searchedList,
                    title: playlistName,
                  ),
                ],
                onPlayTap: () async {
                  setState(() {
                    done = false;
                  });

                  try {
                    final AppMediaItem? response = await YouTubeServices().formatVideoFromId(
                      id: searchedList.first['id'].toString(), data: searchedList.first,
                    );
                    final List<AppMediaItem> playList = AppMediaItem.listFromList(searchedList);
                    if(playList.isNotEmpty) {
                      playList[0] = response!;

                      setState(() {
                        done = true;
                      });
                      NeomPlayerInvoker.init(
                        appMediaItems: playList,
                        index: 0,
                        isOffline: false,
                        recommend: false,
                      );
                    }
                  } catch (e) {
                    AppUtilities.logger.e(e.toString());
                    setState(() {
                      done = true;
                    });
                    ShowSnackBar().showSnackBar(
                      context,
                      'Algo sucedió al iniciar la reproducción.',
                    );
                  }

                },

                onShuffleTap: () async {
                  setState(() {
                    done = false;
                  });
                  final List<AppMediaItem> playList = List.from(searchedList);
                  playList.shuffle();
                  final AppMediaItem? response = await YouTubeServices().formatVideoFromId(
                    id: playList.first.id,
                    data: searchedList.first,
                  );
                  playList[0] = response!;
                  setState(() {
                    done = true;
                  });
                  NeomPlayerInvoker.init(
                    appMediaItems: playList,
                    index: 0,
                    isOffline: false,
                    recommend: false,
                  );
                },
                sliverList: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      if (searchedList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20.0,
                            top: 5.0,
                            bottom: 5.0,
                          ),
                          child: Text(
                            PlayerTranslationConstants.songs.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ...searchedList.map(
                        (Map entry) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 5.0,
                            ),
                            child: ListTile(
                              leading: widget.type == 'album'
                                  ? null
                                  : imageCard(
                                      imageUrl: entry['image'].toString(),
                                    ),
                              title: Text(
                                entry['title'].toString(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onLongPress: () {
                                copyToClipboard(
                                  context: context,
                                  text: entry['title'].toString(),
                                );
                              },
                              subtitle: entry['subtitle'] == ''
                                  ? null
                                  : Text(
                                      entry['subtitle'].toString(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              onTap: () async {
                                setState(() {
                                  done = false;
                                });
                                final AppMediaItem? response = await YouTubeServices().formatVideoFromId(
                                  id: entry['id'].toString(), data: entry,);
                                setState(() {
                                  done = true;
                                });

                                if(response != null) {
                                  NeomPlayerInvoker.init(
                                    appMediaItems: [response],
                                    index: 0,
                                    isOffline: false,
                                  );
                                }
                                // for (var i = 0;
                                //     i < searchedList.length;
                                //     i++) {
                                //   YouTubeServices()
                                //       .formatVideo(
                                //     video: searchedList[i],
                                //     quality: Hive.box(AppHiveConstants.settings)
                                //         .get(
                                //           'ytQuality',
                                //           defaultValue: 'Low',
                                //         )
                                //         .toString(),
                                //   )
                                //       .then((songMap) {
                                //     final MediaItem mediaItem =
                                //         MediaItemConverter.mapToMediaItem(
                                //       songMap!,
                                //     );
                                //     addToNowPlaying(
                                //       context: context,
                                //       mediaItem: mediaItem,
                                //       showNotification: false,
                                //     );
                                //   });
                                // }
                              },
                              trailing: YtSongTileTrailingMenu(data: entry),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (!done)
              Center(
                child: SizedBox(
                  height: MediaQuery.of(context).size.width / 2,
                  width: MediaQuery.of(context).size.width / 2,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GradientContainer(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                PlayerTranslationConstants.useHome.tr,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.secondary,
                              ),
                              strokeWidth: 5,
                            ),
                            Text(
                              PlayerTranslationConstants.fetchingStream.tr,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
