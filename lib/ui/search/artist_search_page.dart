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

import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_music_player/data/api_services/APIs/api.dart';
import 'package:neom_music_player/ui/widgets/artist_like_button.dart';
import 'package:neom_music_player/ui/widgets/bouncy_sliver_scroll_view.dart';
import 'package:neom_music_player/ui/widgets/copy_clipboard.dart';
import 'package:neom_music_player/ui/widgets/download_button.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/horizontal_albumlist.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/widgets/like_button.dart';
import 'package:neom_music_player/ui/widgets/playlist_popupmenu.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/ui/widgets/song_tile_trailing_menu.dart';
import 'package:neom_music_player/domain/use_cases/player_service.dart';
import 'package:neom_music_player/domain/entities/url_image_generator.dart';
import 'package:neom_music_player/ui/widgets/song_list.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';

class ArtistSearchPage extends StatefulWidget {
  final Map data;

  const ArtistSearchPage({
    super.key,
    required this.data,
  });

  @override
  _ArtistSearchPageState createState() => _ArtistSearchPageState();
}

class _ArtistSearchPageState extends State<ArtistSearchPage> {
  bool status = false;
  String category = '';
  String sortOrder = '';
  Map<String, List> data = {};
  bool fetched = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!status) {
      status = true;
      SaavnAPI()
          .fetchArtistSongs(
        artistToken: widget.data['artistToken'].toString(),
        category: category,
        sortOrder: sortOrder,
      )
          .then((value) {
        setState(() {
          data = value;
          fetched = true;
        });
      });
    }
    return GradientContainer(
      child: Scaffold(
        backgroundColor: AppColor.main75,
        body: !fetched
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : data.isEmpty
                ? emptyScreen(
                    context,
                    0,
                    ':( ',
                    100,
                    PlayerTranslationConstants.sorry.tr,
                    60,
                    PlayerTranslationConstants.resultsNotFound.tr,
                    20,
                  )
                : BouncyImageSliverScrollView(
                    scrollController: _scrollController,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        tooltip: PlayerTranslationConstants.share.tr,
                        onPressed: () {
                          Share.share(
                            widget.data['perma_url'].toString(),
                          );
                        },
                      ),
                      ArtistLikeButton(
                        data: widget.data,
                        size: 27.0,
                      ),
                      if (data['Top Songs'] != null)
                        PlaylistPopupMenu(
                          data: data['Top Songs']!,
                          title: widget.data['title']?.toString() ?? 'Songs',
                        ),
                    ],
                    title: widget.data['title']?.toString() ??
                        PlayerTranslationConstants.songs.tr,
                    placeholderImage: AppAssets.musicPlayerArtist,
                    imageUrl: UrlImageGetter([widget.data['image'].toString()])
                        .mediumQuality,
                    sliverList: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      PlayerInvoke.init(
                                        songsList: data['Top Songs']!,
                                        index: 0,
                                        isOffline: false,
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        top: 10,
                                        bottom: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 5.0,
                                            offset: Offset(0.0, 3.0),
                                          )
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.play_arrow_rounded,
                                              color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary ==
                                                      Colors.white
                                                  ? Colors.black
                                                  : Colors.white,
                                              size: 26.0,
                                            ),
                                            const SizedBox(width: 5.0),
                                            Text(
                                              PlayerTranslationConstants.play.tr,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18.0,
                                                color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary ==
                                                        Colors.white
                                                    ? Colors.black
                                                    : Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      ShowSnackBar().showSnackBar(
                                        context,
                                        PlayerTranslationConstants.connectingRadio.tr,
                                        duration: const Duration(
                                          seconds: 2,
                                        ),
                                      );
                                      SaavnAPI().createRadio(
                                        names: [
                                          widget.data['title']?.toString() ??
                                              '',
                                        ],
                                        language: widget.data['language']
                                                ?.toString() ??
                                            'hindi',
                                        stationType: 'artist',
                                      ).then((value) {
                                        if (value != null) {
                                          SaavnAPI()
                                              .getRadioSongs(
                                            stationId: value,
                                          )
                                              .then((value) {
                                            PlayerInvoke.init(
                                              songsList: value,
                                              index: 0,
                                              isOffline: false,
                                            );
                                          });
                                        }
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        border: Border.all(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.podcasts_rounded,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                              size: 26.0,
                                            ),
                                            const SizedBox(width: 5.0),
                                            Text(
                                              PlayerTranslationConstants.radio.tr,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18.0,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Container(
                                  margin: const EdgeInsets.only(
                                    top: 10,
                                    bottom: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100.0),
                                    border: Border.all(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: GestureDetector(
                                      child: Icon(
                                        Icons.shuffle_rounded,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                        size: 24.0,
                                      ),
                                      onTap: () {
                                        PlayerInvoke.init(
                                          songsList: data['Top Songs']!,
                                          index: 0,
                                          isOffline: false,
                                          shuffle: true,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...data.entries.map(
                            (entry) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 25,
                                      top: 15,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (entry.key ==
                                            'Top Songs') ...<Widget>[
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              ChoiceChip(
                                                label: Text(
                                                  PlayerTranslationConstants.popularity.tr,
                                                ),
                                                selectedColor: Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                    .withOpacity(0.2),
                                                labelStyle: TextStyle(
                                                  color: category == ''
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .secondary
                                                      : Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge!
                                                          .color,
                                                  fontWeight: category == ''
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                                selected: category == '',
                                                onSelected: (bool selected) {
                                                  if (selected) {
                                                    category = '';
                                                    sortOrder = '';
                                                    status = false;
                                                    setState(() {});
                                                  }
                                                },
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              ChoiceChip(
                                                label: Text(
                                                  PlayerTranslationConstants.date.tr,
                                                ),
                                                selectedColor: Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                    .withOpacity(0.2),
                                                labelStyle: TextStyle(
                                                  color: category == 'latest'
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .secondary
                                                      : Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge!
                                                          .color,
                                                  fontWeight:
                                                      category == 'latest'
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                ),
                                                selected: category == 'latest',
                                                onSelected: (bool selected) {
                                                  if (selected) {
                                                    category = 'latest';
                                                    sortOrder = 'desc';
                                                    status = false;
                                                    setState(() {});
                                                  }
                                                },
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              ChoiceChip(
                                                label: Text(
                                                  PlayerTranslationConstants.alphabetical.tr,
                                                ),
                                                selectedColor: Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                    .withOpacity(0.2),
                                                labelStyle: TextStyle(
                                                  color:
                                                      category == 'alphabetical'
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                          : Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge!
                                                              .color,
                                                  fontWeight:
                                                      category == 'alphabetical'
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                ),
                                                selected:
                                                    category == 'alphabetical',
                                                onSelected: (bool selected) {
                                                  if (selected) {
                                                    category = 'alphabetical';
                                                    sortOrder = 'asc';
                                                    status = false;
                                                    setState(() {});
                                                  }
                                                },
                                              ),
                                              const Spacer(),
                                              // removed as it wasn't useful
                                              // if (data['Top Songs'] !=
                                              //     null)
                                              // MultiDownloadButton(
                                              //   data:
                                              //       data['Top Songs']!,
                                              //   playlistName: widget
                                              //           .data['title']
                                              //           ?.toString() ??
                                              //       'Songs',
                                              // ),
                                              // const SizedBox(
                                              //   width: 5,
                                              // ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (entry.key != 'Top Songs')
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        5,
                                        10,
                                        5,
                                        0,
                                      ),
                                      child: HorizontalAlbumsList(
                                        songsList: entry.value,
                                        onTap: (int idx) {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              opaque: false,
                                              pageBuilder: (
                                                _,
                                                __,
                                                ___,
                                              ) =>
                                                  entry.key == 'Related Artists'
                                                      ? ArtistSearchPage(
                                                          data: entry.value[idx]
                                                              as Map,
                                                        )
                                                      : SongsListPage(
                                                          listItem:
                                                              entry.value[idx]
                                                                  as Map,
                                                        ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  else
                                    ListView.builder(
                                      itemCount: entry.value.length,
                                      padding: const EdgeInsets.fromLTRB(
                                        5,
                                        5,
                                        5,
                                        0,
                                      ),
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          contentPadding: const EdgeInsets.only(
                                            left: 15.0,
                                          ),
                                          title: Text(
                                            '${entry.value[index]["title"]}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          onLongPress: () {
                                            copyToClipboard(
                                              context: context,
                                              text:
                                                  '${entry.value[index]["title"]}',
                                            );
                                          },
                                          subtitle: Text(
                                            '${entry.value[index]["subtitle"]}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          leading: imageCard(
                                            placeholderImage: AssetImage(
                                              (entry.key == 'Top Songs' ||
                                                      entry.key ==
                                                          'Latest Release')
                                                  ? AppAssets.musicPlayerCover
                                                  : AppAssets.musicPlayerAlbum,
                                            ),
                                            imageUrl: entry.value[index]
                                                    ['image']
                                                .toString(),
                                          ),
                                          trailing: (entry.key == 'Top Songs' ||
                                                  entry.key ==
                                                      'Latest Release' ||
                                                  entry.key == 'Singles')
                                              ? Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    DownloadButton(
                                                      data: entry.value[index]
                                                          as Map,
                                                      icon: 'download',
                                                    ),
                                                    LikeButton(
                                                      data: entry.value[index]
                                                          as Map,
                                                      mediaItem: null,
                                                    ),
                                                    SongTileTrailingMenu(
                                                      data: entry.value[index]
                                                          as Map,
                                                    ),
                                                  ],
                                                )
                                              : null,
                                          onTap: () {
                                            if (entry.key == 'Top Songs' ||
                                                entry.key == 'Latest Release' ||
                                                entry.key == 'Singles') {
                                              PlayerInvoke.init(
                                                songsList: entry.value,
                                                index: index,
                                                isOffline: false,
                                              );
                                            }
                                            if (entry.key != 'Top Songs' &&
                                                entry.key != 'Latest Release' &&
                                                entry.key != 'Singles') {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  opaque: false,
                                                  pageBuilder: (
                                                    _,
                                                    __,
                                                    ___,
                                                  ) =>
                                                      SongsListPage(
                                                    listItem: entry.value[index]
                                                        as Map,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
