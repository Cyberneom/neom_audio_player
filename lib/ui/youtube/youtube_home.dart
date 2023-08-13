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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_music_player/data/implementations/app_hive_controller.dart';
import 'package:neom_music_player/ui/widgets/drawer.dart';
import 'package:neom_music_player/ui/widgets/on_hover.dart';
import 'package:neom_music_player/domain/use_cases/youtube_services.dart';
import 'package:neom_music_player/ui/YouTube/youtube_playlist.dart';
import 'package:neom_music_player/ui/YouTube/youtube_search.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:get/get.dart';



class YouTube extends StatefulWidget {
  const YouTube({super.key});

  @override
  _YouTubeState createState() => _YouTubeState();
}

class _YouTubeState extends State<YouTube>
    with AutomaticKeepAliveClientMixin<YouTube> {

  final TextEditingController _controller = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  bool status = false;
  late List searchedList;
  late List headList;

  @override
  void initState() {

    AppUtilities.logger.i("Initializing Youtube Feature");
    searchedList = AppHiveController().searchedList;
    headList = AppHiveController().headList;

    if (!status) {
      YouTubeServices().getMusicHome().then((value) {
        status = true;
        if (value.isNotEmpty) {
          setState(() {
            searchedList = value['body'] ?? [];
            headList = value['head'] ?? [];
            AppHiveController().updateCache(
              searchedList: searchedList,
              headList: headList,
            );
          });
        } else {
          status = false;
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext cntxt) {
    super.build(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool rotated = MediaQuery.of(context).size.height < screenWidth;
    double boxSize = !rotated
        ? MediaQuery.of(context).size.width / 2
        : MediaQuery.of(context).size.height / 2.5;
    if (boxSize > 250) boxSize = 250;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColor.main75,
      body: Stack(
        children: [
          if (searchedList.isEmpty)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 70, 10, 0),
              child: Column(
                children: [
                  if (headList.isNotEmpty)
                    CarouselSlider.builder(
                      itemCount: headList.length,
                      options: CarouselOptions(
                        height: boxSize + 20,
                        viewportFraction: rotated ? 0.36 : 1.0,
                        autoPlay: true,
                        enlargeCenterPage: true,
                      ),
                      itemBuilder: (
                        BuildContext context,
                        int index,
                        int pageViewIndex,
                      ) =>
                          GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false,
                              pageBuilder: (_, __, ___) => YouTubeSearchPage(
                                query: headList[index]['title'].toString(),
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            errorWidget: (context, _, __) => const Image(
                              fit: BoxFit.cover,
                              image: AssetImage(
                                AppAssets.musicPlayerYTCover,
                              ),
                            ),
                            imageUrl: headList[index]['image'].toString(),
                            placeholder: (context, url) => const Image(
                              fit: BoxFit.cover,
                              image: AssetImage(AppAssets.musicPlayerYTCover),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ListView.builder(
                    itemCount: searchedList.length,
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 10),
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 10, 0, 5),
                                child: Text(
                                  '${searchedList[index]["title"]}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: boxSize + 10,
                            width: double.infinity,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              itemCount:
                                  (searchedList[index]['playlists'] as List)
                                      .length,
                              itemBuilder: (context, idx) {
                                final item =
                                    searchedList[index]['playlists'][idx];
                                item['subtitle'] = item['type'] != 'video'
                                    ? '${item["count"]} Tracks | ${item["description"]}'
                                    : '${item["count"]} | ${item["description"]}';
                                return GestureDetector(
                                  onTap: () {
                                    item['type'] == 'video'
                                        ? Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              opaque: false,
                                              pageBuilder: (_, __, ___) =>
                                                  YouTubeSearchPage(
                                                query: item['title'].toString(),
                                              ),
                                            ),
                                          )
                                        : Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              opaque: false,
                                              pageBuilder: (_, __, ___) =>
                                                  YouTubePlaylist(
                                                playlistId: item['playlistId']
                                                    .toString(),
                                                // playlistImage:
                                                //     item['imageStandard']
                                                //         .toString(),
                                                // playlistName:
                                                //     item['title'].toString(),
                                                // playlistSubtitle:
                                                //     '${item['count']} Songs',
                                                // playlistSecondarySubtitle:
                                                //     item['description']
                                                //         ?.toString(),
                                              ),
                                            ),
                                          );
                                  },
                                  child: SizedBox(
                                    width: item['type'] != 'playlist'
                                        ? (boxSize - 30) * (16 / 9)
                                        : boxSize - 30,
                                    child: HoverBox(
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: Card(
                                                    elevation: 5,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10.0,
                                                      ),
                                                    ),
                                                    clipBehavior:
                                                        Clip.antiAlias,
                                                    child: CachedNetworkImage(
                                                      fit: BoxFit.cover,
                                                      errorWidget:
                                                          (context, _, __) =>
                                                              Image(
                                                        fit: BoxFit.cover,
                                                        image: item['type'] !=
                                                                'playlist'
                                                            ? const AssetImage(
                                                                AppAssets.musicPlayerYTCover,
                                                              )
                                                            : const AssetImage(
                                                                AppAssets.musicPlayerCover,
                                                              ),
                                                      ),
                                                      imageUrl: item['image']
                                                          .toString(),
                                                      placeholder:
                                                          (context, url) =>
                                                              Image(
                                                        fit: BoxFit.cover,
                                                        image: item['type'] !=
                                                                'playlist'
                                                            ? const AssetImage(
                                                                AppAssets.musicPlayerYTCover,
                                                              )
                                                            : const AssetImage(
                                                                AppAssets.musicPlayerCover,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (item['type'] == 'chart')
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Container(
                                                      color: Colors.black
                                                          .withOpacity(0.75),
                                                      width: (boxSize - 30) *
                                                          (16 / 9) /
                                                          2.5,
                                                      margin:
                                                          const EdgeInsets.all(
                                                        4.0,
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            item['count']
                                                                .toString(),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          const IconButton(
                                                            onPressed: null,
                                                            color: Colors.white,
                                                            disabledColor:
                                                                Colors.white,
                                                            icon: Icon(
                                                              Icons
                                                                  .playlist_play_rounded,
                                                              size: 40,
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10.0,
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  '${item["title"]}',
                                                  textAlign: TextAlign.center,
                                                  softWrap: false,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  item['subtitle'].toString(),
                                                  textAlign: TextAlign.center,
                                                  softWrap: false,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .color,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 5.0,
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      builder: ({
                                        required BuildContext context,
                                        required bool isHover,
                                        Widget? child,
                                      }) {
                                        return Card(
                                          color: isHover
                                              ? null
                                              : Colors.transparent,
                                          elevation: 0,
                                          margin: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10.0,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: child,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          GestureDetector(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 55.0,
              padding: const EdgeInsets.all(5.0),
              margin:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
              // margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  10.0,
                ),
                color: Theme.of(context).cardColor,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5.0,
                    offset: Offset(1.5, 1.5),
                    // shadow direction: bottom right
                  )
                ],
              ),
              child: Row(
                children: [
                  homeDrawer(context: context),
                  const SizedBox(
                    width: 5.0,
                  ),
                  Text(
                    PlayerTranslationConstants.searchYt.tr,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Theme.of(context).textTheme.bodySmall!.color,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const YouTubeSearchPage(
                  query: '',
                  autofocus: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
