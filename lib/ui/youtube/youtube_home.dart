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
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_music_player/domain/entities/playlist_section.dart';
import 'package:neom_music_player/domain/use_cases/ytmusic/youtube_services.dart';
import 'package:neom_music_player/ui/YouTube/youtube_search.dart';
import 'package:neom_music_player/ui/drawer/music_player_drawer.dart';
import 'package:neom_music_player/ui/youtube/playlist_card.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';

class YouTube extends StatefulWidget {
  const YouTube({super.key});

  @override
  _YouTubeState createState() => _YouTubeState();
}

class _YouTubeState extends State<YouTube> with AutomaticKeepAliveClientMixin<YouTube> {

  final TextEditingController _controller = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  bool status = false;
  List<PlaylistSection>? searchedList;
  PlaylistSection? headList;

  @override
  void initState() {

    AppUtilities.logger.i('Initializing Youtube Feature');
    // searchedList = AppHiveController().searchedList;
    // headList = AppHiveController().headList;

    if (!status) {
      YouTubeServices().getMusicHome().then((value) {
        status = true;
        if (value.head != null || value.body != null) {
          setState(() {
            headList = value.head;
            searchedList = value.body;
            // AppHiveController().updateCache(
            //   searchedList: searchedList.t,
            //   headList: headList,
            // );
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
          if (searchedList == null || searchedList!.isEmpty)
            const Center(child: CircularProgressIndicator(),)
          else
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 70, 10, 0),
              child: Column(
                children: [
                  if (headList != null)
                    CarouselSlider.builder(
                      itemCount: headList?.playlistItems?.length,
                      options: CarouselOptions(
                        height: boxSize + 20,
                        viewportFraction: rotated ? 0.36 : 1.0,
                        autoPlay: true,
                        enlargeCenterPage: true,
                      ),
                      itemBuilder: (BuildContext context,
                        int index, int pageViewIndex,) {
                        String headlistTitle = headList?.playlistItems![index].title ?? '';
                        if(headlistTitle.toLowerCase() == 'null') {
                          headlistTitle = '';
                        }
                        String headlistImgUrl = headList?.playlistItems![index].imgUrl ?? '';
                        return GestureDetector(
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
                              imageUrl: headlistImgUrl,
                              placeholder: (context, url) => const Image(
                                fit: BoxFit.cover,
                                image: AssetImage(AppAssets.musicPlayerYTCover),
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(context,
                              PageRouteBuilder(opaque: false,
                                pageBuilder: (_, __, ___) => YouTubeSearchPage(
                                  query: headlistTitle,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ListView.builder(
                    itemCount: searchedList?.length ?? 0,
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 10),
                    itemBuilder: (context, index) {
                      String sectionTitle = searchedList![index].title;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 10, 0, 5),
                                child: Text(sectionTitle,
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
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              itemCount: searchedList![index].playlistItems?.length ?? 0,
                              itemBuilder: (context, idx) {
                                return PlaylistCard(playlistItem: searchedList![index].playlistItems![idx]);
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
              margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
              // margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0,),
                color: AppTheme.canvasColor50(context),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5.0,
                    offset: Offset(1.5, 1.5),
                    // shadow direction: bottom right
                  ),
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
