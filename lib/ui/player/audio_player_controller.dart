import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyric_ui/ui_netease.dart';
import 'package:flutter_lyric/lyrics_model_builder.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:get/get.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_commons/utils/share_utilities.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/validator.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../../data/implementations/player_hive_controller.dart';
import '../../domain/models/media_lyrics.dart';
import '../../domain/use_cases/audio_player_service.dart';
import '../../neom_audio_handler.dart';
import '../../audio_player_invoker.dart';
import '../../utils/mappers/media_item_mapper.dart';
import '../library/playlist_player_page.dart';
import 'lyrics/lyrics.dart';

class AudioPlayerController extends GetxController implements AudioPlayerService {

  final userServiceImpl = Get.find<UserService>();
  NeomAudioHandler? audioHandler;

  AppUser user = AppUser();
  AppProfile profile = AppProfile();

  Rxn<MediaItem> mediaItem = Rxn<MediaItem>();
  Rx<AppMediaItem> appMediaItem = AppMediaItem().obs;

  RxString mediaItemTitle = ''.obs;
  RxString mediaItemArtist = ''.obs;
  RxString mediaItemAlbum = ''.obs;

  RxBool isLoading = true.obs;
  RxBool isLoadingAudio = true.obs;
  RxBool isButtonDisabled = false.obs;
  RxBool isSharePopupShown = false.obs;
  bool reproduceItem = true;

  bool offline = false;
  Itemlist? personalPlaylist;
  Itemlist? releaseItemlist;

  bool getLyricsOnline = false;
  final PanelController panelController = PanelController();

  GlobalKey<FlipCardState> onlineCardKey = GlobalKey<FlipCardState>();
  final Duration time = Duration.zero;
  int mediaItemDuration = 10;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t('onInit MediaPlayer Controller');

    try {
      user = userServiceImpl.user;
      profile = userServiceImpl.profile;

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if (Get.arguments[0] is AppReleaseItem) {
          initReleaseItem(Get.arguments[0]);
        } else if (Get.arguments[0] is AppMediaItem) {
          initAppMediaItem(Get.arguments[0]);
        } else if (Get.arguments[0] is String) {
          ///VERIFY IF USEFUL
          ///appMediaItemId = arguments[0];???
        }

        if(Get.arguments.length > 1) {
          reproduceItem = Get.arguments[1] as bool;
        }
      }

      getItemPlaylist();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void initReleaseItem(AppReleaseItem item) {
    appMediaItem.value = AppMediaItemMapper.fromAppReleaseItem(item);
    if(appMediaItem.value.artist.contains(' - ')) {
      appMediaItem.value.album = TextUtilities.getMediaName(appMediaItem.value.artist);
      appMediaItem.value.artist = TextUtilities.getArtistName(appMediaItem.value.artist);
    }
    updateMediaItemValues();
  }

  @override
  void initAppMediaItem(AppMediaItem item) {
    appMediaItem.value = item;
    updateMediaItemValues();
  }

  @override
  void onReady() {
    super.onReady();
    isLoading.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        Get.find<AudioPlayerInvoker>().getOrInitAudioHandler().then((NeomAudioHandler? handler) async {
          audioHandler = handler;
          bool alreadyPlaying = audioHandler?.currentMediaItem?.id == appMediaItem.value.id;
          if(reproduceItem && !alreadyPlaying) {
            await Get.find<AudioPlayerInvokerService>().init(
              appMediaItems: [appMediaItem.value],
              index: 0,
            );
          }
          isLoadingAudio.value = false;
        });

        getLyricsOnline = PlayerHiveController().getLyricsOnline;
      } catch (e) {
        AppConfig.logger.e(e.toString());
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    appMediaItem.value = AppMediaItem();
    isLoading.value = true;
    update();
  }

  @override
  void clear() {

  }

  @override
  Future<void> getItemPlaylist() async {

    if(profile.itemlists?.isEmpty ?? true) profile.itemlists = await ItemlistFirestore().getByOwnerId(profile.id);

    for(Itemlist list in profile.itemlists?.values ?? {}) {
      if(list.appReleaseItems?.firstWhereOrNull((item) => item.id == appMediaItem.value.id) != null){
        personalPlaylist= list;
        break;
      }
      if(list.appMediaItems?.firstWhereOrNull((item) => item.id == appMediaItem.value.id) != null){
        personalPlaylist= list;
        break;
      }
    }

    for(Itemlist list in AppConfig.instance.releaseItemlists.values) {
      if(list.appReleaseItems?.firstWhereOrNull((item) => item.id == appMediaItem.value.id) != null){
        releaseItemlist = list;
        break;
      }
      if(list.appMediaItems?.firstWhereOrNull((item) => item.id == appMediaItem.value.id) != null){
        releaseItemlist= list;
        break;
      }
    }
  }

  @override
  void gotoPlaylistPlayer() {
    getItemPlaylist();
    Get.to(() => PlaylistPlayerPage(itemlist: releaseItemlist));
  }

