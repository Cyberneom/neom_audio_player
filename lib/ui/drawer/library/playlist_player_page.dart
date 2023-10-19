import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';
import 'package:neom_itemlists/itemlists/data/firestore/app_media_item_firestore.dart';
import 'package:neom_music_player/data/implementations/playlist_hive_controller.dart';
import 'package:neom_music_player/neom_player_invoker.dart';
import 'package:neom_music_player/ui/drawer/library/widgets/song_page_tab.dart';
import 'package:neom_music_player/ui/widgets/custom_physics.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/multi_download_button.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:neom_music_player/utils/helpers/songs_count.dart' as songs_count;
import 'package:neom_music_player/utils/neom_audio_utilities.dart';

final ValueNotifier<bool> selectMode = ValueNotifier<bool>(false);
final Set<String> selectedItems = <String>{};

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
  TabController? _tcontroller;
  int sortValue = Hive.box(AppHiveConstants.settings).get('sortValue', defaultValue: 1) as int;
  int orderValue = Hive.box(AppHiveConstants.settings).get('orderValue', defaultValue: 1) as int;
  int albumSortValue =   Hive.box(AppHiveConstants.settings).get('albumSortValue', defaultValue: 2) as int;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showShuffle = ValueNotifier<bool>(true);
  int _currentTabIndex = 0;
  final int defaultTabLength = 1;
  PlaylistHiveController playlistHiveController = PlaylistHiveController();
  AppProfile profile = AppProfile();

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
  }

  @override
  void initState() {
    _tcontroller = TabController(length: defaultTabLength, vsync: this);
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

    if (widget.itemlist != null) {
      _appMediaItems = AppMediaItem.mapItemsFromItemlist(widget.itemlist!);
    } else {
      getLiked();
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tcontroller!.dispose();
    _scrollController.dispose();
  }

  Future<void> getLiked() async {
    AppProfile profile = playlistHiveController.userController.profile;
    Map<String, AppMediaItem> items = await AppMediaItemFirestore().fetchAll();
    _appMediaItems = items.values.toList();
    setState(() {});
  }

  void deleteLiked(AppMediaItem song) {
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
    return GradientContainer(
      child: DefaultTabController(
        length: defaultTabLength,
        child: Scaffold(
          backgroundColor: AppColor.main75,
          appBar: AppBar(
            title: Text(
              widget.itemlist != null
                  ? widget.itemlist?.name.tr.toUpperCase() ?? ''
                  : widget.alternativeName.tr.toUpperCase(),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
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
              ],
            ),
            actions: [
              ValueListenableBuilder(
                valueListenable: selectMode,
                child: Row(
                  children: <Widget>[
                    if (_appMediaItems.isNotEmpty && _appMediaItems.firstWhereOrNull((element) => element.mediaSource != AppMediaSource.internal) == null)
                      MultiDownloadButton(
                        data: _appMediaItems.map((e) => e.toJSON()).toList(),
                        playlistName: widget.itemlist != null
                            ? widget.itemlist!.name.toUpperCase()
                            : widget.alternativeName.toUpperCase(),),                    
                    if (_currentTabIndex == 0)
                      PopupMenuButton(
                        icon: const Icon(Icons.sort_rounded),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        ),
                        onSelected:
                            // (currentIndex == 0) ?
                            (int value) {
                          if (value < 5) {
                            sortValue = value;
                            Hive.box(AppHiveConstants.settings).put('sortValue', value);
                          } else {
                            orderValue = value - 5;
                            Hive.box(AppHiveConstants.settings).put('orderValue', orderValue);
                          }
                          _appMediaItems = NeomAudioUtilities.sortSongs(
                            _appMediaItems,
                            sortVal: sortValue,
                            order: orderValue,
                          );
                          setState(() {});
                        },
                        itemBuilder: (context) {
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
                                                Brightness.dark ? Colors.white : Colors.grey[700],) 
                                        else
                                          const SizedBox(),
                                        const SizedBox(width: 10),
                                        Text(e,),
                                      ],
                                    ),
                                  ),
                                ).toList(),
                          );
                          menuList.add(const PopupMenuDivider(height: 10,),);
                          menuList.addAll(
                            orderTypes
                                .map(
                                  (e) => PopupMenuItem(value: sortTypes.length + orderTypes.indexOf(e),
                                    child: Row(
                                      children: [
                                        if (orderValue == orderTypes.indexOf(e))
                                          Icon(Icons.check_rounded,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white : Colors.grey[700],)
                                        else
                                          const SizedBox(),
                                        const SizedBox(width: 10),
                                        Text(
                                          e,
                                        ),
                                      ],
                                    ),
                                  ),
                                ).toList(),
                          );
                          return menuList;
                        },
                      ),
                  ],
                ),
                builder: (
                  BuildContext context,
                  bool showValue,
                  Widget? child,
                ) {
                  return showValue
                      ? Row(
                          children: [
                            MultiDownloadButton(
                              data: _appMediaItems
                                  .where(
                                    (element) =>
                                        selectedItems.contains(element.id),
                                  )
                                  .toList(),
                              playlistName: widget.itemlist != null
                                  ? widget.itemlist!.name.toUpperCase()
                                  : widget.alternativeName.toUpperCase(),
                            ),
                            IconButton(
                              onPressed: () {
                                selectedItems.clear();
                                selectMode.value = false;
                              },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                          ],
                  ) : child!;
                },
              ),
            ],
          ),
          body: TabBarView(
            physics: const CustomPhysics(),
            controller: _tcontroller,
            children: [
              SongsPageTab(
                appMediaItems: _appMediaItems,
                onDelete: (AppMediaItem item) {
                  deleteLiked(item);
                  },
                playlistName: widget.itemlist?.name ?? '',
                scrollController: _scrollController,
              ),
            ],
          ),
          floatingActionButton: ValueListenableBuilder(
            valueListenable: _showShuffle,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).cardColor,
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
        ),
      ),
    );
  }

}
