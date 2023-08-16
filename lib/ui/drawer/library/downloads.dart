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

import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_music_player/domain/entities/app_media_item.dart';
import 'package:neom_music_player/ui/widgets/custom_physics.dart';
import 'package:neom_music_player/ui/widgets/data_search.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/widgets/playlist_head.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/helpers/picker.dart';
import 'package:neom_music_player/neom_player_invoke.dart';
import 'package:neom_music_player/ui/drawer/library/liked.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

class Downloads extends StatefulWidget {
  const Downloads({super.key});
  @override
  _DownloadsState createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads>
    with SingleTickerProviderStateMixin {
  Box downloadsBox = Hive.box('downloads');
  bool added = false;
  List<AppMediaItem> _appMediaItems = [];
  final Map<String, List<Map>> _albums = {};
  final Map<String, List<Map>> _artists = {};
  final Map<String, List<Map>> _genres = {};
  List _sortedAlbumKeysList = [];
  List _sortedArtistKeysList = [];
  List _sortedGenreKeysList = [];
  TabController? _tcontroller;
  int _currentTabIndex = 0;
  // int currentIndex = 0;
  // String? tempPath = Hive.box(AppHiveConstants.settings).get('tempDirPath')?.toString();
  int sortValue = Hive.box(AppHiveConstants.settings).get('sortValue', defaultValue: 1) as int;
  int orderValue =
      Hive.box(AppHiveConstants.settings).get('orderValue', defaultValue: 1) as int;
  int albumSortValue =
      Hive.box(AppHiveConstants.settings).get('albumSortValue', defaultValue: 2) as int;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showShuffle = ValueNotifier<bool>(true);

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
    // getDownloads();
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

  Future<void> getDownloads() async {
    // _appMediaItems = downloadsBox.values.toList();
    setArtistAlbum();
  }

  void setArtistAlbum() {
    for (final mediaItem in _appMediaItems) {
      try {
        // if (_albums.containsKey(mediaItem.album)) {
        //   final List<Map> tempAlbum = _albums[mediaItem.album]!;
        //   tempAlbum.add(mediaItem as Map);
        //   _albums.addEntries([MapEntry(mediaItem.album.toString(), tempAlbum)]);
        // } else {
        //   _albums.addEntries([MapEntry(mediaItem.album.toString(), [mediaItem as Map])]);
        // }
        //
        // if (_artists.containsKey(mediaItem.artist)) {
        //   final List<Map> tempArtist = _artists[mediaItem.artist]!;
        //   tempArtist.add(mediaItem);
        //   _artists.addEntries([MapEntry(mediaItem.artist.toString(), tempArtist)]);
        // } else {
        //   _artists.addEntries([
        //     MapEntry(mediaItem.artist.toString(), [mediaItem])
        //   ]);
        // }
        //
        // if (_genres.containsKey(mediaItem.genre)) {
        //   final List<Map> tempGenre = _genres[mediaItem.genre]!;
        //   tempGenre.add(mediaItem);
        //   _genres
        //       .addEntries([MapEntry(mediaItem.genre.toString(), tempGenre)]);
        // } else {
        //   _genres.addEntries([
        //     MapEntry(mediaItem.genre.toString(), [mediaItem])
        //   ]);
        // }
      } catch (e) {
        // ShowSnackBar().showSnackBar(
        //   context,
        //   'Error: $e',
        // );
        AppUtilities.logger.e('Error while setting artist and album: $e');
      }
    }

    sortSongs(sortVal: sortValue, order: orderValue);

    _sortedAlbumKeysList = _albums.keys.toList();
    _sortedArtistKeysList = _artists.keys.toList();
    _sortedGenreKeysList = _genres.keys.toList();

    sortAlbums();

    added = true;
    setState(() {});
  }

  void sortSongs({required int sortVal, required int order}) {
    switch (sortVal) {
      case 0:
        _appMediaItems.sort(
          (a, b) => a.title
              .toString()
              .toUpperCase()
              .compareTo(b.title.toString().toUpperCase()),
        );
      case 1:
        _appMediaItems.sort(
          (a, b) => a.releaseDate
              .toString()
              .toUpperCase()
              .compareTo(b.releaseDate.toString().toUpperCase()),
        );
      case 2:
        _appMediaItems.sort(
          (a, b) => a.album
              .toString()
              .toUpperCase()
              .compareTo(b.album.toString().toUpperCase()),
        );
      case 3:
        _appMediaItems.sort(
          (a, b) => a.artist
              .toString()
              .toUpperCase()
              .compareTo(b.artist.toString().toUpperCase()),
        );
      case 4:
        _appMediaItems.sort(
          (a, b) => a.duration
              .toString()
              .toUpperCase()
              .compareTo(b.duration.toString().toUpperCase()),
        );
      default:
        _appMediaItems.sort(
          (b, a) => a.releaseDate
              .toString()
              .toUpperCase()
              .compareTo(b.releaseDate.toString().toUpperCase()),
        );
        break;
    }

    if (order == 1) {
      _appMediaItems = _appMediaItems.reversed.toList();
    }
  }

  void sortAlbums() {
    switch (albumSortValue) {
      case 0:
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
      case 1:
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
      case 2:
        _sortedAlbumKeysList
            .sort((b, a) => _albums[a]!.length.compareTo(_albums[b]!.length));
        _sortedArtistKeysList
            .sort((b, a) => _artists[a]!.length.compareTo(_artists[b]!.length));
        _sortedGenreKeysList
            .sort((b, a) => _genres[a]!.length.compareTo(_genres[b]!.length));
      case 3:
        _sortedAlbumKeysList
            .sort((a, b) => _albums[a]!.length.compareTo(_albums[b]!.length));
        _sortedArtistKeysList
            .sort((a, b) => _artists[a]!.length.compareTo(_artists[b]!.length));
        _sortedGenreKeysList
            .sort((a, b) => _genres[a]!.length.compareTo(_genres[b]!.length));
      default:
        _sortedAlbumKeysList
            .sort((b, a) => _albums[a]!.length.compareTo(_albums[b]!.length));
        _sortedArtistKeysList
            .sort((b, a) => _artists[a]!.length.compareTo(_artists[b]!.length));
        _sortedGenreKeysList
            .sort((b, a) => _genres[a]!.length.compareTo(_genres[b]!.length));
        break;
    }
  }

  Future<void> deleteSong(Map song) async {
    await downloadsBox.delete(song['id']);
    final audioFile = File(song['path'].toString());
    final imageFile = File(song['image'].toString());
    if (_albums[song['album']]!.length == 1) {
      _sortedAlbumKeysList.remove(song['album']);
    }
    _albums[song['album']]!.remove(song);

    if (_artists[song['artist']]!.length == 1) {
      _sortedArtistKeysList.remove(song['artist']);
    }
    _artists[song['artist']]!.remove(song);

    if (_genres[song['genre']]!.length == 1) {
      _sortedGenreKeysList.remove(song['genre']);
    }
    _genres[song['genre']]!.remove(song);

    _appMediaItems.remove(song);
    try {
      await audioFile.delete();
      if (await imageFile.exists()) {
        imageFile.delete();
      }
      ShowSnackBar().showSnackBar(
        context,
        '${PlayerTranslationConstants.deleted.tr} ${song['title']}',
      );
    } catch (e) {
      AppUtilities.logger.e('Failed to delete $audioFile.path', e);
      ShowSnackBar().showSnackBar(
        context,
        '${PlayerTranslationConstants.failedDelete.tr}: ${audioFile.path}\nError: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: AppColor.main75,
          appBar: AppBar(
            title: Text(PlayerTranslationConstants.downs.tr),
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
              IconButton(
                icon: const Icon(CupertinoIcons.search),
                tooltip: PlayerTranslationConstants.search.tr,
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: DownloadsSearch(
                      data: _appMediaItems,
                      isDowns: true,
                    ),
                  );
                },
              ),
              if (_appMediaItems.isNotEmpty && _currentTabIndex == 0)
                PopupMenuButton(
                  icon: const Icon(Icons.sort_rounded),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                  onSelected:
                      // (currentIndex == 0)
                      // ?
                      (int value) {
                    if (value < 5) {
                      sortValue = value;
                      Hive.box(AppHiveConstants.settings).put('sortValue', value);
                    } else {
                      orderValue = value - 5;
                      Hive.box(AppHiveConstants.settings).put('orderValue', orderValue);
                    }
                    sortSongs(sortVal: sortValue, order: orderValue);
                    setState(() {});
                    //   }
                    // : (int value) {
                    //     albumSortValue = value;
                    //     Hive.box(AppHiveConstants.settings)
                    //         .put('albumSortValue', value);
                    //     sortAlbums();
                    //     setState(() {});
                  },
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
          ),
          body: !added
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : TabBarView(
                  physics: const CustomPhysics(),
                  controller: _tcontroller,
                  children: [
                    DownSongsTab(
                      onDelete: (Map item) {
                        deleteSong(item);
                      },
                      appMediaItems: _appMediaItems,
                      scrollController: _scrollController,
                    ),
                    AlbumsTab(
                      albums: _albums,
                      offline: true,
                      type: 'album',
                      sortedAlbumKeysList: _sortedAlbumKeysList,
                    ),
                    AlbumsTab(
                      albums: _artists,
                      type: 'artist',
                      // tempPath: tempPath,
                      offline: true,
                      sortedAlbumKeysList: _sortedArtistKeysList,
                    ),
                    AlbumsTab(
                      albums: _genres,
                      type: 'genre',
                      offline: true,
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
                if (_appMediaItems.isNotEmpty) {
                  NeomPlayerInvoke.init(
                    appMediaItems: _appMediaItems,
                    index: 0,
                    isOffline: true,
                    fromDownloads: true,
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

Future<AppMediaItem> editTags(AppMediaItem mediaItem, BuildContext context) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      final tagger = Audiotagger();

      FileImage songImage = FileImage(File(mediaItem.image.toString()));

      final titlecontroller = TextEditingController(text: mediaItem.title.toString());
      final albumcontroller = TextEditingController(text: mediaItem.album.toString());
      final artistcontroller = TextEditingController(text: mediaItem.artist.toString());
      final albumArtistController = TextEditingController(text: mediaItem.albumArtist.toString());
      final genrecontroller = TextEditingController(text: mediaItem.genre.toString());
      final yearcontroller = TextEditingController(text: mediaItem.year.toString());
      final pathcontroller = TextEditingController(text: mediaItem.path.toString());

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        content: SizedBox(
          height: 400,
          width: 300,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final String filePath = await Picker.selectFile(
                      context: context,
                      // ext: .png', 'jpg', 'jpeg,
                      message: 'Pick Image',
                    );
                    if (filePath != '') {
                      final imagePath = filePath;
                      File(imagePath).copy(mediaItem.image.toString());

                      songImage = FileImage(File(imagePath));

                      final Tag tag = Tag(
                        artwork: imagePath,
                      );
                      try {
                        await [
                          Permission.manageExternalStorage,
                        ].request();
                        await tagger.writeTags(
                          path: mediaItem.path.toString(),
                          tag: tag,
                        );
                      } catch (e) {
                        await tagger.writeTags(
                          path: mediaItem.path.toString(),
                          tag: tag,
                        );
                      }
                    }
                  },
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width / 2,
                      width: MediaQuery.of(context).size.width / 2,
                      child: Image(
                        fit: BoxFit.cover,
                        image: songImage,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Text(
                      PlayerTranslationConstants.title.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: titlecontroller,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      PlayerTranslationConstants.artist.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: artistcontroller,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      PlayerTranslationConstants.albumArtist.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: albumArtistController,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      PlayerTranslationConstants.album.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: albumcontroller,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      PlayerTranslationConstants.genre.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: genrecontroller,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      PlayerTranslationConstants.year.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: yearcontroller,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      PlayerTranslationConstants.songPath.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: pathcontroller,
                  onSubmitted: (value) {},
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(PlayerTranslationConstants.cancel.tr),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () async {
              Navigator.pop(context);
              mediaItem.title = titlecontroller.text;
              mediaItem.album = albumcontroller.text;
              mediaItem.artist = artistcontroller.text;
              mediaItem.albumArtist = albumArtistController.text;
              mediaItem.genre = genrecontroller.text;
              mediaItem.year = int.parse(yearcontroller.text);
              mediaItem.path = pathcontroller.text;
              final tag = Tag(
                title: titlecontroller.text,
                artist: artistcontroller.text,
                album: albumcontroller.text,
                genre: genrecontroller.text,
                year: yearcontroller.text,
                albumArtist: albumArtistController.text,
              );
              try {
                try {
                  await [
                    Permission.manageExternalStorage,
                  ].request();
                  tagger.writeTags(
                    path: mediaItem.path.toString(),
                    tag: tag,
                  );
                } catch (e) {
                  await tagger.writeTags(
                    path: mediaItem.path.toString(),
                    tag: tag,
                  );
                  ShowSnackBar().showSnackBar(
                    context,
                    PlayerTranslationConstants.successTagEdit.tr,
                  );
                }
              } catch (e) {
                AppUtilities.logger.e('Failed to edit tags', e);
                ShowSnackBar().showSnackBar(
                  context,
                  '${PlayerTranslationConstants.failedTagEdit.tr}\nError: $e',
                );
              }
            },
            child: Text(
              PlayerTranslationConstants.ok.tr,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary == Colors.white
                    ? Colors.black
                    : null,
              ),
            ),
          ),
          const SizedBox(
            width: 5,
          ),
        ],
      );
    },
  );
  return mediaItem;
}

class DownSongsTab extends StatefulWidget {
  final List<AppMediaItem> appMediaItems;
  final Function(Map item) onDelete;
  final ScrollController scrollController;
  const DownSongsTab({
    super.key,
    required this.appMediaItems,
    required this.onDelete,
    required this.scrollController,
  });

  @override
  State<DownSongsTab> createState() => _DownSongsTabState();
}

class _DownSongsTabState extends State<DownSongsTab>
    with AutomaticKeepAliveClientMixin {
  Future<void> downImage({required String imageFilePath,
  required String songFilePath,
  required String url,}) async {
    final File file = File(imageFilePath);

    try {
      await file.create();
      final image = await Audiotagger().readArtwork(path: songFilePath);
      if (image != null) {
        file.writeAsBytesSync(image);
      }
    } catch (e) {
      final HttpClientRequest request2 =
          await HttpClient().getUrl(Uri.parse(url));
      final HttpClientResponse response2 = await request2.close();
      final bytes2 = await consolidateHttpClientResponseBytes(response2);
      await file.writeAsBytes(bytes2);
    }
  }

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
                offline: true,
                fromDownloads: true,
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
                    return ListTile(
                      leading: imageCard(
                        imageUrl: widget.appMediaItems[index].image.toString(),
                        localImage: true,
                        localErrorFunction: (_, __) {
                          if (widget.appMediaItems[index].image.isNotEmpty) {
                              downImage(songFilePath: '', imageFilePath: '', url: widget.appMediaItems[index].image.toString(),
                            );
                          }
                        },
                      ),
                      onTap: () {
                        NeomPlayerInvoke.init(
                          appMediaItems: widget.appMediaItems,
                          index: index,
                          isOffline: true,
                          fromDownloads: true,
                          recommend: false,
                        );
                      },
                      title: Text(
                        '${widget.appMediaItems[index].title}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${widget.appMediaItems[index].artist ?? 'Artist name'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15.0),
                              ),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 0,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_rounded,
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Text(
                                      PlayerTranslationConstants.edit.tr,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 1,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_rounded,
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Text(
                                      PlayerTranslationConstants.delete.tr,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (int? value) async {
                              if (value == 0) {
                                widget.appMediaItems[index] = await editTags(
                                  widget.appMediaItems[index],
                                  context,
                                );
                                Hive.box(AppHiveConstants.downloads).put(
                                  widget.appMediaItems[index].id,
                                  widget.appMediaItems[index],
                                );
                                setState(() {});
                              }
                              if (value == 1) {
                                setState(() {
                                  widget.onDelete(widget.appMediaItems[index] as Map);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }
}