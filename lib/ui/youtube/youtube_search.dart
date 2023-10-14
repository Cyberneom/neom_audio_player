import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_music_player/domain/use_cases/ytmusic/youtube_services.dart';
import 'package:neom_music_player/domain/use_cases/ytmusic/yt_music.dart';
import 'package:neom_music_player/neom_player_invoker.dart';
import 'package:neom_music_player/ui/YouTube/youtube_artist.dart';
import 'package:neom_music_player/ui/YouTube/youtube_playlist.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/widgets/music_search_bar.dart' as searchbar;
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/ui/widgets/song_list_view.dart';
import 'package:neom_music_player/ui/widgets/song_tile_trailing_menu.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:neom_music_player/utils/enums/youtube_item_type.dart';

class YouTubeSearchPage extends StatefulWidget {
  final String query;
  final bool autofocus;
  const YouTubeSearchPage({
    super.key,
    required this.query,
    this.autofocus = false,
  });
  @override
  _YouTubeSearchPageState createState() => _YouTubeSearchPageState();
}

class _YouTubeSearchPageState extends State<YouTubeSearchPage> {

  String query = '';
  bool status = false;
  List<Map> searchedList = [];
  bool fetched = false;
  bool done = true;

  //TODO Get Values from AppHiveController
  bool liveSearch = Hive.box(AppHiveConstants.settings).get('liveSearch', defaultValue: true) as bool;
  List searchHistory = Hive.box(AppHiveConstants.settings).get('search', defaultValue: []) as List;
  bool searchYtMusic = Hive.box(AppHiveConstants.settings).get('searchYtMusic', defaultValue: true) as bool;
  bool showHistory = Hive.box(AppHiveConstants.settings).get('showHistory', defaultValue: true) as bool;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.query;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool rotated = MediaQuery.of(context).size.height < MediaQuery.of(context).size.width;
    double boxSize = !rotated
        ? MediaQuery.of(context).size.width / 2
        : MediaQuery.of(context).size.height / 2.5;
    if (boxSize > 250) boxSize = 250;
    if (!status) {
      status = true;
      if (query.isEmpty && widget.query.isEmpty) {
        fetched = true;
      } else {
        if (searchYtMusic) {
          AppUtilities.logger.i('calling yt music search');
          YtMusicService().search(query == '' ? widget.query : query)
              .then((value) {
            setState(() {
              searchedList = value;
              fetched = true;
            });
          });
        } else {
          AppUtilities.logger.i('calling youtube search');
          YouTubeServices()
              .fetchSearchResults(query == '' ? widget.query : query)
              .then((value) {
            setState(() {
              searchedList = value;
              fetched = true;
            });
          });
        }
      }
    }
    return GradientContainer(
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppColor.main75,
          body: searchbar.MusicSearchBar(
            isYt: true,
            controller: _controller,
            liveSearch: true,
            autofocus: widget.autofocus,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            hintText: PlayerTranslationConstants.searchYt.tr,
            onQueryChanged: (changedQuery) async {
              return YouTubeServices().getSearchSuggestions(query: changedQuery);
            },
            onSubmitted: (submittedQuery) async {
              setState(() {
                fetched = false;
                query = submittedQuery;
                _controller.text = submittedQuery;
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(
                    offset: query.length,
                  ),
                );
                status = false;
                searchedList = [];
              });
            },
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 70,
                    left: 20,
                  ),
                  child: (query.isEmpty && widget.query.isEmpty)
                      ? null
                      : Row(
                          children: [
                            ChoiceChip(
                              label: const Text('YT Music'),
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: searchYtMusic
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .color,
                                fontWeight: searchYtMusic
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              selected: searchYtMusic,
                              onSelected: (bool selected) {
                                if (selected) {
                                  searchYtMusic = true;
                                  fetched = false;
                                  status = false;
                                  Hive.box(AppHiveConstants.settings).put(
                                    'searchYtMusic',
                                    searchYtMusic,
                                  );
                                  setState(() {});
                                }
                              },
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            ChoiceChip(
                              label: Text(
                                PlayerTranslationConstants.youTube.tr,
                              ),
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: !searchYtMusic
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .color,
                                fontWeight: !searchYtMusic
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              selected: !searchYtMusic,
                              onSelected: (bool selected) {
                                if (selected) {
                                  searchYtMusic = false;
                                  fetched = false;
                                  status = false;
                                  Hive.box(AppHiveConstants.settings).put(
                                    'searchYtMusic',
                                    searchYtMusic,
                                  );
                                  setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                ),
                Expanded(
                  child: (!fetched)
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : (query.isEmpty && widget.query.isEmpty)
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Wrap(
                                      children: List<Widget>.generate(
                                        searchHistory.length,
                                        (int index) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5.0,
                                            ),
                                            child: GestureDetector(
                                              child: Chip(
                                                label: Text(
                                                  searchHistory[index]
                                                      .toString(),
                                                ),
                                                labelStyle: TextStyle(
                                                  color: Theme.of(context).textTheme.bodyLarge!.color,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                                onDeleted: () {
                                                  setState(() {
                                                    searchHistory.removeAt(index);
                                                    Hive.box(AppHiveConstants.settings).put('search', searchHistory,
                                                    );
                                                  });
                                                },
                                              ),
                                              onTap: () {
                                                setState(() {
                                                    fetched = false;
                                                    query = searchHistory.removeAt(index).toString().trim();
                                                    searchHistory.insert(0, query,);
                                                    Hive.box(AppHiveConstants.settings).put('search', searchHistory,);
                                                    _controller.text = query;
                                                    status = false;
                                                    fetched = false;
                                                  },
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : searchedList.isEmpty
                              ? emptyScreen(context,
                    0, ':( ',
                    100, PlayerTranslationConstants.sorry.tr,
                    60, PlayerTranslationConstants.resultsNotFound.tr, 20,)
                      : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                        ),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: searchedList.map(
                                (Map section) {
                                  if (section['items'] == null) {
                                    return const SizedBox();
                                  }
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 15, top: 20, bottom: 5,),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(section['title'].toString(),
                                              style: TextStyle(color: Theme.of(context,).colorScheme.secondary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            if (['songs'].contains(section['title'].toString().toLowerCase(),))
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  GestureDetector(
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          PlayerTranslationConstants.viewAll.tr,
                                                          style: TextStyle(color: Theme.of(context,).textTheme.bodySmall!.color,
                                                            fontWeight: FontWeight.w800,
                                                          ),
                                                        ),
                                                        Icon(Icons.chevron_right_rounded,
                                                          color: Theme.of(context,).textTheme.bodySmall!.color,
                                                        ),
                                                      ],
                                                    ),
                                                    onTap: () {
                                                      Navigator.push(context,
                                                        PageRouteBuilder(
                                                          opaque: false,
                                                          pageBuilder: (_, __, ___,) => SongsListViewPage(
                                                            onTap: (index, listItems,) {},
                                                            title: AppTranslationConstants.searchResults.tr,
                                                            subtitle: '\n${AppTranslationConstants.type.tr}: ${section['title'].toString().camelCase!.tr}\n${AppTranslationConstants.searchedText.tr}: "${(query == '' ? widget.query : query)?.capitalizeAllWordsFirstLetter() ?? ""}"',
                                                            listItemsTitle: section['title'].toString(),
                                                            loadFunction: () {
                                                              return YtMusicService().searchSongs(query == '' ? widget.query : query,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                      ListView.builder(
                                        physics: const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: (section['items'] as List).length,
                                        itemBuilder: (context, idx) {
                                          final itemType = section['items'][idx]['type']?.toString() ?? 'Video';
                                          YoutubeItemType ytItemType = YoutubeItemType.song;
                                          ytItemType = EnumToString.fromString(YoutubeItemType.values, itemType) ?? YoutubeItemType.song;
                                          return ListTile(
                                            title: Text(
                                              section['items'][idx]['title'].toString(),
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            subtitle: Text(
                                              section['items'][idx]['subtitle'].toString(),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            contentPadding: const EdgeInsets.only(left: 15.0,),
                                            leading: imageCard(
                                              borderRadius: itemType == 'Artist' ? 50.0 : 7.0,
                                              imageUrl: section['items'][idx]['image'].toString(),
                                            ),
                                            trailing: (itemType == 'Song' || itemType == 'Video')
                                                ? YtSongTileTrailingMenu(
                                              data: section['items']
                                              [idx] as Map,) : null,
                                            onTap: () async {
                                              AppUtilities.logger.d('Tapping Search Result');
                                              switch(ytItemType) {
                                                case YoutubeItemType.artist:
                                                  Navigator.push(context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          YouTubeArtist(artistId: section['items'][idx]['id'].toString(),
                                                          ),
                                                    ),
                                                  );
                                                case YoutubeItemType.playlist:
                                                  Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) =>
                                                        YouTubePlaylist(playlistId: section['items'][idx]['id'].toString(),
                                                          type: 'playlist',
                                                        ),
                                                    ),
                                                  );
                                                case YoutubeItemType.song:
                                                  setState(() {
                                                    done = false;
                                                  });
                                                  final AppMediaItem? response = await YouTubeServices().formatVideoFromId(
                                                    id: section['items'][idx]['id'].toString(),
                                                    data: section['items'][idx] as Map,
                                                  );
                                                  final Map response2 = await YtMusicService().getSongData(
                                                    videoId: section['items'][idx]['id'].toString(),
                                                  );
                                                  if (response != null && response2['image'] != null) {
                                                    response.imgUrl = response2['image'].toString();
                                                  }
                                                  setState(() {
                                                    done = true;
                                                  });

                                                  if (response != null) {
                                                    NeomPlayerInvoker.init(appMediaItems: [response],
                                                      index: 0, isOffline: false,
                                                    );
                                                  }
                                                  if (response == null) {
                                                    ShowSnackBar().showSnackBar(context, PlayerTranslationConstants.ytLiveAlert.tr,);
                                                  }
                                                case YoutubeItemType.video:
                                                  setState(() {
                                                    done = false;
                                                  });
                                                  final AppMediaItem? response = await YouTubeServices().formatVideoFromId(
                                                    id: section['items'][idx]['id'].toString(),
                                                    data: section['items'][idx] as Map,
                                                  );

                                                  setState(() {
                                                    done = true;
                                                  });

                                                  if (response != null) {
                                                    NeomPlayerInvoker.init(
                                                      appMediaItems: [response],
                                                      index: 0, isOffline: false,
                                                    );
                                                  }
                                                  if (response == null) {
                                                    ShowSnackBar().showSnackBar(context, PlayerTranslationConstants.ytLiveAlert.tr,);
                                                  }
                                                case YoutubeItemType.album:
                                                  Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) =>
                                                        YouTubePlaylist(playlistId: section['items'][idx]['id'].toString(),
                                                          type: 'album',),
                                                    ),
                                                  );
                                                case YoutubeItemType.single:
                                                  Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) =>
                                                        YouTubePlaylist(playlistId: section['items'][idx]['id'].toString(),
                                                          type: 'album',),
                                                    ),
                                                  );
                                                default:
                                                  break;
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
                      if (!done)
                        Center(
                          child: SizedBox.square(
                            dimension: boxSize,
                            child: Card(
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  15,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: GradientContainer(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceEvenly,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor:
                                        AlwaysStoppedAnimation<
                                            Color>(
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
