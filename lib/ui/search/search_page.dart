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
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_music_player/data/api_services/APIs/saavn_api.dart';
import 'package:neom_music_player/ui/widgets/copy_clipboard.dart';
import 'package:neom_music_player/ui/widgets/download_button.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/widgets/like_button.dart';
import 'package:neom_music_player/ui/widgets/search_bar.dart' as searchbar;
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/ui/widgets/song_tile_trailing_menu.dart';
import 'package:neom_music_player/domain/use_cases/player_service.dart';
import 'package:neom_music_player/ui/widgets/song_list.dart';
import 'package:neom_music_player/ui/search/album_search_page.dart';
import 'package:neom_music_player/ui/search/artist_search_page.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:get/get.dart';

class SearchPage extends StatefulWidget {
  final String query;
  final bool fromHome;
  final bool autofocus;
  const SearchPage({
    super.key,
    required this.query,
    this.fromHome = false,
    this.autofocus = false,
  });

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';
  bool status = false;
  Map searchedData = {};
  Map position = {};
  List sortedKeys = [];
  final ValueNotifier<List<String>> topSearch = ValueNotifier<List<String>>(
    [],
  );
  bool fetched = false;
  bool alertShown = false;
  bool albumFetched = false;
  bool? fromHome;
  List search = Hive.box(AppHiveConstants.settings).get(
    'search',
    defaultValue: [],
  ) as List;
  // bool showHistory =
  //     Hive.box(AppHiveConstants.settings).get('showHistory', defaultValue: true) as bool;
  bool liveSearch =
      Hive.box(AppHiveConstants.settings).get('liveSearch', defaultValue: true) as bool;

  final controller = TextEditingController();

