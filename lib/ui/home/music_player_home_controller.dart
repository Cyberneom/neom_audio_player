
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';

import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';


class MusicPlayerHomeController extends GetxController {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  final Rxn<MediaItem> _mediaItem = Rxn<MediaItem>();
  MediaItem? get mediaItem => _mediaItem.value;
  set mediaItem(MediaItem? mediaItem) => _mediaItem.value = mediaItem;
  // final Rx<MediaItem> _itemlists = <Itemlist>.obs;
  // Map<String, Itemlist> get itemlists => _itemlists;
  // set itemlists(Map<String, Itemlist> itemlists) => _itemlists.value = itemlists;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  List preferredLanguage = Hive.box(AppHiveConstants.settings).get('preferredLanguage', defaultValue: ['Español']) as List;
  List likedRadio = Hive.box(AppHiveConstants.settings).get('likedRadio', defaultValue: []) as List;
  Map<String, Itemlist> itemLists = {};

  List recentSongs = Hive.box(AppHiveConstants.cache).get('recentSongs', defaultValue: []) as List;
  Map<String, AppMediaItem> recentList = {};
  Map<String, Itemlist> myItemLists = {};
  Map<String, Itemlist> publicItemlists = {};
  int recentIndex = 0;
  int playlistIndex = 1;

  // Map data = Hive.box(AppHiveConstants.cache).get('homepage', defaultValue: {}) as Map;
  // Map likedArtists = Hive.box(AppHiveConstants.settings).get('likedArtists', defaultValue: {}) as Map;
  // List playlistNames = Hive.box(AppHiveConstants.settings).get('playlistNames')?.toList() as List? ?? [AppHiveConstants.favoriteSongs];
  // Map playlistDetails = Hive.box(AppHiveConstants.settings).get('playlistDetails', defaultValue: {}) as Map;

  @override
  void onInit() async {
    super.onInit();
    logger.d("Music Player Home Controller Init");
    await getHomePageData();
    try {

    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    try {
      if(recentSongs.isNotEmpty) {
        logger.d("Retrieving recent songs from Hive.");
        for (final element in recentSongs) {
          AppMediaItem recentMediaItem = AppMediaItem.fromJSON(element);
          recentList[recentMediaItem.id] = recentMediaItem;
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    isLoading = false;
    update();
  }

  Future<void> getHomePageData() async {
    AppUtilities.logger.i("Get ItemLists Home Data");

    final userController = Get.find<UserController>();

    try {
      myItemLists = await ItemlistFirestore().fetchAll(profileId: userController.profile.id);
      publicItemlists = await ItemlistFirestore().fetchAll(excludeMyFavorites: false, minItems: 2);
      for (final myItemlist in myItemLists.values) {
        publicItemlists.removeWhere((key, publicList) => myItemlist.id == publicList.id);
      }
      myItemLists.addAll(publicItemlists);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }


    List<Itemlist> sortedList = publicItemlists.values.toList();
    sortedList.sort((a, b) => b.getTotalItems().compareTo(a.getTotalItems()));
    publicItemlists.clear();

    for (var sortedItem in sortedList) {
      publicItemlists[sortedItem.id] = sortedItem;
    }

    update();
  }

  void clear() {
  }

  // void setMediaItem(MediaItem item) {
  //   AppUtilities.logger.i("Setting new mediaitem)");
  //   mediaItem = item;
  //   update();
  // }

}
