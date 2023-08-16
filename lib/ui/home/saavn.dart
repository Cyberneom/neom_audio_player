import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/enums/itemlist_type.dart';
import 'package:neom_music_player/data/api_services/APIs/saavn_api.dart';
import 'package:neom_music_player/domain/entities/app_media_item.dart';
import 'package:neom_music_player/ui/widgets/collage.dart';
import 'package:neom_music_player/ui/widgets/horizontal_albumlist.dart';
import 'package:neom_music_player/ui/widgets/horizontal_albumlist_separated.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/widgets/like_button.dart';
import 'package:neom_music_player/ui/widgets/on_hover.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/ui/widgets/song_tile_trailing_menu.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/music_player_route_constants.dart';
import 'package:neom_music_player/utils/helpers/extensions.dart';
import 'package:neom_music_player/utils/helpers/format.dart';
import 'package:neom_music_player/neom_player_invoke.dart';
import 'package:neom_music_player/ui/widgets/song_list.dart';
import 'package:neom_music_player/ui/drawer/library/liked.dart';
import 'package:neom_music_player/ui/Search/artist_search_page.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:neom_music_player/utils/enums/image_quality.dart';
import 'dart:math';

bool fetched = false;
List preferredLanguage = Hive.box(AppHiveConstants.settings).get('preferredLanguage', defaultValue: ['Hindi']) as List;
List likedRadio = Hive.box(AppHiveConstants.settings).get('likedRadio', defaultValue: []) as List;
// Map data = Hive.box(AppHiveConstants.cache).get('homepage', defaultValue: {}) as Map;
Map<String, Itemlist> itemLists = {};

class SaavnHomePage extends StatefulWidget {
  @override
  _SaavnHomePageState createState() => _SaavnHomePageState();
}

