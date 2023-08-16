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

final ValueNotifier<bool> selectMode = ValueNotifier<bool>(false);
final Set<String> selectedItems = <String>{};

class LikedSongs extends StatefulWidget {
  final String playlistName;
  final String? showName;
  final bool fromPlaylist;
  final List<AppMediaItem>? appMediaSongs;
  const LikedSongs({
    super.key,
    required this.playlistName,
    this.showName,
    this.fromPlaylist = false,
    this.appMediaSongs,
  });
  @override
  _LikedSongsState createState() => _LikedSongsState();
}

class _LikedSongsState extends State<LikedSongs>
    with SingleTickerProviderStateMixin {
  Box? likedBox;
  bool added = false;
  // String? tempPath = Hive.box(AppHiveConstants.settings).get('tempDirPath')?.toString();
  List<AppMediaItem> _appMediaSongs = [];
  final Map<String, List<Map>> _albums = {};
  final Map<String, List<Map>> _artists = {};
  final Map<String, List<Map>> _genres = {};
  List _sortedAlbumKeysList = [];
  List _sortedArtistKeysList = [];
  List _sortedGenreKeysList = [];
  TabController? _tcontroller;
  // int currentIndex = 0;
  int sortValue = Hive.box(AppHiveConstants.settings).get('sortValue', defaultValue: 1) as int;
  int orderValue = Hive.box(AppHiveConstants.settings).get('orderValue', defaultValue: 1) as int;
  int albumSortValue =   Hive.box(AppHiveConstants.settings).get('albumSortValue', defaultValue: 2) as int;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showShuffle = ValueNotifier<bool>(true);
  int _currentTabIndex = 0;

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
  }

  @override
  void initState() {
    _tcontroller = TabController(length: 4, vsync: this);
    _tcontroller!.addListener(() {
      if ((_tcontroller!.previousIndex != 0 && _tcontroller!.index == 0) ||
          (_tcontroller!.previousIndex == 0)) {
        setState(() => _currentTabIndex = _tcontroller!.index);
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        _showShuffle.value = false;
      } else {
        _showShuffle.value = true;
      }
    });
    // if (tempPath == null) {
    //   getTemporaryDirectory().then((value) {
    //     Hive.box(AppHiveConstants.settings).put('tempDirPath', value.path);
    //   });
    // }
    // _tcontroller!.addListener(changeTitle);
    getLiked();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tcontroller!.dispose();
    _scrollController.dispose();
  }

  // void changeTitle() {
  //   setState(() {
  //     currentIndex = _tcontroller!.index;
  //   });
  // }

  void getLiked() {
    likedBox = Hive.box(widget.playlistName);
    if (widget.fromPlaylist) {
      _appMediaSongs = widget.appMediaSongs!;
    } else {
      _appMediaSongs = likedBox?.values.map((element) {
        return AppMediaItem.fromMap(element);
      }).toList() ?? [];
      songs_count.addSongsCount(
        widget.playlistName,
        _appMediaSongs.length,
        _appMediaSongs.length >= 4
            ? _appMediaSongs.sublist(0, 4)
            : _appMediaSongs.sublist(0, _appMediaSongs.length),
      );
    }
    setArtistAlbum();
  }

  void setArtistAlbum() {
    // for (final element in _appMediaItems) {
    //   if (_albums.containsKey(element.album)) {
    //     final List<Map> tempAlbum = _albums[element.album]!;
    //     tempAlbum.add(element as Map);
    //     _albums.addEntries([MapEntry(element.album.toString(), tempAlbum)]);
    //   } else {
    //     _albums.addEntries([
    //       MapEntry(element.album.toString(), [element as Map])
    //     ]);
    //   }
    //
    //   element.artist.toString().split(', ').forEach((singleArtist) {
    //     if (_artists.containsKey(singleArtist)) {
    //       final List<Map> tempArtist = _artists[singleArtist]!;
    //       tempArtist.add(element);
    //       _artists.addEntries([MapEntry(singleArtist, tempArtist)]);
    //     } else {
    //       _artists.addEntries([
    //         MapEntry(singleArtist, [element])
    //       ]);
    //     }
    //   });
    //
    //   if (_genres.containsKey(element.genre)) {
    //     final List<Map> tempGenre = _genres[element.genre]!;
    //     tempGenre.add(element);
    //     _genres.addEntries([MapEntry(element.genre.toString(), tempGenre)]);
    //   } else {
    //     _genres.addEntries([
    //       MapEntry(element.genre.toString(), [element])
    //     ]);
    //   }
    // }
    //
    // sortSongs(sortVal: sortValue, order: orderValue);
    //
    // _sortedAlbumKeysList = _albums.keys.toList();
    // _sortedArtistKeysList = _artists.keys.toList();
    // _sortedGenreKeysList = _genres.keys.toList();
    //
    // sortAlbums();
    //
    // added = true;
    // setState(() {});
  }

  void sortAlbums() {
    if (albumSortValue == 0) {
      _sortedAlbumKeysList.sort(
        (a, b) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedArtistKeysList.sort(
        (a, b) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedGenreKeysList.sort(
        (a, b) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
    }
    if (albumSortValue == 1) {
      _sortedAlbumKeysList.sort(
        (b, a) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedArtistKeysList.sort(
        (b, a) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedGenreKeysList.sort(
        (b, a) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
    }
    if (albumSortValue == 2) {
      _sortedAlbumKeysList
          .sort((b, a) => _albums[a]!.length.compareTo(_albums[b]!.length));
      _sortedArtistKeysList
          .sort((b, a) => _artists[a]!.length.compareTo(_artists[b]!.length));
      _sortedGenreKeysList
          .sort((b, a) => _genres[a]!.length.compareTo(_genres[b]!.length));
    }
    if (albumSortValue == 3) {
      _sortedAlbumKeysList
          .sort((a, b) => _albums[a]!.length.compareTo(_albums[b]!.length));
      _sortedArtistKeysList
          .sort((a, b) => _artists[a]!.length.compareTo(_artists[b]!.length));
      _sortedGenreKeysList
          .sort((a, b) => _genres[a]!.length.compareTo(_genres[b]!.length));
    }
    if (albumSortValue == 4) {
      _sortedAlbumKeysList.shuffle();
      _sortedArtistKeysList.shuffle();
      _sortedGenreKeysList.shuffle();
    }
  }

  void deleteLiked(AppMediaItem song) {
    setState(() {
      likedBox!.delete(song.id);
      if (_albums[song.album]!.length == 1) {
        _sortedAlbumKeysList.remove(song.album);
      }
      _albums[song.album]!.remove(song);

      song.artist.toString().split(', ').forEach((singleArtist) {
        if (_artists[singleArtist]!.length == 1) {
          _sortedArtistKeysList.remove(singleArtist);
        }
        _artists[singleArtist]!.remove(song);
      });

      if (_genres[song.genre]!.length == 1) {
        _sortedGenreKeysList.remove(song.genre);
      }
      _genres[song.genre]!.remove(song);

      _appMediaSongs.remove(song);
      songs_count.addSongsCount(
        widget.playlistName,
        _appMediaSongs.length,
        _appMediaSongs.length >= 4
            ? _appMediaSongs.sublist(0, 4)
            : _appMediaSongs.sublist(0, _appMediaSongs.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: AppColor.main75,
          appBar: AppBar(
            title: Text(
              widget.showName == null
                  ? widget.playlistName[0].toUpperCase() +
                      widget.playlistName.substring(1)
                  : widget.showName![0].toUpperCase() +
                      widget.showName!.substring(1),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: TabBar(
              controller: _tcontroller,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(
                  text: PlayerTranslationConstants.songs.tr,
                ),
                Tab(
                  text: PlayerTranslationConstants.albums.tr,
                ),
                Tab(
                  text: PlayerTranslationConstants.artists.tr,
                ),
                Tab(
                  text: PlayerTranslationConstants.genres.tr,
                ),
              ],
            ),
            actions: [
              ValueListenableBuilder(
                valueListenable: selectMode,
                child: Row(
                  children: <Widget>[
                    if (_appMediaSongs.isNotEmpty)
                      MultiDownloadButton(
                        data: _appMediaSongs,
                        playlistName: widget.showName == null
                            ? widget.playlistName[0].toUpperCase() +
                                widget.playlistName.substring(1)
                            : widget.showName![0].toUpperCase() +
                                widget.showName!.substring(1),
                      ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.search),
                      tooltip: PlayerTranslationConstants.search.tr,
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: DownloadsSearch(data: _appMediaSongs),
                        );
                      },
                    ),
                    if (_currentTabIndex == 0)
                      PopupMenuButton(
                        icon: const Icon(Icons.sort_rounded),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        ),
                        onSelected:
                            // (currentIndex == 0) ?
                            (int value) {
                          if (value < 5) {
                            sortValue = value;
                            Hive.box(AppHiveConstants.settings).put('sortValue', value);
                          } else {
                            orderValue = value - 5;
                            Hive.box(AppHiveConstants.settings).put('orderValue', orderValue);
                          }
                          _appMediaSongs = NeomAudioUtilities.sortSongs(
                            _appMediaSongs,
                            sortVal: sortValue,
                            order: orderValue,
                          );
                          setState(() {});
                        },
                        // : (int value) {
                        //     albumSortValue = value;
                        //     Hive.box(AppHiveConstants.settings).put('albumSortValue', value);
                        //     sortAlbums();
                        //     setState(() {});
                        //   },
                        itemBuilder:
                            // (currentIndex == 0)
                            // ?
                            (context) {
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                    value: sortTypes.length +
                                        orderTypes.indexOf(e),
                                    child: Row(
                                      children: [
                                        if (orderValue == orderTypes.indexOf(e))
                                          Icon(
                                            Icons.check_rounded,
                                            color:
                                                Theme.of(context).brightness ==
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
                ),
                builder: (
                  BuildContext context,
                  bool showValue,
                  Widget? child,
                ) {
                  return showValue
                      ? Row(
                          children: [
                            MultiDownloadButton(
                              data: _appMediaSongs
                                  .where(
                                    (element) =>
                                        selectedItems.contains(element.id),
                                  )
                                  .toList(),
                              playlistName: widget.showName == null
                                  ? widget.playlistName[0].toUpperCase() +
                                      widget.playlistName.substring(1)
                                  : widget.showName![0].toUpperCase() +
                                      widget.showName!.substring(1),
                            ),
                            IconButton(
                              onPressed: () {
                                selectedItems.clear();
                                selectMode.value = false;
                              },
                              icon: const Icon(Icons.clear_rounded),
                            )
                          ],
                        )
                      : child!;
                },
              ),
            ],
          ),
          body: !added
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : TabBarView(
                  physics: const CustomPhysics(),
                  controller: _tcontroller,
                  children: [
                    SongsTab(
                      appMediaItems: _appMediaSongs,
                      onDelete: (AppMediaItem item) {
                        deleteLiked(item);
                      },
                      playlistName: widget.playlistName,
                      scrollController: _scrollController,
                    ),
                    AlbumsTab(
                      albums: _albums,
                      type: 'album',
                      offline: false,
                      playlistName: widget.playlistName,
                      sortedAlbumKeysList: _sortedAlbumKeysList,
                    ),
                    AlbumsTab(
                      albums: _artists,
                      type: 'artist',
                      offline: false,
                      playlistName: widget.playlistName,
                      sortedAlbumKeysList: _sortedArtistKeysList,
                    ),
                    AlbumsTab(
                      albums: _genres,
                      type: 'genre',
                      offline: false,
                      playlistName: widget.playlistName,
                      sortedAlbumKeysList: _sortedGenreKeysList,
                    ),
                  ],
                ),
          floatingActionButton: ValueListenableBuilder(
            valueListenable: _showShuffle,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).cardColor,
              child: Icon(
                Icons.shuffle_rounded,
                color: Colors.white,
                size: 24.0,
              ),
              onPressed: () {
                if (_appMediaSongs.isNotEmpty) {
                  NeomPlayerInvoke.init(
                    appMediaItems: _appMediaSongs,
                    index: 0,
                    isOffline: false,
                    recommend: false,
                    shuffle: true,
                  );
                }
              },
            ),
            builder: (
              BuildContext context,
              bool showShuffle,
              Widget? child,
            ) {
              return AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: showShuffle ? Offset.zero : const Offset(0, 2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: showShuffle ? 1 : 0,
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SongsTab extends StatefulWidget {
  final List<AppMediaItem> appMediaItems;
  final String playlistName;
  final Function(AppMediaItem item) onDelete;
  final ScrollController scrollController;
  const SongsTab({
    super.key,
    required this.appMediaItems,
    required this.onDelete,
    required this.playlistName,
    required this.scrollController,
  });

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return (widget.appMediaItems.isEmpty)
        ? emptyScreen(
            context,
            3,
            PlayerTranslationConstants.nothingTo.tr,
            15.0,
            PlayerTranslationConstants.showHere.tr,
            50,
            PlayerTranslationConstants.addSomething.tr,
            23.0,
          )
        : Column(
            children: [
              PlaylistHead(
                songsList: widget.appMediaItems,
                offline: false,
                fromDownloads: false,
              ),
              Expanded(
                child: ListView.builder(
                  controller: widget.scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10),
                  shrinkWrap: true,
                  itemCount: widget.appMediaItems.length,
                  itemExtent: 70.0,
                  itemBuilder: (context, index) {
                    return ValueListenableBuilder(
                      valueListenable: selectMode,
                      builder: (context, value, child) {
                        final bool selected = selectedItems.contains(widget.appMediaItems[index].id);
                        return ListTile(
                          leading: imageCard(
                            imageUrl: widget.appMediaItems[index].image.toString(),
                            selected: selected,
                          ),
                          onTap: () {
                            if (selectMode.value) {
                              selectMode.value = false;
                              if (selected) {
                                selectedItems.remove(
                                  widget.appMediaItems[index].id.toString(),
                                );
                                selectMode.value = true;
                                if (selectedItems.isEmpty) {
                                  selectMode.value = false;
                                }
                              } else {
                                selectedItems
                                    .add(widget.appMediaItems[index].id.toString());
                                selectMode.value = true;
                              }
                              setState(() {});
                            } else {
                              NeomPlayerInvoke.init(
                                appMediaItems: widget.appMediaItems,
                                index: index,
                                isOffline: false,
                                recommend: false,
                                playlistBox: widget.playlistName,
                              );
                            }
                          },
                          onLongPress: () {
                            selectMode.value = false;
                            if (selected) {
                              selectedItems.remove(widget.appMediaItems[index].id.toString());
                              selectMode.value = true;
                              if (selectedItems.isEmpty) {
                                selectMode.value = false;
                              }
                            } else {
                              selectedItems
                                  .add(widget.appMediaItems[index].id.toString());
                              selectMode.value = true;
                            }
                            setState(() {});
                          },
                          selected: selected,
                          selectedTileColor: Colors.white10,
                          title: Text(
                            '${widget.appMediaItems[index].title}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${widget.appMediaItems[index].artist ?? 'Unknown'} - ${widget.appMediaItems[index].album ?? 'Unknown'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.playlistName != AppHiveConstants.favoriteSongs)
                                LikeButton(
                                  mediaItem: null,
                                  data: widget.appMediaItems[index] as Map,
                                ),
                              DownloadButton(
                                data: widget.appMediaItems[index] as Map,
                                icon: 'download',
                              ),
                              SongTileTrailingMenu(
                                appMediaItem: widget.appMediaItems[index],
                                itemlist: Itemlist(),
                                isPlaylist: true,
                                deleteLiked: widget.onDelete,
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

class AlbumsTab extends StatefulWidget {
  final Map<String, List> albums;
  final List sortedAlbumKeysList;
  // final String? tempPath;
  final String type;
  final bool offline;
  final String? playlistName;
  const AlbumsTab({
    super.key,
    required this.albums,
    required this.offline,
    required this.sortedAlbumKeysList,
    required this.type,
    this.playlistName,
    // this.tempPath,
  });

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.sortedAlbumKeysList.isEmpty
        ? emptyScreen(
            context,
            3,
            PlayerTranslationConstants.nothingTo.tr,
            15.0,
            PlayerTranslationConstants.showHere.tr,
            50,
            PlayerTranslationConstants.addSomething.tr,
            23.0,
          )
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 10.0),
            shrinkWrap: true,
            itemExtent: 70.0,
            itemCount: widget.sortedAlbumKeysList.length,
            itemBuilder: (context, index) {
              final List imageList = widget
                  .albums[widget.sortedAlbumKeysList[index]]!.length >= 4
                  ? widget.albums[widget.sortedAlbumKeysList[index]]!.sublist(0, 4)
                  : widget.albums[widget.sortedAlbumKeysList[index]]!.sublist(0,
                widget.albums[widget.sortedAlbumKeysList[index]]!.length,
              );
              return ListTile(
                leading: (widget.offline)
                    ? OfflineCollage(
                        imageList: imageList,
                        showGrid: widget.type == 'genre',
                        placeholderImage: widget.type == 'artist'
                            ? AppAssets.musicPlayerArtist
                            : AppAssets.musicPlayerAlbum,
                      )
                    : Collage(
                        imageList: [AppFlavour.getAppLogoUrl()],//itemlist.getImgUrls(),
                        showGrid: widget.type == 'genre',
                        placeholderImage: widget.type == 'artist'
                            ? AppAssets.musicPlayerArtist
                            : AppAssets.musicPlayerAlbum,
                      ),
                title: Text(
                  '${widget.sortedAlbumKeysList[index]}',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  widget.albums[widget.sortedAlbumKeysList[index]]!.length == 1
                      ? '${widget.albums[widget.sortedAlbumKeysList[index]]!.length} ${PlayerTranslationConstants.song.tr}'
                      : '${widget.albums[widget.sortedAlbumKeysList[index]]!.length} ${PlayerTranslationConstants.songs.tr}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall!.color,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, __, ___) => widget.offline
                          ? SongsList(
                              data: AppMediaItem.listFromList(widget.albums[widget.sortedAlbumKeysList[index]]!),
                              offline: widget.offline,
                            )
                          : LikedSongs(
                              playlistName: widget.playlistName!,
                              fromPlaylist: true,
                              showName:
                                  widget.sortedAlbumKeysList[index].toString(),
                              appMediaSongs: AppMediaItem.listFromList(widget.albums[widget.sortedAlbumKeysList[index]]),
                            ),
                    ),
                  );
                },
              );
            },
          );
  }
}
