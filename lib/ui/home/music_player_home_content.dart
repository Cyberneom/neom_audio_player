
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/itemlist_type.dart';
import 'package:neom_music_player/neom_player_invoker.dart';
import 'package:neom_music_player/to_delete/search/search_page.dart';
import 'package:neom_music_player/ui/drawer/library/playlist_player_page.dart';
import 'package:neom_music_player/ui/home/music_player_home_controller.dart';
import 'package:neom_music_player/ui/player/media_player_page.dart';
import 'package:neom_music_player/ui/widgets/collage.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/horizontal_albumlist_separated.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/widgets/on_hover.dart';
import 'package:neom_music_player/ui/widgets/song_list.dart';
import 'package:neom_music_player/ui/widgets/song_tile_trailing_menu.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/music_player_route_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:neom_music_player/utils/enums/image_quality.dart';

class MusicPlayerHomeContent extends StatelessWidget {

  MusicPlayerHomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double boxSize = MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
        ? MediaQuery.of(context).size.width / 2 : MediaQuery.of(context).size.height / 2.5;
    if (boxSize > 250) boxSize = 250;

    return GetBuilder<MusicPlayerHomeController>(
      id: AppPageIdConstants.musicPlayerHome,
      builder: (_) => _.isLoading ? const Center(child: CircularProgressIndicator(),)
        : (_.myItemLists.isEmpty && _.recentList.isEmpty && _.publicItemlists.isEmpty)
        ? TextButton(
          onPressed: ()=>Navigator.push(context, MaterialPageRoute(
            builder: (context) => const SearchPage(
              query: '', fromHome: true, autofocus: true,
            ),
          ),
        ),
        child: emptyScreen(context, 3,
        PlayerTranslationConstants.nothingTo.tr, 15.0,
        PlayerTranslationConstants.showHere.tr, 50,
        PlayerTranslationConstants.startSearch.tr, 23.0,),
      ) : ListView.builder(physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        itemCount: _.publicItemlists.isEmpty ? 3 : (_.publicItemlists.length + 3),
        itemBuilder: (context, idx) {
          AppUtilities.logger.v('Building Music Home Index $idx');
          if (idx == _.recentIndex) {
            return buildLastSessionContainer(context, _);
          }
          if (idx == _.myPlaylistsIndex) {
            return _.myItemLists.isNotEmpty ? buildMyPlaylistsContainer(_, context, boxSize) : Container();
          }

          if (idx == _.favoriteItemsIndex) {
            return _.favoriteItems.isNotEmpty ? buildFavoriteItemsContainer(_, context, boxSize) : Container();
          }

          final Itemlist publicList = _.publicItemlists.values.elementAt(idx - 3);
          if (publicList == null || publicList.getTotalItems() == 0) {
            return const SizedBox();
          } else if (publicList.name == 'likedArtists') {
            return buildLikedArtistContainer(publicList, context);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                child: Text(publicList.name.capitalizeFirst,
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
                  ///TRY TO MAKE ALLIANCE WITH RADIO STATIONS ONLINE
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
                    final currentSongList = [];
                    //publicItemlists.values.elementAt(idx).where((e) => e['type'] == 'song').toList();
                    if (publicList.id.isEmpty) return const SizedBox();
                    return GestureDetector(
                      child: SizedBox(
                        width: boxSize - 30,
                        child: HoverBox(
                          child: imageCard(
                            margin: const EdgeInsets.all(4.0),
                            borderRadius: 10,
                            // item['type'] == 'radio_station' ? 1000.0 : 10.0,
                            imageUrl: publicList.getImgUrls()
                                .length > index ? publicList.getImgUrls()
                                .elementAt(index) : publicList
                                .getImgUrls().last,
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0,),),
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
                                              borderRadius: BorderRadius
                                                  .circular(10,
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
                                              ///TODO TO VERIFY
                                              // if (isHover)
                                              //   LikeButton(
                                              //     appMediaItem: null,
                                              //     data: publicList.toJSON(),
                                              //   ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,),
                                    child: Column(
                                      children: [
                                        Text(item.name,
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
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // onLongPress: () {
                      //   Feedback.forLongPress(context);
                      //   showDialog(
                      //     context: context,
                      //     builder: (context) {
                      //       return InteractiveViewer(
                      //         child: Stack(
                      //           children: [
                      //             GestureDetector(
                      //               onTap: () => Navigator.pop(context),
                      //             ),
                      //             AlertDialog(
                      //               shape: RoundedRectangleBorder(
                      //                 borderRadius: BorderRadius.circular(15.0),
                      //               ),
                      //               backgroundColor: Colors.transparent,
                      //               contentPadding: EdgeInsets.zero,
                      //               content: imageCard(
                      //                 borderRadius: 15,//item['type'] == 'radio_station' ? 1000.0 : 15.0,
                      //                 imageUrl: publicList.imgUrl,
                      //                 imageQuality: ImageQuality.high,
                      //                 placeholderImage: const AssetImage(AppAssets.musicPlayerAlbum),
                      //                 // (item['type'] == 'playlist' ||
                      //                 //     item['type'] == 'album') ? const AssetImage(
                      //                 //   AppAssets.musicPlayerAlbum,
                      //                 // ) : item['type'] == 'artist'
                      //                 //     ? const AssetImage(AppAssets.musicPlayerArtist,)
                      //                 //     : const AssetImage(AppAssets.musicPlayerCover,),
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       );
                      //       },
                      //     );
                      //   },
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
                            Navigator.push(context,
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) =>
                                    SongsListPage(
                                      itemlist: publicList, //TODO Get items from itemlist,
                                    ),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },),
    );
  }

  Widget buildLastSessionContainer(BuildContext context, MusicPlayerHomeController _) {
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
            songsList: _.recentList.values.toList(),
            onTap: (int idx) {
              NeomPlayerInvoker.init(
                appMediaItems: [_.recentList.values.elementAt(idx)],
                index: 0,
              );
            },
          ),
        ],
      ),
      builder: (BuildContext context, Box box, Widget? child) {
        return (_.recentList.isEmpty ||
            !(box.get('showRecent', defaultValue: true) as bool))
            ? const SizedBox() : child!;
      },
    );
  }

  Widget buildMyPlaylistsContainer(MusicPlayerHomeController _, BuildContext context, double boxSize) {
    return Column(
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
            onTap: () => Get.toNamed(AppRouteConstants.lists),
          ),
          SizedBox(
            height: boxSize + 15,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _.myItemLists.length,
              itemBuilder: (context, index) {
                Itemlist itemlist = _.myItemLists.values.elementAt(index);
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius
                            .circular(10.0,),),
                        clipBehavior: Clip.antiAlias,
                        child: name == AppHiveConstants.favoriteSongs
                            ? const Image(image: AssetImage(AppAssets.musicPlayerCover,),)
                            : const Image(image: AssetImage(AppAssets.musicPlayerAlbum,),),
                      ) : Collage(
                        borderRadius: 10.0,
                        imageList: itemlist.getImgUrls(),
                        showGrid: true,
                        placeholderImage: AppAssets.musicPlayerCover,
                      ),
                      builder: ({
                      required BuildContext context,
                      required bool isHover,
                      Widget? child,}) {
                      return Card(
                        color: isHover ? null : Colors.transparent,
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0,),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            SizedBox.square(
                              dimension: isHover ? boxSize - 25 : boxSize - 30,
                              child: child,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(itemlist.name.capitalizeFirst!,
                                    textAlign: TextAlign.center,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,),
                                  ),
                                  if (subtitle != null && subtitle.isNotEmpty)
                                    Text(subtitle,
                                      textAlign: TextAlign.center,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).textTheme.bodySmall!.color,
                                      ),
                                    ),
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
                    ///DEPRECATED
                    // await Hive.openBox(name);
                    Navigator.push(context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PlaylistPlayerPage(
                              alternativeName: name, itemlist: itemlist,
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
  }

  Widget buildFavoriteItemsContainer(MusicPlayerHomeController _, BuildContext context, double boxSize) {
    return Column(
      children: [
        GestureDetector(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                child: Text(
                  PlayerTranslationConstants.favorites.tr,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          onTap: () => MaterialPageRoute(builder: (context) => PlaylistPlayerPage(),),
        ),
        SizedBox(
          height: boxSize + 15,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _.favoriteItems.length,
            itemBuilder: (context, index) {
              AppMediaItem favoriteItem = _.favoriteItems.elementAt(index);
              final String name = favoriteItem.name;
              final String subtitle = favoriteItem.artist;
              return GestureDetector(
                child: SizedBox(
                  width: boxSize - 20,
                  child: HoverBox(
                    child: (favoriteItem.imgUrl.isEmpty && (favoriteItem.allImgs == null || (favoriteItem.allImgs?.isEmpty ?? true)))
                        ? Card(
                      elevation: 5,
                      color: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius
                          .circular(10.0,),),
                      clipBehavior: Clip.antiAlias,
                      child: const Image(image: AssetImage(AppAssets.musicPlayerCover,),),
                    ) : Collage(
                      borderRadius: 10.0,
                      imageList: favoriteItem.imgUrl.isNotEmpty ? [favoriteItem.imgUrl] : favoriteItem.allImgs!,
                      showGrid: true,
                      placeholderImage: AppAssets.musicPlayerCover,
                    ),
                    builder: ({
                      required BuildContext context,
                      required bool isHover,
                      Widget? child,}) {
                      return Card(
                        color: isHover ? null : Colors.transparent,
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0,),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            SizedBox.square(
                              dimension: isHover ? boxSize - 25 : boxSize - 30,
                              child: child,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(favoriteItem.name.capitalizeFirst!,
                                    textAlign: TextAlign.center,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,),
                                  ),
                                  if (subtitle != null && subtitle.isNotEmpty)
                                    Text(subtitle,
                                      textAlign: TextAlign.center,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).textTheme.bodySmall!.color,
                                      ),
                                    ),
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
                  ///DEPRECATED
                  // await Hive.openBox(name);
                  Get.to(() => MediaPlayerPage(appMediaItem: favoriteItem),transition: Transition.leftToRight);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildLikedArtistContainer(Itemlist itemlist, BuildContext context) {
    final Itemlist likedArtistsList = itemlist;
    return likedArtistsList.getTotalItems() == 0
        ? const SizedBox()
        : Column(
      children: [
        Row(
          children: [
            Padding(
              padding:
              const EdgeInsets.fromLTRB(15, 10, 0, 5),
              child: Text('Liked Artists',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        // HorizontalAlbumsList(
        //   itemlist: likedArtistsList,
        //   onTap: (int idx) {
        //     Navigator.push(
        //       context,
        //       PageRouteBuilder(
        //         opaque: false,
        //         pageBuilder: (_, __, ___) =>
        //             ArtistSearchPage(
        //               data: likedArtistsList as Map,
        //             ),
        //       ),
        //     );
        //   },
        // ),
      ],
    );
  }

}
