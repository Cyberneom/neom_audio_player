
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/itemlist_type.dart';
import 'package:neom_itemlists/itemlists/data/firestore/app_media_item_firestore.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';


class MusicPlayerHomeController extends GetxController {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();
  final ScrollController scrollController = ScrollController();

  final Rxn<MediaItem> _mediaItem = Rxn<MediaItem>();
  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;

  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  List preferredLanguage = Hive.box(AppHiveConstants.settings).get('preferredLanguage', defaultValue: ['Español']) as List;
  List likedRadio = Hive.box(AppHiveConstants.settings).get('likedRadio', defaultValue: []) as List;
  Map<String, Itemlist> itemLists = {};

  List recentSongs = Hive.box(AppHiveConstants.cache).get('recentSongs', defaultValue: []) as List;
  Map<String, AppMediaItem> recentList = {};
  Map<String, Itemlist> myItemLists = {};
  Map<String, Itemlist> publicItemlists = {};
  int recentIndex = 0;
  int myPlaylistsIndex = 1;
  int favoriteItemsIndex = 2;

  AppProfile profile = AppProfile();
  Map<String, AppMediaItem> globalMediaItems = {};
  List<AppMediaItem> favoriteItems = [];
  // Map data = Hive.box(AppHiveConstants.cache).get('homepage', defaultValue: {}) as Map;
  // Map likedArtists = Hive.box(AppHiveConstants.settings).get('likedArtists', defaultValue: {}) as Map;
  // List playlistNames = Hive.box(AppHiveConstants.settings).get('playlistNames')?.toList() as List? ?? [AppHiveConstants.favoriteSongs];
  // Map playlistDetails = Hive.box(AppHiveConstants.settings).get('playlistDetails', defaultValue: {}) as Map;

  @override
  void onInit() async {
    super.onInit();
    logger.d('Music Player Home Controller Init');
    try {
      final userController = Get.find<UserController>();
      profile = userController.profile;
      await getHomePageData();
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    try {
      if(recentSongs.isNotEmpty) {
        logger.d('Retrieving recent songs from Hive.');
        for (final element in recentSongs) {
          AppMediaItem recentMediaItem = AppMediaItem.fromJSON(element);
          recentList[recentMediaItem.id] = recentMediaItem;
        }
      }

      globalMediaItems = await AppMediaItemFirestore().fetchAll();

      profile.favoriteItems?.forEach((favItem) {
        if(globalMediaItems.containsKey(favItem)) {
          AppMediaItem globalItem = globalMediaItems.values.firstWhere((item) => favItem == item.id);
          favoriteItems.add(globalItem);
        }
      });
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    isLoading.value = false;
    update([AppPageIdConstants.musicPlayerHome]);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> getHomePageData() async {
    AppUtilities.logger.i('Get ItemLists Home Data');
    try {
      myItemLists = await ItemlistFirestore().fetchAll(profileId: profile.id);
      publicItemlists = await ItemlistFirestore().fetchAll(excludeMyFavorites: true, minItems: 0);
      for (final myItemlist in myItemLists.values) {
        publicItemlists.removeWhere((key, publicList) => myItemlist.id == publicList.id);
      }
      myItemLists.addAll(publicItemlists);

      ///IMPROVE WAY TO SPLIT PLAYLISTS AND GIGLISTS FROM CHAMBERPRESETS AND READLISTS
      myItemLists.removeWhere((key, publicList) => publicList.type == ItemlistType.chamberPresets || publicList.type == ItemlistType.readlist);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    List<Itemlist> sortedList = publicItemlists.values.toList();
    sortedList.sort((a, b) => b.getTotalItems().compareTo(a.getTotalItems()));
    publicItemlists.clear();

    for (var sortedItem in sortedList) {
      publicItemlists[sortedItem.id] = sortedItem;
    }

    update([AppPageIdConstants.musicPlayerHome]);
  }

  void clear() {
  }

  // void setMediaItem(MediaItem item) {
  //   AppUtilities.logger.i("Setting new mediaitem)");
  //   mediaItem = item;
  //   update();
  // }

}
