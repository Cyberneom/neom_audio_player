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
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_itemlists/itemlists/data/api_services/spotify/spotify_search.dart';
import 'package:neom_itemlists/itemlists/ui/widgets/app_item_widgets.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/music_search_bar.dart' as searchbar;
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
  String searchParam = '';
  bool status = false;
  // Map searchedData = {};
  Map position = {};
  // List sortedKeys = [];
  final ValueNotifier<List<String>> topSearch = ValueNotifier<List<String>>([],);
  bool fetched = false;
  bool alertShown = false;
  bool albumFetched = false;
  bool? fromHome;
  List search = Hive.box(AppHiveConstants.settings).get(
    'search',
    defaultValue: [],
  ) as List;
  bool showHistory = Hive.box(AppHiveConstants.settings).get('showHistory', defaultValue: true) as bool;
  bool liveSearch = Hive.box(AppHiveConstants.settings).get('liveSearch', defaultValue: true) as bool;

  final controller = TextEditingController();

  Map<String, AppMediaItem> appMediaItems = <String, AppMediaItem>{};
  Map<String, AppReleaseItem> items = {};

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
    // final Map result = await SaavnAPI().fetchSongSearchResults(searchQuery: query == '' ? widget.query : query, count: 5,);

    if(items.isEmpty) {
      items = await AppReleaseItemFirestore().retrieveAll();
    }

    for (var item in items.values) {
      if(item.name.toLowerCase().contains(searchParam) || item.ownerName.toLowerCase().contains(searchParam)){
        appMediaItems[item.id] = AppMediaItem.fromAppReleaseItem(item);
      }
    }

    appMediaItems.addAll(await SpotifySearch().searchSongs(searchParam));
    // final List songResults = result['songs'] as List;
    // if (songResults.isNotEmpty) searchedData['Songs'] = songResults;
    fetched = true;
    // this fetches albums, playlists, artists, etc
    // final List<Map> value = await SaavnAPI().fetchSearchResults(searchParam == '' ? widget.query : searchParam);
    // searchedData.addEntries(value[0].entries);
    // position = value[1];
    // sortedKeys = position.keys.toList()..sort();
    // albumFetched = true;
    setState(
      () {},
    );
  }

  Future<void> getTrendingSearch() async {
    // topSearch.value = await SaavnAPI().getTopSearches();
  }

  Widget nothingFound(BuildContext context) {
    if (!alertShown) {
      alertShown = true;
    }
    return emptyScreen(
      context, 0,
      ':( ', 100,
      PlayerTranslationConstants.sorry.tr, 60,
      PlayerTranslationConstants.resultsNotFound.tr, 20,
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
          body: searchbar.MusicSearchBar(
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
                        const SizedBox(height: 100,),
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
                                        color: Theme.of(context).textTheme.bodyLarge!.color,
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
                                          searchParam = search.removeAt(index).toString().trim();
                                          search.insert(0, searchParam,);
                                          Hive.box(AppHiveConstants.settings).put('search', search,);
                                          controller.text = searchParam;
                                          controller.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                              offset: searchParam.length,
                                            ),
                                          );
                                          status = false;
                                          fromHome = false;
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
                                                    searchParam = value[index].trim();
                                                    controller.text = searchParam;
                                                    controller.selection =
                                                        TextSelection
                                                            .fromPosition(
                                                      TextPosition(
                                                        offset: searchParam.length,
                                                      ),
                                                    );
                                                    status = false;
                                                    fromHome = false;
                                                    if (search.contains(
                                                      searchParam,
                                                    )) {
                                                      search.remove(searchParam);
                                                    }
                                                    search.insert(
                                                      0,
                                                      searchParam,
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
                    : appMediaItems.isEmpty
                        ? nothingFound(context)
                        : SingleChildScrollView(
                            padding: const EdgeInsets.only(
                              top: 100,
                            ),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 25, top: 10,),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(AppTranslationConstants.releaseItem.tr,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                            // if (item.e.name != 'Top Result')
                                            //   Padding(
                                            //     padding: const EdgeInsets.fromLTRB(25, 0, 25, 0,),
                                            //     child: Row(
                                            //       mainAxisAlignment:
                                            //           MainAxisAlignment.end,
                                            //       children: [
                                            //         GestureDetector(
                                            //           onTap: () {
                                            //             if (e.type ==  MediaItemType.song) {
                                            //               Navigator.push(
                                            //                 context,
                                            //                 PageRouteBuilder(
                                            //                   opaque: false,
                                            //                   pageBuilder: (_, __, ___,) => SongsListPage(itemlist: Itemlist()),
                                            //                 ),
                                            //               );
                                            //             }
                                            //           },
                                            //           child: Row(
                                            //             children: [
                                            //               Text(
                                            //                 PlayerTranslationConstants.viewAll.tr,
                                            //                 style: TextStyle(
                                            //                   color: Theme.of(context,).textTheme.bodySmall!.color,
                                            //                   fontWeight: FontWeight.w800,
                                            //                 ),
                                            //               ),
                                            //               Icon(Icons.chevron_right_rounded,
                                            //                 color: Theme.of(context,).textTheme.bodySmall!.color,
                                            //               ),
                                            //             ],
                                            //           ),
                                            //         ),
                                            //       ],
                                            //     ),
                                            //   ),
                                    ],
                                  ),
                                ),
                                ListView.builder(
                                  itemCount: appMediaItems.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.only(left: 5, right: 10,),
                                  itemBuilder: (context, index) {
                                    AppMediaItem item = appMediaItems.values.elementAt(index);
                                    // final int count = item.likes;
                                    // String countText = item.artist;
                                    // countText = count > 1 ? '$count ${PlayerTranslationConstants.songs.tr}'
                                    //     : '$count ${PlayerTranslationConstants.song.tr}';
                                    return createCoolMediaItemTile(context, item, query: searchParam);
                                    },
                                ),
                              ],
                            ),
            ),
            onSubmitted: (String submittedQuery) {
              setState(
                () {
                  fetched = false;
                  searchParam = submittedQuery;
                  status = false;
                  fromHome = false;
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
