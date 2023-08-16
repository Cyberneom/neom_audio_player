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

import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_music_player/data/implementations/spotify_hive_controller.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/ui/Search/search_page.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

class TopPage extends StatefulWidget {
  final String type;
  const TopPage({super.key, required this.type});
  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage>
    with AutomaticKeepAliveClientMixin<TopPage> {

  SpotifyHiveController spotifyHiveController = Get.put(SpotifyHiveController());

  Future<void> getCachedData(String type) async {
    spotifyHiveController.getCachedData(type);
    setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getCachedData(widget.type);
    spotifyHiveController.scrapData(widget.type);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isGlobal = widget.type == 'Global';
    if ((isGlobal && !spotifyHiveController.globalFetched) || (!isGlobal && !spotifyHiveController.localFetched)) {
      getCachedData(widget.type);
      spotifyHiveController.scrapData(widget.type);
      setState(() {});
    }
    return ValueListenableBuilder(
      valueListenable: isGlobal ? spotifyHiveController.globalFetchFinished : spotifyHiveController.localFetchFinished,
      builder: (BuildContext context, bool value, Widget? child) {
        final List showList = isGlobal ? spotifyHiveController.globalSongs : spotifyHiveController.localSongs;
        return Column(
          children: [
            if (!(Hive.box(AppHiveConstants.settings).get('spotifySigned', defaultValue: false)
                as bool))
              Expanded(
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      spotifyHiveController.scrapData(widget.type, signIn: true);
                    },
                    child: Text(PlayerTranslationConstants.signInSpotify.tr),
                  ),
                ),
              )
            else if (showList.isEmpty)
              Expanded(
                child: value
                    ? emptyScreen(
                        context,
                        0,
                        ':( ',
                        100,
                        'ERROR',
                        60,
                        'Service Unavailable',
                        20,
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                        ],
                      ),
              )
            else
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: showList.length,
                  itemExtent: 70.0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: imageCard(
                        imageUrl: showList[index]['image_url_small'].toString(),
                      ),
                      title: Text(
                        '${index + 1}. ${showList[index]["name"]}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        showList[index]['artist'].toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(15.0),
                          ),
                        ),
                        onSelected: (int? value) async {
                          if (value == 0) {
                            await launchUrl(
                              Uri.parse(
                                showList[index]['spotifyUrl'].toString(),
                              ),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 0,
                            child: Row(
                              children: [
                                const Icon(Icons.open_in_new_rounded),
                                const SizedBox(width: 10.0),
                                Text(
                                  PlayerTranslationConstants.openInSpotify.tr,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchPage(
                              query: showList[index]['name'].toString(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}