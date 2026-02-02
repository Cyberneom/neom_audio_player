import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/ui/widgets/images/neom_image_card.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';

import '../../../audio_player_invoker.dart';
import '../../../utils/audio_player_utilities.dart';
import '../../../utils/constants/audio_player_route_constants.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
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

    return SintBuilder<AudioPlayerHomeController>(
      id: AppPageIdConstants.audioPlayerHome,
      builder: (controller) => Obx(()=> controller.isLoading.value
          ? const Center(child: CircularProgressIndicator(),)
        : (controller.myItemLists.isEmpty && controller.favoriteItems.isEmpty
          && controller.recentList.isEmpty && controller.publicItemlists.isEmpty
          && controller.releaseItemlists.isEmpty)
        ? TextButton(
          onPressed: ()=> Navigator.push(context, MaterialPageRoute(
            builder: (context) => const SearchPage(
              fromHome: true, autofocus: true,
            ),
          ),
        ),
        child: emptyScreen(context, 3,
        AudioPlayerTranslationConstants.nothingTo.tr, 15.0,
        AudioPlayerTranslationConstants.showHere.tr, 50,
        AudioPlayerTranslationConstants.startSearch.tr, 23.0,),
      ) : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          if(!AppConfig.instance.isGuestMode && controller.recentList.isNotEmpty)
            SliverToBoxAdapter(child: buildLastSessionContainer(context, controller)),
          if(controller.favoriteItems.isNotEmpty)
            SliverToBoxAdapter(child: buildFavoriteItemsContainer(controller, context, boxSize)),
          if(controller.releaseItemlists.isNotEmpty)
            SliverToBoxAdapter(child: buildCategorizedPlaylists(controller.releaseItemlists.values.toList(), boxSize, context)),
          if(controller.publicItemlists.isNotEmpty) SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
                Itemlist publicList = Itemlist();
                publicList = controller.publicItemlists.values.elementAt(index);
                bool containsExternalItems = publicList.externalItems?.isNotEmpty ?? true;
                if (publicList.id.isEmpty || publicList.getTotalItems() == 0 || containsExternalItems) {
                  return const SizedBox.shrink();
                } else if (publicList.name == 'likedArtists') {
                  return buildLikedArtistContainer(publicList, context);
                }

                return buildPublicListColumn(publicList, context, boxSize);
              },
              childCount: controller.publicItemlists.length,
            ),
          ),
        ]),
      ),
    );
  }

  Column buildPublicListColumn(Itemlist publicList, BuildContext context, double boxSize) {
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
              List<AppMediaItem> itemsOnLists = AppMediaItemMapper.mapItemsFromItemlist(publicList);
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
                      imageUrl: publicList.getImgUrls().length > index ? publicList.getImgUrls()
                          .elementAt(index) : publicList.getImgUrls().last,
                      placeholderImage: const AssetImage(AppAssets.audioPlayerAlbum),
                    ),
                    builder: ({required BuildContext context, required bool isHover, Widget? child,}) {
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
                                if(publicList.getTotalItems() > 0)
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
                                    style: const TextStyle(fontWeight: FontWeight.w500,),
                                  ),
                                  if (item.ownerName.isNotEmpty)
                                    Text(item.ownerName,
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
  }

  Widget buildCategorizedPlaylists(List<Itemlist> lists, double boxSize, BuildContext context, {bool shuffle = true}) {
    if(lists.isEmpty) const SizedBox.shrink();

    lists.shuffle();
    Set<Itemlist> shownPlaylists = {};
    Map<String, List<Itemlist>> categorizedItemlists = AudioPlayerUtilities.categorizePlaylistsByTags(lists);

    if(categorizedItemlists.isNotEmpty) {
      return ListView.builder(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemCount: categorizedItemlists.length,
        itemBuilder: (context, index) {
          String tag = categorizedItemlists.keys.elementAt(index);
          List<Itemlist> items = categorizedItemlists.values.elementAt(index);
          /// items.where((item) => !shownPlaylists.contains(item)).toList();
          shownPlaylists.addAll(items);
          return buildPlaylistsContainer(items, context, tag.tr.toUpperCase(), boxSize);
        },
      );
    } else {
      return buildPlaylistsContainer(lists, context, CommonTranslationConstants.recentReleases.tr, boxSize);
    }
  }

  Widget buildLastSessionContainer(BuildContext context, AudioPlayerHomeController controller) {
    return controller.settingsBox != null ?
    ValueListenableBuilder(
      valueListenable: controller.settingsBox!.listenable(),
      child: Column(
        children: [
          GestureDetector(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 0, 5),
                  child: Text(
                    CommonTranslationConstants.lastSession.tr,
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
            songsList: controller.recentList.values.where((item)=> item.mediaSource == AppMediaSource.internal).toList(),
            onTap: (int idx) {
              Sint.find<AudioPlayerInvoker>().init(
                mediaItems: controller.recentList.values.toList(),
                index: idx,
              );
            },
          ),
        ],
      ),
      builder: (BuildContext context, Box box, Widget? child) {
        return (controller.recentList.isEmpty ||
            !(box.get('showRecent', defaultValue: true) as bool))
            ? const SizedBox.shrink() : child!;
      },
    ):SizedBox.shrink();
  }

  Widget buildPlaylistsContainer(List<Itemlist> playlists, BuildContext context, String title, double boxSize) {
    return Column(
        children: [
          GestureDetector(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                  child: Text(title,
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
              // AuthGuard.protect(context, () {
              //   Sint.toNamed(AppRouteConstants.lists);
              // });
            }
          ),
          SizedBox(
            height: boxSize + 15,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                Itemlist itemlist = playlists.elementAt(index);
                String name = itemlist.name;
                int totalItems = itemlist.getTotalItems();
                String? subtitle;
                if(totalItems == 1) {
                  subtitle = '$totalItems ${AudioPlayerTranslationConstants.mediaItem.tr}';
                } else if(totalItems > 1) {
                  subtitle = '$totalItems ${AudioPlayerTranslationConstants.mediaItems.tr}';
                }
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
                        child: name == AppHiveBox.favoriteItems.name
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
                                  if(subtitle != null && subtitle.isNotEmpty)
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
                    if(totalItems == 1) {
                      List<AppMediaItem> singleItemList = AppMediaItemMapper.mapItemsFromItemlist(itemlist);
                      AppMediaItem singleItem = singleItemList.first;
                      Sint.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [singleItem]);
                    } else if(totalItems > 1) {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (context) => PlaylistPlayerPage(itemlist: itemlist,),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
    );
  }

  Widget buildFavoriteItemsContainer(AudioPlayerHomeController controller, BuildContext context, double boxSize) {
    return Column(
      children: [
        GestureDetector(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                child: Text(
                  AppTranslationConstants.favorites.tr.toUpperCase(),
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
            itemCount: controller.favoriteItems.length,
            itemBuilder: (context, index) {
              AppMediaItem favoriteItem = controller.favoriteItems.elementAt(index);
              final String subtitle = favoriteItem.ownerName;
              return favoriteItem.mediaSource == AppMediaSource.internal ? GestureDetector(
                child: SizedBox(
                  width: boxSize - 20,
                  child: HoverBox(
                    child: (favoriteItem.imgUrl.isEmpty && (favoriteItem.galleryUrls?.isEmpty ?? true))
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
                      imageList: favoriteItem.imgUrl.isNotEmpty ? [favoriteItem.imgUrl] : favoriteItem.galleryUrls ?? [],
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
                  Sint.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [favoriteItem]);
                },
              ) : SizedBox.shrink();
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
