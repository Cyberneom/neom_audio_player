import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:sint/sint.dart';
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

import '../../data/hive/catalog_cache_controller.dart';
import '../../data/implementations/player_hive_controller.dart';

class AudioPlayerHomeController extends SintController {

  final userServiceImpl = Sint.find<UserService>();
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

  // Offline support
  final CatalogCacheController _catalogCache = CatalogCacheController();
  RxBool isOfflineMode = false.obs;

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
      // OPTIMIZATION: Defer public itemlists loading to after UI is ready
      Future.delayed(const Duration(milliseconds: 800), () {
        getPublicItemlists();
      });
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

      // Load cached data first for instant UI
      await _loadCachedCatalog();

      // Try to fetch fresh data
      await _fetchGlobalMediaItems();

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

  /// Load cached catalog data for instant UI.
  Future<void> _loadCachedCatalog() async {
    try {
      // Load cached media items
      final cachedMediaItems = await _catalogCache.getCachedMediaItems();
      if (cachedMediaItems.isNotEmpty && globalMediaItems.isEmpty) {
        globalMediaItems.value = cachedMediaItems;
        AppConfig.logger.d('Loaded ${cachedMediaItems.length} cached media items');
      }

      // Load cached release itemlists
      final cachedReleases = await _catalogCache.getCachedReleaseItemlists();
      if (cachedReleases.isNotEmpty && releaseItemlists.isEmpty) {
        releaseItemlists.value = cachedReleases;
        AppConfig.logger.d('Loaded ${cachedReleases.length} cached release itemlists');
      }
    } catch (e) {
      AppConfig.logger.e('Error loading cached catalog: $e');
    }
  }

  /// OPTIMIZED: Fetch global media items with pagination and offline fallback.
  /// Only loads first batch initially, more can be loaded on demand.
  Future<void> _fetchGlobalMediaItems({int limit = 50}) async {
    try {
      final isOnline = await _catalogCache.isOnline();

      if (!isOnline) {
        AppConfig.logger.d('Offline mode - using cached media items');
        isOfflineMode.value = true;
        return;
      }

      isOfflineMode.value = false;

      // OPTIMIZATION: Only load first 50 items instead of ALL
      globalMediaItems.value = await AppMediaItemFirestore().fetchAll(
          excludeTypes: [MediaItemType.pdf, MediaItemType.neomPreset],
          limit: limit,
      );

      // Cache for offline access
      await _catalogCache.cacheMediaItems(globalMediaItems.value);

      AppConfig.logger.d('Fetched and cached ${globalMediaItems.length} media items (limit: $limit)');
    } catch (e) {
      AppConfig.logger.e('Error fetching media items: $e');
      isOfflineMode.value = true;
    }
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
      // Load cached public itemlists first
      final cachedItemlists = await _catalogCache.getCachedPublicItemlists();
      if (cachedItemlists.isNotEmpty && publicItemlists.isEmpty) {
        publicItemlists.value = cachedItemlists;
        AppConfig.logger.d('Loaded ${cachedItemlists.length} cached public itemlists');
      }

      // Check if online
      final isOnline = await _catalogCache.isOnline();
      if (!isOnline) {
        AppConfig.logger.d('Offline mode - using cached public itemlists');
        isOfflineMode.value = true;
        return;
      }

      isOfflineMode.value = false;

      publicItemlists.value = await ItemlistFirestore().fetchAll(
          excludeFromProfileId: profile.id,
          itemlistType: ItemlistType.playlist
      );

      publicItemlists.removeWhere((key, publicList) => publicList.type == ItemlistType.readlist
          || publicList.type == ItemlistType.giglist);

      // Sort by total items
      List<Itemlist> sortedList = publicItemlists.values.toList();
      sortedList.sort((a, b) => b.getTotalItems().compareTo(a.getTotalItems()));
      publicItemlists.clear();

      for (var sortedItem in sortedList) {
        publicItemlists[sortedItem.id] = sortedItem;
      }

      // Cache for offline access
      await _catalogCache.cachePublicItemlists(publicItemlists.value);

      AppConfig.logger.d('Fetched and cached ${publicItemlists.length} public itemlists');
    } catch(e) {
      AppConfig.logger.e(e.toString());
      isOfflineMode.value = true;
    }
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
