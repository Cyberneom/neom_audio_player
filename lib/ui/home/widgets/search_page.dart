import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/data/implementations/app_hive_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_itemlists/itemlists/ui/widgets/app_item_widgets.dart';

import 'package:neom_commons/core/utils/constants/app_hive_constants.dart';import '../../../utils/constants/player_translation_constants.dart';
import '../../widgets/empty_screen.dart';
import '../../widgets/music_search_bar.dart' as searchbar;

class SearchPage extends StatefulWidget {

  final String query;
  final bool fromHome;
  final bool autofocus;

  const SearchPage({
    super.key,
    this.query = '',
    this.fromHome = false,
    this.autofocus = false,
  });

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {

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
  Box? settingsBox;
  List search = [];
  bool showHistory = true;
  bool liveSearch = true;

  final controller = TextEditingController();

  Map<String, AppMediaItem> appMediaItems = <String, AppMediaItem>{};
  Map<String, AppReleaseItem> items = {};

  @override
  void initState() async {
    controller.text = widget.query;
    settingsBox = await AppHiveController().getBox(AppHiveBox.settings.name);
    search = settingsBox?.get(AppHiveConstants.search, defaultValue: [],) as List;
    showHistory = settingsBox?.get(AppHiveConstants.showHistory, defaultValue: true) as bool;
    liveSearch = settingsBox?.get(AppHiveConstants.liveSearch, defaultValue: true) as bool;
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> fetchResults() async {

    if(items.isEmpty) {
      if(AppFlavour.appInUse != AppInUse.e) {
        items = await AppReleaseItemFirestore().retrieveAll();
      } else {
        appMediaItems = await AppMediaItemFirestore().fetchAll();
        appMediaItems.removeWhere((key, value) =>
        !(value.name.toLowerCase().contains(searchParam.toLowerCase()) ||
            value.artist.toLowerCase().contains(searchParam.toLowerCase()))
        );

      }
    }

    for (var item in items.values) {
      if(item.name.toLowerCase().contains(searchParam.toLowerCase()) || (item.ownerName.toLowerCase().contains(searchParam.toLowerCase()))){
        appMediaItems[item.id] = AppMediaItem.fromAppReleaseItem(item);
      }
    }

    ///DEPRECATED appMediaItems.addAll(await SpotifySearch.searchSongs(searchParam));
    
    fetched = true;
    
    setState(() {},);
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
    return SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppColor.main50,
          body: searchbar.MusicSearchBar(
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
                                    settingsBox?.put('search', search,);
                                  });
                                },
                              ),
                              onTap: () {
                                setState(
                                      () {
                                    fetched = false;
                                    searchParam = search.removeAt(index).toString().trim();
                                    search.insert(0, searchParam,);
                                    settingsBox?.put('search', search,);
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
                      if (value.isEmpty) return const SizedBox.shrink();
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
                                              settingsBox?.put('search', search,);
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
    );
  }
}
