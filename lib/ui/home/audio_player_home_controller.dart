import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_commons/core/data/implementations/app_hive_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_hive_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';
import 'package:neom_commons/core/utils/enums/itemlist_type.dart';
import 'package:neom_commons/core/utils/enums/media_item_type.dart';

import '../../data/implementations/player_hive_controller.dart';

class AudioPlayerHomeController extends GetxController {

  final userController = Get.find<UserController>();
  final ScrollController scrollController = ScrollController();

  final Rxn<MediaItem> mediaItem = Rxn<MediaItem>();
  final RxBool isLoading = true.obs;
  final RxBool showSearchBarLeading = false.obs;

  List preferredLanguage = [];
  Map<String, Itemlist> itemLists = {};

  List recentSongs = Hive.box(AppHiveBox.player.name).get(AppHiveConstants.recentSongs, defaultValue: []) as List;
  Map<String, AppMediaItem> recentList = {};
  Map<String, Itemlist> myItemLists = {};
  Map<String, Itemlist> publicItemlists = {};
  Map<String, Itemlist> releaseItemlists = {};

  int recentIndex = 0;
  int myPlaylistsIndex = 1;
  int favoriteItemsIndex = 2;
  int lastReleasesIndex = 3;
  int previousIndex = 4;

  AppProfile profile = AppProfile();
  Map<String, AppMediaItem> globalMediaItems = {};
  List<AppMediaItem> favoriteItems = [];
  Box? settingsBox;

  @override
  void onInit() {
    super.onInit();
    AppUtilities.logger.t('Music Player Home Controller Init');
    try {
      profile = userController.profile;
      releaseItemlists =  userController.releaseItemlists;
      scrollController.addListener(_scrollListener);
      getHomePageData();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  void onReady() {
    super.onReady();
    try {
      initializeAudioPlayerHome();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    userController.defaultItemlistType = ItemlistType.playlist;
    isLoading.value = false;
    // update([AppPageIdConstants.audioPlayerHome]);
  }

  Future<void> initializeAudioPlayerHome() async {
    if(recentSongs.isNotEmpty) {
      AppUtilities.logger.d('Retrieving recent songs from Hive.');
      for (final element in recentSongs) {
        AppMediaItem recentMediaItem = AppMediaItem.fromJSON(element);
        recentList[recentMediaItem.id] = recentMediaItem;
        AppUtilities.logger.d('Recent song: ${recentMediaItem.name}');
      }
    }

    globalMediaItems = await AppMediaItemFirestore().fetchAll(
      excludeTypes: [MediaItemType.pdf, MediaItemType.neomPreset]
    );

    profile.favoriteItems?.forEach((favItem) {
      if(globalMediaItems.containsKey(favItem)) {
        AppMediaItem globalItem = globalMediaItems.values.firstWhere((item) => favItem == item.id);
        favoriteItems.add(globalItem);
      }
    });

    preferredLanguage = PlayerHiveController().preferredLanguage;
    settingsBox = await AppHiveController().getBox(AppHiveBox.settings.name);
  }

  @override
  void dispose() {
    scrollController.dispose();
    scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  Future<void> getHomePageData() async {
    AppUtilities.logger.d('Fetching home page data...');
    try {
      myItemLists = profile.itemlists ?? {};
      myItemLists.removeWhere((key, publicList) => publicList.type == ItemlistType.readlist);
      myItemLists.removeWhere((key, publicList) => publicList.type == ItemlistType.giglist);

      publicItemlists = await ItemlistFirestore().fetchAll(
          excludeFromProfileId: profile.id,
          itemlistType: ItemlistType.playlist
      );

      publicItemlists.removeWhere((key, publicList) => publicList.type == ItemlistType.readlist
          || publicList.type == ItemlistType.giglist);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    List<Itemlist> sortedList = publicItemlists.values.toList();
    sortedList.sort((a, b) => b.getTotalItems().compareTo(a.getTotalItems()));
    publicItemlists.clear();

    for (var sortedItem in sortedList) {
      publicItemlists[sortedItem.id] = sortedItem;
    }

    AppUtilities.logger.d('${publicItemlists.length} public itemlists fetched.');
  }

  void clear() {

  }


  void _scrollListener() {
    if (scrollController.offset > 70) {
      showSearchBarLeading.value = true;
    } else {
      showSearchBarLeading.value = false;
    }
    update([AppPageIdConstants.audioPlayerHome]);
  }

}
