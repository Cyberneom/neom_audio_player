import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_itemlists/itemlists/data/firestore/app_media_item_firestore.dart';

import '../../../data/implementations/playlist_hive_controller.dart';
import '../../../neom_player_invoker.dart';
import '../../../utils/constants/app_hive_constants.dart';
import '../../../utils/constants/player_translation_constants.dart';
import '../../../utils/helpers/songs_count.dart' as songs_count;
import '../../../utils/neom_audio_utilities.dart';
import 'widgets/song_page_tab.dart';

final ValueNotifier<bool> selectMode = ValueNotifier<bool>(false);

class PlaylistPlayerPage extends StatefulWidget {
  final Itemlist? itemlist;
  final String alternativeName;
  final List<AppMediaItem>? appMediaItems;

  const PlaylistPlayerPage({
    super.key,
    this.itemlist,
    this.alternativeName = '',
    this.appMediaItems,
  });
  @override
  _PlaylistPlayerPageState createState() => _PlaylistPlayerPageState();
}

class _PlaylistPlayerPageState extends State<PlaylistPlayerPage>
    with SingleTickerProviderStateMixin {

  Box? likedBox;
  List<AppMediaItem> _appMediaItems = [];
  int sortValue = Hive.box(AppHiveConstants.settings).get('sortValue', defaultValue: 1) as int;
  int orderValue = Hive.box(AppHiveConstants.settings).get('orderValue', defaultValue: 1) as int;
  int albumSortValue =   Hive.box(AppHiveConstants.settings).get('albumSortValue', defaultValue: 2) as int;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showShuffle = ValueNotifier<bool>(true);
  PlaylistHiveController playlistHiveController = PlaylistHiveController();
  AppProfile profile = AppProfile();
  bool isLoading = true;

  @override
  void initState() {
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        _showShuffle.value = false;
      } else {
        _showShuffle.value = true;
      }
    });

    if (widget.itemlist != null) {
      _appMediaItems = AppMediaItem.mapItemsFromItemlist(widget.itemlist!);
      isLoading = false;
    } else {
      getFavoriteItems();
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Future<void> getFavoriteItems() async {
    AppProfile profile = playlistHiveController.userController.profile;
    Map<String, AppMediaItem> items = await AppMediaItemFirestore().retrieveFromList(profile.favoriteItems ?? []);
    _appMediaItems = items.values.toList();
    setState(() {
      isLoading = false;
    });
  }

  void removeFromFavorites(AppMediaItem song) {
    setState(() {
      likedBox!.delete(song.id);
      _appMediaItems.remove(song);
      songs_count.addSongsCount(
        widget.alternativeName,
        _appMediaItems.length,
        _appMediaItems.length >= 4
            ? _appMediaItems.sublist(0, 4)
            : _appMediaItems.sublist(0, _appMediaItems.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.main50,
      appBar: AppBarChild(
        title: widget.itemlist != null
            ? widget.itemlist?.name.tr.capitalizeFirst ?? ''
            : widget.alternativeName.tr.capitalizeFirst,
        actionWidgets: [
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                color: AppColor.getMain(), // Set your desired color here
              ),
            ),
            child: PopupMenuButton(
              icon: const Icon(Icons.sort_rounded),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              onSelected: (int value) {
                if (value < 5) {
                  sortValue = value;
                  Hive.box(AppHiveConstants.settings).put('sortValue', value);
                } else {
                  orderValue = value - 5;
                  Hive.box(AppHiveConstants.settings).put('orderValue', orderValue);
                }
                _appMediaItems = NeomAudioUtilities.sortSongs(_appMediaItems,
                  sortVal: sortValue,
                  order: orderValue,
                );
                setState(() {});
                },
              itemBuilder: (context) {
                final List<String> sortTypes = [
                  PlayerTranslationConstants.displayName.tr.capitalizeFirst,
                  PlayerTranslationConstants.dateAdded.tr.capitalizeFirst,
                  PlayerTranslationConstants.album.tr.capitalizeFirst,
                  PlayerTranslationConstants.artist.tr.capitalizeFirst,
                  PlayerTranslationConstants.duration.tr.capitalizeFirst,
                ];
                final List<String> orderTypes = [
                  PlayerTranslationConstants.inc.tr,
                  PlayerTranslationConstants.dec.tr,
                ];
                final menuList = <PopupMenuEntry<int>>[];
                menuList.addAll(
                  sortTypes.map((e) => PopupMenuItem(
                    value: sortTypes.indexOf(e),
                    child: Row(
                      children: [
                        if (sortValue == sortTypes.indexOf(e))
                          Row(
                            children: [
                              Icon(Icons.check_rounded,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white : Colors.grey[700],
                              ),
                              AppTheme.widthSpace10,
                            ],
                          ),
                        Text(e),
                      ],
                    ),
                  ),).toList(),
                );
                menuList.add(const PopupMenuDivider(height: 10,),);
                menuList.addAll(
                  orderTypes.map((e) => PopupMenuItem(
                    value: sortTypes.length + orderTypes.indexOf(e),
                    child: Row(
                      children: [
                        if(orderValue == orderTypes.indexOf(e))
                          Row(
                            children: [
                              Icon(Icons.check_rounded,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white : Colors.grey[700],),
                              AppTheme.widthSpace10,
                            ],
                          ),
                        Text(e,),
                      ],
                    ),
                  ),).toList(),
                );
                return menuList;
                },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: isLoading ? const AppCircularProgressIndicator() : SongsPageTab(
        appMediaItems: _appMediaItems,
            onDelete: (AppMediaItem item) {
              removeFromFavorites(item);
            },
            playlistName: widget.itemlist?.name ?? '',
            scrollController: _scrollController,
          ),
      ),
          floatingActionButton: ValueListenableBuilder(
            valueListenable: _showShuffle,
            child: FloatingActionButton(
              backgroundColor: AppColor.bondiBlue,
              elevation: 20,
              child: const Icon(
                Icons.shuffle_rounded,
                color: Colors.white,
                size: 24.0,
              ),
              onPressed: () {
                if (_appMediaItems.isNotEmpty) {
                  NeomPlayerInvoker.init(
                    appMediaItems: _appMediaItems,
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
    );
  }

}
