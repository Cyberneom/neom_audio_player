import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';

import '../../data/implementations/player_hive_controller.dart';

class AudioPlayerHomeController extends GetxController {

  final userServiceImpl = Get.find<UserService>();
  final ScrollController scrollController = ScrollController();

  final Rxn<MediaItem> mediaItem = Rxn<MediaItem>();
  final RxBool isLoading = true.obs;
  final RxBool showSearchBarLeading = false.obs;

  List preferredLanguage = [];
  Map<String, Itemlist> itemLists = {};

  List? recentSongs;
  RxMap<String, AppMediaItem> recentList = <String, AppMediaItem>{}.obs;
  RxMap<String, Itemlist> myItemLists = <String, Itemlist>{}.obs;
  RxMap<String, Itemlist> publicItemlists = <String, Itemlist>{}.obs;
  RxMap<String, Itemlist> releaseItemlists = <String, Itemlist>{}.obs;

  int recentIndex = 0;
  int myPlaylistsIndex = 1;
  int favoriteItemsIndex = 2;
  int lastReleasesIndex = 3;
  int previousIndex = 4;

  AppProfile profile = AppProfile();
  RxMap<String, AppMediaItem> globalMediaItems = <String, AppMediaItem>{}.obs;
  RxList<AppMediaItem> favoriteItems = <AppMediaItem>[].obs;
  Box? settingsBox;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t('Music Player Home Controller Init');
    try {
      profile = userServiceImpl.profile;
      releaseItemlists.value =  AppConfig.instance.releaseItemlists;
      scrollController.addListener(_scrollListener);
      AppConfig.instance.defaultItemlistType = ItemlistType.playlist;
      initializeAudioPlayerHome();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  void onReady() {
    super.onReady();
    try {
      getPublicItemlists();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  Future<void> initializeAudioPlayerHome() async {
    AppConfig.logger.d('Initializing Audio Player Home Controller...');

    try {
      myItemLists.value = profile.itemlists ?? {};
      myItemLists.removeWhere((key, publicList) => publicList.type == ItemlistType.readlist);
      myItemLists.removeWhere((key, publicList) => publicList.type == ItemlistType.giglist);

      recentSongs = Hive.box(AppHiveBox.player.name).get(AppHiveConstants.recentSongs, defaultValue: []) as List;

      if(recentSongs?.isNotEmpty ?? false) {
        AppConfig.logger.d('Retrieving recent songs from Hive.');
        for (final element in recentSongs ?? []) {
          AppMediaItem recentMediaItem = AppMediaItem.fromJSON(element);
          recentList[recentMediaItem.id] = recentMediaItem;
          AppConfig.logger.t('Recent song: ${recentMediaItem.name}');
        }
      }

      globalMediaItems.value = await AppMediaItemFirestore().fetchAll(
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
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
  }

  @override
  void dispose() {
    scrollController.dispose();
    scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  Future<void> getPublicItemlists() async {
    AppConfig.logger.d('Fetching public itemlists...');

    try {
      publicItemlists.value = await ItemlistFirestore().fetchAll(
          excludeFromProfileId: profile.id,
          itemlistType: ItemlistType.playlist
      );

      publicItemlists.removeWhere((key, publicList) => publicList.type == ItemlistType.readlist
          || publicList.type == ItemlistType.giglist);
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
    List<Itemlist> sortedList = publicItemlists.values.toList();
    sortedList.sort((a, b) => b.getTotalItems().compareTo(a.getTotalItems()));
    publicItemlists.clear();

    for (var sortedItem in sortedList) {
      publicItemlists[sortedItem.id] = sortedItem;
    }

    AppConfig.logger.d('${publicItemlists.length} public itemlists fetched.');
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