  @override
  void initState() {
    controller.text = widget.query;
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> fetchResults() async {
    // this fetches top 5 songs results
    final Map result = await SaavnAPI().fetchSongSearchResults(
      searchQuery: query == '' ? widget.query : query,
      count: 5,
    );
    final List songResults = result['songs'] as List;
    if (songResults.isNotEmpty) searchedData['Songs'] = songResults;
    fetched = true;
    // this fetches albums, playlists, artists, etc
    final List<Map> value =
        await SaavnAPI().fetchSearchResults(query == '' ? widget.query : query);

    searchedData.addEntries(value[0].entries);
    position = value[1];
    sortedKeys = position.keys.toList()..sort();
    albumFetched = true;
    setState(
      () {},
    );
  }

  Future<void> getTrendingSearch() async {
    topSearch.value = await SaavnAPI().getTopSearches();
  }

  Widget nothingFound(BuildContext context) {
    if (!alertShown) {
      ShowSnackBar().showSnackBar(
        context,
        PlayerTranslationConstants.sorry.tr,
        duration: const Duration(seconds: 7),
        action: SnackBarAction(
          textColor: Theme.of(context).colorScheme.secondary,
          label: PlayerTranslationConstants.useProxy.tr,
          onPressed: () {
            setState(() {
              Hive.box(AppHiveConstants.settings).put('useProxy', true);
              fetched = false;
              status = false;
              searchedData = {};
            });
          },
        ),
      );
      alertShown = true;
    }
    return emptyScreen(
      context,
      0,
      ':( ',
      100,
      PlayerTranslationConstants.sorry.tr,
      60,
      PlayerTranslationConstants.resultsNotFound.tr,
      20,
    );
  }

  @override
  Widget build(BuildContext context) {
    fromHome ??= widget.fromHome;
    if (!status) {
      status = true;
      fromHome! ? getTrendingSearch() : fetchResults();
    }
    return GradientContainer(
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppColor.main75,
          body: searchbar.SearchBar(
            isYt: false,
            controller: controller,
            liveSearch: liveSearch,
            autofocus: widget.autofocus,
            hintText: PlayerTranslationConstants.searchText.tr,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if (fromHome ?? false) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    fromHome = true;
                  });
                }
              },
            ),
            body: (fromHome!)
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10.0,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 100,
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Wrap(
                            children: List<Widget>.generate(
                              search.length,
                              (int index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                  ),
                                  child: GestureDetector(
                                    child: Chip(
                                      label: Text(
                                        search[index].toString(),
                                      ),
                                      labelStyle: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      onDeleted: () {
                                        setState(() {
                                          search.removeAt(index);
                                          Hive.box(AppHiveConstants.settings).put('search', search,);
                                        });
                                      },
                                    ),
                                    onTap: () {
                                      setState(
                                        () {
                                          fetched = false;
                                          query = search
                                              .removeAt(index)
                                              .toString()
                                              .trim();
                                          search.insert(
                                            0,
                                            query,
                                          );
                                          Hive.box(AppHiveConstants.settings).put(
                                            'search',
                                            search,
                                          );
                                          controller.text = query;
                                          controller.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                              offset: query.length,
                                            ),
                                          );
                                          status = false;
                                          fromHome = false;
                                          searchedData = {};
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: topSearch,
                          builder: (
                            BuildContext context,
                            List<String> value,
                            Widget? child,
                          ) {
                            if (value.isEmpty) return const SizedBox();
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        PlayerTranslationConstants.trendingSearch.tr,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Wrap(
                                    children: List<Widget>.generate(
                                      value.length,
                                      (int index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(value[index]),
                                            selectedColor: Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withOpacity(0.2),
                                            labelStyle: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .color,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            selected: false,
                                            onSelected: (bool selected) {
                                              if (selected) {
                                                setState(
                                                  () {
                                                    fetched = false;
                                                    query = value[index].trim();
                                                    controller.text = query;
                                                    controller.selection =
                                                        TextSelection
                                                            .fromPosition(
                                                      TextPosition(
                                                        offset: query.length,
                                                      ),
                                                    );
                                                    status = false;
                                                    fromHome = false;
                                                    searchedData = {};
                                                    if (search.contains(
                                                      query,
                                                    )) {
                                                      search.remove(query);
                                                    }
                                                    search.insert(
                                                      0,
                                                      query,
                                                    );
                                                    if (search.length > 10) {
                                                      search =
                                                          search.sublist(0, 10);
                                                    }
                                                    Hive.box(AppHiveConstants.settings).put(
                                                      'search',
                                                      search,
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : !fetched
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : (searchedData.isEmpty)
                        ? nothingFound(context)
                        : SingleChildScrollView(
                            padding: const EdgeInsets.only(
                              top: 100,
                            ),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: sortedKeys.map(
                                (e) {
                                  final String key = position[e].toString();
                                  final List? value =
                                      searchedData[key] as List?;

                                  if (value == null) {
                                    return const SizedBox();
                                  }
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 25,
                                          top: 10,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              key,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            if (key != 'Top Result')
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                  25,
                                                  0,
                                                  25,
                                                  0,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        if (key == 'Albums' ||
                                                            key ==
                                                                'Playlists' ||
                                                            key == 'Artists') {
                                                          Navigator.push(
                                                            context,
                                                            PageRouteBuilder(
                                                              opaque: false,
                                                              pageBuilder: (
                                                                _,
                                                                __,
                                                                ___,
                                                              ) =>
                                                                  AlbumSearchPage(
                                                                query: query ==
                                                                        ''
                                                                    ? widget
                                                                        .query
                                                                    : query,
                                                                type: key,
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        if (key == 'Songs') {
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
                                                                listItem: {
                                                                  'id': query ==
                                                                          ''
                                                                      ? widget
                                                                          .query
                                                                      : query,
                                                                  'title': key,
                                                                  'type':
                                                                      'songs',
                                                                },
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            PlayerTranslationConstants.viewAll.tr,
                                                            style: TextStyle(
                                                              color: Theme.of(
                                                                context,
                                                              )
                                                                  .textTheme
                                                                  .bodySmall!
                                                                  .color,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons
                                                                .chevron_right_rounded,
                                                            color: Theme.of(
                                                              context,
                                                            )
                                                                .textTheme
                                                                .bodySmall!
                                                                .color,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      ListView.builder(
                                        itemCount: value.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.only(
                                          left: 5,
                                          right: 10,
                                        ),
                                        itemBuilder: (context, index) {
                                          final int count =
                                              value[index]['count'] as int? ??
                                                  0;
                                          String countText =
                                              value[index]['artist'].toString();
                                          count > 1
                                              ? countText =
                                                  '$count ${PlayerTranslationConstants.songs.tr}'
                                              : countText =
                                                  '$count ${PlayerTranslationConstants.song.tr}';
                                          return ListTile(
                                            contentPadding:
                                                const EdgeInsets.only(
                                              left: 15.0,
                                            ),
                                            title: Text(
                                              '${value[index]["title"]}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              key == 'Albums' ||
                                                      (key == 'Top Result' &&
                                                          value[0]['type'] ==
                                                              'album')
                                                  ? '$countText\n${value[index]["subtitle"]}'
                                                  : '${value[index]["subtitle"]}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            isThreeLine: key == 'Albums' ||
                                                (key == 'Top Result' &&
                                                    value[0]['type'] ==
                                                        'album'),
                                            leading: imageCard(
                                              borderRadius: key == 'Artists' ||
                                                      (key == 'Top Result' &&
                                                          value[0]['type'] ==
                                                              'artist')
                                                  ? 50.0
                                                  : 7.0,
                                              placeholderImage: AssetImage(
                                                key == 'Artists' ||
                                                        (key == 'Top Result' &&
                                                            value[0]['type'] ==
                                                                'artist')
                                                    ? AppAssets.musicPlayerArtist
                                                    : key == 'Songs'
                                                        ? AppAssets.musicPlayerCover
                                                        : AppAssets.musicPlayerAlbum,
                                              ),
                                              imageUrl: value[index]['image']
                                                  .toString(),
                                            ),
                                            trailing: key != 'Albums'
                                                ? key == 'Songs'
                                                    ? Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          DownloadButton(
                                                            data: value[index]
                                                                as Map,
                                                            icon: 'download',
                                                          ),
                                                          LikeButton(
                                                            mediaItem: null,
                                                            data: value[index]
                                                                as Map,
                                                          ),
                                                          SongTileTrailingMenu(
                                                            data: value[index]
                                                                as Map,
                                                          ),
                                                        ],
                                                      )
                                                    : null
                                                : AlbumDownloadButton(
                                                    albumName: value[index]
                                                            ['title']
                                                        .toString(),
                                                    albumId: value[index]['id']
                                                        .toString(),
                                                  ),
                                            onLongPress: () {
                                              copyToClipboard(
                                                context: context,
                                                text:
                                                    '${value[index]["title"]}',
                                              );
                                            },
                                            onTap: () {
                                              query = value[index]['title']
                                                  .toString()
                                                  .trim();
                                              List searchQueries =
                                                  Hive.box(AppHiveConstants.settings).get(
                                                'search',
                                                defaultValue: [],
                                              ) as List;
                                              final idx =
                                                  searchQueries.indexOf(query);
                                              if (idx != -1) {
                                                searchQueries.removeAt(idx);
                                              }
                                              searchQueries.insert(0, query);
                                              if (searchQueries.length > 10) {
                                                searchQueries = searchQueries
                                                    .sublist(0, 10);
                                              }
                                              Hive.box(AppHiveConstants.settings)
                                                  .put('search', searchQueries);

                                              if (key == 'Songs') {
                                                PlayerInvoke.init(
                                                  songsList: [value[index]],
                                                  index: 0,
                                                  isOffline: false,
                                                );
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    pageBuilder: (
                                                      _,
                                                      __,
                                                      ___,
                                                    ) =>
                                                        key == 'Artists' ||
                                                                (key == 'Top Result' &&
                                                                    value[0][
                                                                            'type'] ==
                                                                        'artist')
                                                            ? ArtistSearchPage(
                                                                data:
                                                                    value[index]
                                                                        as Map,
                                                              )
                                                            : SongsListPage(
                                                                listItem:
                                                                    value[index]
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
                              ).toList(),
                            ),
                          ),
            onSubmitted: (String submittedQuery) {
              setState(
                () {
                  fetched = false;
                  query = submittedQuery;
                  status = false;
                  fromHome = false;
                  searchedData = {};
                },
              );
            },
            onQueryCleared: () {
              setState(() {
                fromHome = true;
              });
            },
          ),
        ),
      ),
    );
  }
}
