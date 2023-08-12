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
import 'package:neom_music_player/ui/widgets/bouncy_sliver_scroll_view.dart';
import 'package:neom_music_player/ui/widgets/copy_clipboard.dart';
import 'package:neom_music_player/ui/widgets/download_button.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/widgets/song_list.dart';
import 'package:neom_music_player/ui/Search/artist_search_page.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:get/get.dart';

class AlbumSearchPage extends StatefulWidget {
  final String query;
  final String type;

  const AlbumSearchPage({
    super.key,
    required this.query,
    required this.type,
  });

  @override
  _AlbumSearchPageState createState() => _AlbumSearchPageState();
}

class _AlbumSearchPageState extends State<AlbumSearchPage> {
  int page = 1;
  bool loading = false;
  List<Map>? _searchedList;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !loading) {
        page += 1;
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _fetchData() {
    loading = true;
    switch (widget.type) {
      case 'Playlists':
        SaavnAPI()
            .fetchAlbums(
          searchQuery: widget.query,
          type: 'playlist',
          page: page,
        )
            .then((value) {
          final temp = _searchedList ?? [];
          temp.addAll(value);
          setState(() {
            _searchedList = temp;
            loading = false;
          });
        });
      case 'Albums':
        SaavnAPI()
            .fetchAlbums(
          searchQuery: widget.query,
          type: 'album',
          page: page,
        )
            .then((value) {
          final temp = _searchedList ?? [];
          temp.addAll(value);
          setState(() {
            _searchedList = temp;
            loading = false;
          });
        });
      case 'Artists':
        SaavnAPI()
            .fetchAlbums(
          searchQuery: widget.query,
          type: 'artist',
          page: page,
        )
            .then((value) {
          final temp = _searchedList ?? [];
          temp.addAll(value);
          setState(() {
            _searchedList = temp;
            loading = false;
          });
        });
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: AppColor.main75,
        body: _searchedList == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _searchedList!.isEmpty
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
                    title: widget.type,
                    placeholderImage: widget.type == 'Artists'
                        ? AppAssets.musicPlayerArtist
                        : AppAssets.musicPlayerAlbum,
                    sliverList: SliverList(
                      delegate: SliverChildListDelegate(
                        _searchedList!.map(
                          (Map entry) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: ListTile(
                                title: Text(
                                  '${entry["title"]}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onLongPress: () {
                                  copyToClipboard(
                                    context: context,
                                    text: '${entry["title"]}',
                                  );
                                },
                                subtitle: entry['subtitle'] == ''
                                    ? null
                                    : Text(
                                        '${entry["subtitle"]}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                leading: imageCard(
                                  elevation: 8,
                                  borderRadius:
                                      widget.type == 'Artists' ? 50.0 : 7.0,
                                  placeholderImage: AssetImage(
                                    widget.type == 'Artists'
                                        ? AppAssets.musicPlayerArtist
                                        : AppAssets.musicPlayerAlbum,
                                  ),
                                  imageUrl: entry['image'].toString(),
                                ),
                                trailing: widget.type != 'Albums'
                                    ? null
                                    : AlbumDownloadButton(
                                        albumName: entry['title'].toString(),
                                        albumId: entry['id'].toString(),
                                      ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (_, __, ___) =>
                                          widget.type == 'Artists'
                                              ? ArtistSearchPage(
                                                  data: entry,
                                                )
                                              : SongsListPage(
                                                  listItem: entry,
                                                ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ),
      ),
    );
  }
}