  @override
  void setMediaItem({MediaItem? item, AppMediaItem? appItem}) {
    AppConfig.logger.i('Setting new mediaitem ${item?.title}');
    if(item != null) {
      mediaItem.value = item;
      appMediaItem.value = appItem ?? MediaItemMapper.toAppMediaItem(item);
    } else if(appItem != null) {
      mediaItem.value= MediaItemMapper.fromAppMediaItem(appMediaItem:appItem);
      appMediaItem.value = appItem;
    }

    updateMediaItemValues();
    update();
  }

  @override
  void updateMediaItemValues() {
    mediaItemTitle.value = appMediaItem.value.name;
    mediaItemArtist.value = appMediaItem.value.artist;
    mediaItemAlbum.value = appMediaItem.value.album;
    if(mediaItemTitle.contains(' - ')) {
      mediaItemTitle.value = TextUtilities.getMediaName(appMediaItem.value.name);
      if(appMediaItem.value.artist.isEmpty) {
        mediaItemArtist.value = TextUtilities.getArtistName(appMediaItem.value.name);
      }
    }

    if(mediaItem.value == null) {
      mediaItem.value= MediaItemMapper.fromAppMediaItem(appMediaItem:appMediaItem.value);
    }
  }

  @override
  void toggleLyricsCard() {
    onlineCardKey.currentState!.toggleCard();
    setFlipped(!flipped);
    update([AppPageIdConstants.mediaPlayer]);
  }

  @override
  void setFlipped(bool value) {
    flipped = value;
    if (flipped && mediaLyrics.mediaId != appMediaItem.value.id) {
      fetchLyrics();
    }
    update([AppPageIdConstants.mediaPlayer]);
  }

  @override
  Future<void> sharePopUp() async {
    if (!isSharePopupShown.value) {
      isSharePopupShown.value = true;
      final AppMediaItem item = MediaItemMapper.toAppMediaItem(mediaItem.value!);
      await ShareUtilities.shareAppWithMediaItem(item).whenComplete(() {
        Timer(const Duration(milliseconds: 600), () {
          isSharePopupShown.value = false;
        });
      });
    }
    update([AppPageIdConstants.mediaPlayer]);
  }

  @override
  void goToTimeline(BuildContext context) {
    Get.back();
    update();
  }

  final ValueNotifier<bool> dragging = ValueNotifier<bool>(false);
  final ValueNotifier<bool> tapped = ValueNotifier<bool>(false);
  final ValueNotifier<int> doubleTapped = ValueNotifier<int>(0);
  final ValueNotifier<bool> done = ValueNotifier<bool>(false);
  final ValueNotifier<String> lyricsSource = ValueNotifier<String>('');

  MediaLyrics mediaLyrics = MediaLyrics();
  
  final lyricUI = UINetease();
  LyricsReaderModel? lyricsReaderModel;
  bool flipped = false;

  @override
  Future<void> fetchLyrics() async {
    AppConfig.logger.i('Fetching lyrics for ${appMediaItem.value.name}');
    done.value = false;
    lyricsSource.value = '';
    String appMediaItemLyric = appMediaItem.value.lyrics.isNotEmpty || (appMediaItem.value.description?.isNotEmpty ?? false)  ? (appMediaItem.value.lyrics.isNotEmpty ? appMediaItem.value.lyrics : appMediaItem.value.description ?? '') : '';
    if (appMediaItemLyric.isNotEmpty || offline) {
      mediaLyrics.lyrics = appMediaItemLyric.replaceAll('&nbsp;', '');
      mediaLyrics.mediaId = appMediaItem.value.id;
    } else {
      mediaLyrics = await Lyrics.getLyrics(id: appMediaItem.value.id,
        title: appMediaItem.value.name, artist: appMediaItem.value.artist.toString(),);
    }

    lyricsSource.value = mediaLyrics.source.name;
    lyricsReaderModel = LyricsModelBuilder.create().bindLyricToMain(mediaLyrics.lyrics).getModel();
    done.value = true;
  }

  @override
  void goToOwnerProfile() async {
    AppConfig.logger.i('goToOwnerProfile for ${appMediaItem.value.artistId}');

    String ownerId = appMediaItem.value.artistId ?? '';

    try {
      if(profile.id == ownerId || user.email == ownerId) {
        Get.toNamed(AppRouteConstants.profile);
      } else {

        bool isEmail = Validator.isEmail(ownerId);

        if(isEmail) {
          AppUser? bookUser = await UserFirestore().getByEmail(ownerId);
          List<AppProfile> bookUserProfiles = await ProfileFirestore().retrieveByUserId(bookUser?.id ?? '');
          ownerId = bookUserProfiles.isNotEmpty ? bookUserProfiles.first.id : '';
        }

        if(ownerId.isNotEmpty && ownerId.length > 5) {
          Get.toNamed(AppRouteConstants.mateDetails, arguments: ownerId);
        } else {
          AppUtilities.showSnackBar(message: CommonTranslationConstants.noItemOwnerFound.tr);
        }

      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  bool isOffline() {
    return !(mediaItem.value?.extras!['url'].toString() ?? '').startsWith('http');
  }

  @override
  void setIsLoadingAudio(bool loading) {
    isLoadingAudio.value = loading;
  }

}
