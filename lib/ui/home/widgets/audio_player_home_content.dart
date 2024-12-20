import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/ui/widgets/neom_image_card.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';

import '../../../neom_player_invoker.dart';
import '../../../utils/constants/app_hive_constants.dart';
import '../../../utils/constants/audio_player_route_constants.dart';
import '../../../utils/constants/player_translation_constants.dart';
import '../../library/playlist_player_page.dart';
import '../../widgets/empty_screen.dart';
import '../../widgets/song_tile_trailing_menu.dart';
import '../audio_player_home_controller.dart';
import 'collage.dart';
import 'horizontal_albumlist_separated.dart';
import 'hover_box.dart';
import 'search_page.dart';

class AudioPlayerHomeContent extends StatelessWidget {

  const AudioPlayerHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    double boxSize = MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
        ? MediaQuery.of(context).size.width / 2 : MediaQuery.of(context).size.height / 2.5;
    if (boxSize > 250) boxSize = 250;

    return GetBuilder<AudioPlayerHomeController>(
      id: AppPageIdConstants.audioPlayerHome,
      builder: (_) => _.isLoading.value ? const Center(child: CircularProgressIndicator(),)
        : (_.myItemLists.isEmpty && _.recentList.isEmpty && _.publicItemlists.isEmpty)
        ? TextButton(
          onPressed: ()=> Navigator.push(context, MaterialPageRoute(
            builder: (context) => const SearchPage(
              fromHome: true, autofocus: true,
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
          AppUtilities.logger.t('Building Music Home Index $idx');

          if (idx == _.recentIndex) return buildLastSessionContainer(context, _);

          if (idx == _.myPlaylistsIndex) {
            return _.myItemLists.isNotEmpty ? buildMyPlaylistsContainer(_, context, boxSize) : const SizedBox.shrink();
          }

          if (idx == _.favoriteItemsIndex) {
            return _.favoriteItems.isNotEmpty ? buildFavoriteItemsContainer(_, context, boxSize) : const SizedBox.shrink();
          }

          final Itemlist publicList = _.publicItemlists.values.elementAt(idx - 3);
          if (publicList.getTotalItems() == 0) {
            return const SizedBox.shrink();
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
                  itemBuilder: (context, index) {
                    List<AppMediaItem> itemsOnLists = AppMediaItem.mapItemsFromItemlist(publicList);
                    if (publicList.id.isEmpty || itemsOnLists.isEmpty) return const SizedBox.shrink();
                    AppMediaItem item = itemsOnLists.elementAt(index);
                    return GestureDetector(
                      child: SizedBox(
                        width: boxSize - 30,
                        child: HoverBox(
                          child: NeomImageCard(
                            margin: const EdgeInsets.all(4.0),
                            borderRadius: 10,
                            // item['type'] == 'radio_station' ? 1000.0 : 10.0,
                            imageUrl: publicList.getImgUrls()
                                .length > index ? publicList.getImgUrls()
                                .elementAt(index) : publicList
                                .getImgUrls().last,
                            placeholderImage: const AssetImage(AppAssets.audioPlayerAlbum),
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
                                      if (isHover)
                                        Positioned.fill(
                                          child: Container(
                                            margin: const EdgeInsets.all(4.0,),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(10,),
                                            ),
                                            child: Center(
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: Colors.black87,
                                                  borderRadius: BorderRadius.circular(1000.0,),
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
                                      if (publicList.getTotalItems() > 0)
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10,),
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
                      onTap: () {
                        Navigator.push(context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistPlayerPage(itemlist: publicList,),
                          ),
                        );
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

  Widget buildLastSessionContainer(BuildContext context, AudioPlayerHomeController _) {
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
            onTap: () => Navigator.pushNamed(context, AudioPlayerRouteConstants.recent),
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
            ? const SizedBox.shrink() : child!;
      },
    );
  }

  Widget buildMyPlaylistsContainer(AudioPlayerHomeController _, BuildContext context, double boxSize) {
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
                '${itemlist.getTotalItems()} ${PlayerTranslationConstants.mediaItems.tr}';
                return GestureDetector(
                  child: SizedBox(
                    width: boxSize - 20,
                    child: HoverBox(
                      child: (itemlist.getImgUrls().isEmpty || itemlist.getTotalItems() == 0)
                          ? Card(
                        elevation: 5,
                        color: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0,),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: name == AppHiveConstants.favoriteSongs
                            ? const Image(image: AssetImage(AppAssets.audioPlayerCover,),)
                            : const Image(image: AssetImage(AppAssets.audioPlayerAlbum,),),
                      ) : Collage(
                        borderRadius: 10.0,
                        imageList: itemlist.getImgUrls(),
                        showGrid: true,
                        placeholderImage: AppAssets.audioPlayerCover,
                      ),
                      builder: ({required BuildContext context, required bool isHover,
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
                                  Text(itemlist.name.capitalizeFirst,
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
                      MaterialPageRoute(builder: (context) => PlaylistPlayerPage(itemlist: itemlist,),
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

  Widget buildFavoriteItemsContainer(AudioPlayerHomeController _, BuildContext context, double boxSize) {
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
          onTap: () {
            MaterialPageRoute(builder: (context) => const PlaylistPlayerPage(),);
          }
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
              final String subtitle = favoriteItem.artist;
              return GestureDetector(
                child: SizedBox(
                  width: boxSize - 20,
                  child: HoverBox(
                    child: (favoriteItem.imgUrl.isEmpty && (favoriteItem.allImgs == null || (favoriteItem.allImgs?.isEmpty ?? true)))
                        ? Card(
                      elevation: 5,
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0,),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: const Image(image: AssetImage(AppAssets.audioPlayerCover,),),
                    ) : Collage(
                      borderRadius: 10.0,
                      imageList: favoriteItem.imgUrl.isNotEmpty ? [favoriteItem.imgUrl] : favoriteItem.allImgs!,
                      showGrid: true,
                      placeholderImage: AppAssets.audioPlayerCover,
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
                                  Text(favoriteItem.name.capitalizeFirst,
                                    textAlign: TextAlign.center,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,),
                                  ),
                                  if (subtitle.isNotEmpty)
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
                  Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [favoriteItem]);
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
        ? const SizedBox.shrink()
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
      ],
    );
  }

}