class _SaavnHomePageState extends State<SaavnHomePage>
    with AutomaticKeepAliveClientMixin<SaavnHomePage> {
  List<AppMediaItem> recentList = Hive.box(AppHiveConstants.cache).get('recentSongs', defaultValue: <AppMediaItem>[]) as List<AppMediaItem>;
  List<Itemlist> myItemLists = [];
  List<Itemlist> publicItemlists = [];
  // Map likedArtists = Hive.box(AppHiveConstants.settings).get('likedArtists', defaultValue: {}) as Map;
  // List playlistNames = Hive.box(AppHiveConstants.settings).get('playlistNames')?.toList() as List? ?? [AppHiveConstants.favoriteSongs];
  // Map playlistDetails = Hive.box(AppHiveConstants.settings).get('playlistDetails', defaultValue: {}) as Map;
  int recentIndex = 0;
  int playlistIndex = 1;

  Future<void> getHomePageData() async {
    AppUtilities.logger.i("Get ItemLists Home Data");

    final userController = Get.find<UserController>();

    try {
      Map<String,Itemlist> myLists = await ItemlistFirestore().retrieveItemlists(userController.profile.id);
      myItemLists = myLists.values.toList();
      publicItemlists = await ItemlistFirestore().fetchAll();
      myItemLists.forEach((myKey) {
        publicItemlists.removeWhere((key) => myKey.id == key.id);
      });
      myItemLists.addAll(publicItemlists);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    // Map recievedData = await SaavnAPI().fetchHomePageData();
    // if (recievedData.isNotEmpty) {
    //   Hive.box(AppHiveConstants.cache).put('homepage', recievedData);
    //   data = recievedData;
    //   lists = ['recent', 'playlist', ...?data['collections'] as List?];
    //   lists.insert((lists.length / 2).round(), 'likedArtists');
    // }

    setState(() {});
    // recievedData = await FormatResponse.formatPromoLists(data);
    // if (recievedData.isNotEmpty) {
    //   Hive.box(AppHiveConstants.cache).put('homepage', recievedData);
    //   data = recievedData;
    //   lists = ['recent', 'playlist', ...?data['collections'] as List?];
    //   lists.insert((lists.length / 2).round(), 'likedArtists');
    // }
    setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!fetched) {
      getHomePageData();
      fetched = true;
    }
    double boxSize = MediaQuery.of(context).size.height
        > MediaQuery.of(context).size.width
        ? MediaQuery.of(context).size.width / 2
        : MediaQuery.of(context).size.height / 2.5;
    if (boxSize > 250) boxSize = 250;
    if (publicItemlists.length >= 3) {
      recentIndex = 0;
      playlistIndex = 1;
    } else {
      recentIndex = 1;
      playlistIndex = 0;
    }
    return (myItemLists.isEmpty && recentList.isEmpty && publicItemlists.isEmpty)
        ? const Center(child: CircularProgressIndicator(),)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            itemCount: publicItemlists.isEmpty ? 2 : publicItemlists.length,
            itemBuilder: (context, idx) {
              AppUtilities.logger.i("Building Music Home Index $idx");
              if (idx == recentIndex) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box(AppHiveConstants.settings).listenable(),
                  child: Column(
                    children: [
                      GestureDetector(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 10, 0, 5),
                              child: Text(
                                PlayerTranslationConstants.lastSession.tr,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, MusicPlayerRouteConstants.recent);
                        },
                      ),
                      HorizontalAlbumsListSeparated(
                        songsList: [],//recentList,
                        onTap: (int idx) {
                          NeomPlayerInvoke.init(
                            appMediaItems: [recentList[idx]],
                            index: 0,
                            isOffline: false,
                          );
                        },
                      ),
                    ],
                  ),
                  builder: (BuildContext context, Box box, Widget? child) {
                    return (recentList.isEmpty || !(box.get('showRecent', defaultValue: true) as bool))
                        ? const SizedBox() : child!;
                  },
                );
              }
              if (idx == playlistIndex) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box(AppHiveConstants.settings).listenable(),
                  child: Column(
                    children: [
                      GestureDetector(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                              child: Text(
                                PlayerTranslationConstants.yourPlaylists.tr,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, MusicPlayerRouteConstants.playlists);
                        },
                      ),
                      SizedBox(
                        height: boxSize + 15,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: myItemLists.length,
                          itemBuilder: (context, index) {
                            Itemlist itemlist = myItemLists.elementAt(index);
                            final String name = itemlist.name;
                            final String? subtitle = itemlist.getTotalItems() == 0 ? null :
                                 '${itemlist.getTotalItems()} ${PlayerTranslationConstants.songs.tr}';
                            return GestureDetector(
                              child: SizedBox(
                                width: boxSize - 20,
                                child: HoverBox(
                                  child: (itemlist.getImgUrls().isEmpty || itemlist.getTotalItems() == 0)
                                      ? Card(
                                          elevation: 5,
                                          color: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0,),),
                                          clipBehavior: Clip.antiAlias,
                                          child: name == AppHiveConstants.favoriteSongs
                                              ? const Image(image: AssetImage(AppAssets.musicPlayerCover,),)
                                              : const Image(image: AssetImage(AppAssets.musicPlayerAlbum,),),
                                        )
                                      : Collage(
                                          borderRadius: 10.0,
                                          imageList: itemlist.getImgUrls(),
                                          showGrid: true,
                                          placeholderImage: AppAssets.musicPlayerCover,
                                        ), builder: ({
                                    required BuildContext context,
                                    required bool isHover,
                                    Widget? child,
                                  }) {
                                    return Card(
                                      color: isHover ? null : Colors.transparent,
                                      elevation: 0,
                                      margin: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.0,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        children: [
                                          SizedBox.square(
                                            dimension: isHover ? boxSize - 25 : boxSize - 30,
                                            child: child,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10.0,),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(itemlist.name.capitalizeFirst!,
                                                  textAlign: TextAlign.center,
                                                  softWrap: false,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.w500,),
                                                ),
                                                if (subtitle != null && subtitle.isNotEmpty)
                                                  Text(subtitle,
                                                    textAlign: TextAlign.center,
                                                    softWrap: false,
                                                    overflow:TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Theme.of(context).textTheme.bodySmall!.color,
                                                    ),
                                                  )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              onTap: () async {
                                await Hive.openBox(name);
                                Navigator.push(context,
                                  MaterialPageRoute(
                                    builder: (context) => LikedSongs(
                                      playlistName: name,
                                      showName: name,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    ],
                  ),
                  builder: (BuildContext context, Box box, Widget? child) {
                    return child!;
                    // return (playlistNames.isEmpty ||
                    //         !(box.get('showPlaylist', defaultValue: true)
                    //             as bool) ||
                    //         (playlistNames.length == 1 &&
                    //             playlistNames.first == AppHiveConstants.favoriteSongs &&
                    //             likedCount() == 0))
                    //     ? const SizedBox()
                    //     : child!;
                  },
                );
              }
              final Itemlist publicList = publicItemlists.elementAt(idx);

              if(publicList.name == 'likedArtists') {
                final Itemlist likedArtistsList = publicList;
                return likedArtistsList.getTotalItems() == 0
                    ? const SizedBox()
                    : Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 10, 0, 5),
                                child: Text(
                                  'Liked Artists',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          HorizontalAlbumsList(
                            itemlist: likedArtistsList,
                            onTap: (int idx) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) => ArtistSearchPage(
                                    data: likedArtistsList as Map,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                );
              }
              return publicList == null || publicList.getTotalItems() == 0
                  ? const SizedBox()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                          child: Text(publicList.name.capitalizeFirst ?? '',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: boxSize + 15,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: publicList.getTotalItems(),
                            // publicList.name == 'Radio Stations'
                            //     ? (publicItemlists.values.elementAt(idx) as List).length + likedRadio.length
                            //     : (publicItemlists.values.elementAt(idx) as List).length,
                            itemBuilder: (context, index) {
                              AppMediaItem item = AppMediaItem.mapItemsFromItemlist(publicList).elementAt(index);
                              if (publicList.type != ItemlistType.radioStation) {
                                // item = publicList;
                              } else {
                                // index < likedRadio.length
                                //     ? item = likedRadio[index] as Map
                                //     : item = publicItemlists.values.elementAt(idx)
                                // [index - likedRadio.length] as Map;
                              }
                              final currentSongList = [];//publicItemlists.values.elementAt(idx).where((e) => e['type'] == 'song').toList();
                              if (publicList.id.isEmpty) return const SizedBox();
                              return GestureDetector(
                                onLongPress: () {
                                  Feedback.forLongPress(context);
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return InteractiveViewer(
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () => Navigator.pop(context),
                                            ),
                                            AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15.0),
                                              ),
                                              backgroundColor: Colors.transparent,
                                              contentPadding: EdgeInsets.zero,
                                              content: imageCard(
                                                borderRadius: 15,//item['type'] == 'radio_station' ? 1000.0 : 15.0,
                                                imageUrl: publicList.imgUrl,
                                                imageQuality: ImageQuality.high,
                                                placeholderImage: const AssetImage(AppAssets.musicPlayerAlbum),
                                                // (item['type'] == 'playlist' ||
                                                //     item['type'] == 'album') ? const AssetImage(
                                                //   AppAssets.musicPlayerAlbum,
                                                // ) : item['type'] == 'artist'
                                                //     ? const AssetImage(AppAssets.musicPlayerArtist,)
                                                //     : const AssetImage(AppAssets.musicPlayerCover,),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                onTap: () {
                                  if (false
                                  // item['type'] == 'radio_station'
                                  ) {
                                    // ShowSnackBar().showSnackBar(
                                    //   context,
                                    //   PlayerTranslationConstants.connectingRadio.tr,
                                    //   duration: const Duration(seconds: 2),
                                    // );
                                    // SaavnAPI().createRadio(
                                    //   names: item['more_info']['featured_station_type'].toString() == 'artist'
                                    //       ? [item['more_info']['query'].toString()] : [item['id'].toString()],
                                    //   language: item['more_info']['language']?.toString() ?? 'Español',
                                    //   stationType: item['more_info']['featured_station_type'].toString(),
                                    // ).then((value) {
                                    //   if (value != null) {
                                    //     SaavnAPI().getRadioSongs(stationId: value)
                                    //         .then((value) {
                                    //       NeomPlayerInvoke.init(
                                    //         appMediaItems: value,
                                    //         index: 0,
                                    //         isOffline: false,
                                    //         shuffle: true,
                                    //       );
                                    //     });
                                    //   }
                                    // });
                                  } else {
                                    if (false
                                    // item['type'] == 'song'
                                    ) {
                                      // NeomPlayerInvoke.init(
                                      //   appMediaItems: AppMediaItem.listFromList(currentSongList as List),
                                      //   index: currentSongList.indexWhere(
                                      //     (e) => e['id'] == item.get['id'],
                                      //   ),
                                      //   isOffline: false,
                                      // );
                                    } else {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          opaque: false,
                                          pageBuilder: (_, __, ___) =>
                                              SongsListPage(itemlist: publicList,//TODO Get items from itemlist,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: SizedBox(
                                  width: boxSize - 30,
                                  child: HoverBox(
                                    child: imageCard(
                                      margin: const EdgeInsets.all(4.0),
                                      borderRadius: 10,
                                          // item['type'] == 'radio_station'
                                          //     ? 1000.0
                                          //     : 10.0,
                                      imageUrl: publicList.getImgUrls().elementAt(index),
                                      imageQuality: ImageQuality.medium,
                                      placeholderImage: const AssetImage(AppAssets.musicPlayerAlbum),
                                          // (item['type'] == 'playlist' ||
                                          //     item['type'] == 'album')
                                          //     ? const AssetImage(AppAssets.musicPlayerAlbum,)
                                          //     : item['type'] == 'artist'
                                          //         ? const AssetImage(AppAssets.musicPlayerArtist,)
                                          //         : const AssetImage(AppAssets.musicPlayerCover,),
                                    ),
                                    builder: ({
                                      required BuildContext context,
                                      required bool isHover,
                                      Widget? child,
                                    }) {
                                      return Card(
                                        color: isHover ? null : Colors.transparent,
                                        elevation: 0,
                                        margin: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0,),),
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          children: [
                                            Stack(
                                              children: [
                                                SizedBox.square(
                                                  dimension: isHover ? boxSize - 25 : boxSize - 30,
                                                  child: child,
                                                ),
                                                if (isHover
                                                    // && (item['type'] == 'song' || item['type'] == 'radio_station')
                                                )
                                                  Positioned.fill(
                                                    child: Container(
                                                      margin: const EdgeInsets.all(4.0,),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black54,
                                                        borderRadius: BorderRadius.circular(10,
                                                          // item['type'] == 'radio_station'
                                                          //     ? 1000.0 : 10.0,
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: DecoratedBox(
                                                          decoration: BoxDecoration(
                                                            color: Colors.black87,
                                                            borderRadius: BorderRadius
                                                                .circular(1000.0,),
                                                          ),
                                                          child: const Icon(
                                                            Icons.play_arrow_rounded,
                                                            size: 50.0,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                // if (item['type'] == 'radio_station' &&
                                                //     (Platform.isAndroid || Platform.isIOS || isHover))
                                                //   Align(
                                                //     alignment: Alignment.topRight,
                                                //     child: IconButton(
                                                //       icon: likedRadio.contains(item)
                                                //           ? const Icon(Icons.favorite_rounded, color: Colors.red,)
                                                //           : const Icon(Icons.favorite_border_rounded),
                                                //       tooltip: likedRadio.contains(item)
                                                //           ? PlayerTranslationConstants.unlike.tr
                                                //           : PlayerTranslationConstants.like.tr,
                                                //       onPressed: () {
                                                //         likedRadio.contains(item)
                                                //             ? likedRadio.remove(item)
                                                //             : likedRadio.add(item);
                                                //         Hive.box(AppHiveConstants.settings).put('likedRadio', likedRadio,);
                                                //         setState(() {});
                                                //       },
                                                //     ),
                                                //   ),
                                                if (publicList.getTotalItems() > 0
                                                    // || item['type'] == 'song'
                                                )
                                                  Align(
                                                    alignment: Alignment.topRight,
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (isHover)
                                                          LikeButton(
                                                            mediaItem: null,
                                                            data: publicList.toJSON(),
                                                          ),
                                                        SongTileTrailingMenu(
                                                          appMediaItem: item,
                                                          itemlist: publicList,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10.0,),
                                              child: Column(
                                                children: [
                                                  Text(item.title,
                                                    textAlign: TextAlign.center,
                                                    softWrap: false,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  if (item.artist.isNotEmpty)
                                                    Text(item.artist,
                                                      textAlign: TextAlign.center,
                                                      softWrap: false,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Theme.of(context).textTheme.bodySmall!.color,
                                                      ),
                                                    )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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
          );
  }

  String getSubTitle(Map item) {
    AppUtilities.logger.e("Getting SubtTitle.");
    final type = item['type'];
    switch (type) {
      case 'charts':
        return '';
      case 'radio_station':
        return 'Radio • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle']?.toString().unescape()}';
      case 'playlist':
        return 'Playlist • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'song':
        return 'Single • ${item['artist']?.toString().unescape()}';
      case 'mix':
        return 'Mix • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'show':
        return 'Podcast • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'album':
        final artists = item['more_info']?['artistMap']?['artists'].map((artist) => artist['name']).toList();
        if (artists != null) {
          return 'Album • ${artists?.join(', ')?.toString().unescape()}';
        } else if (item['subtitle'] != null && item['subtitle'] != '') {
          return 'Album • ${item['subtitle']?.toString().unescape()}';
        }
        return 'Album';
      default:
        final artists = item['more_info']?['artistMap']?['artists']
            .map((artist) => artist['name'])
            .toList();
        return artists?.join(', ')?.toString().unescape() ?? '';
    }
  }

  int likedCount() {
    return Hive.box(AppHiveConstants.favoriteSongs).length;
  }
}
