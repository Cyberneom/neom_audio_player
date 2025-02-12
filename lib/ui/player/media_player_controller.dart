import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyric_ui/ui_netease.dart';
import 'package:flutter_lyric/lyrics_model_builder.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:get/get.dart';
// ignore: unused_import
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:sliding_up_panel/sliding_up_panel.dart';

// ignore: unused_import
import '../../data/providers/neom_audio_provider.dart';
import '../../domain/entities/media_lyrics.dart';
import '../../domain/entities/position_data.dart';
import '../../domain/use_cases/neom_audio_handler.dart';
import '../../neom_player_invoker.dart';
import 'package:neom_commons/core/utils/constants/app_hive_constants.dart';
import '../../utils/helpers/media_item_mapper.dart';
import '../../utils/neom_audio_utilities.dart';
import '../library/playlist_player_page.dart';
import 'lyrics/lyrics.dart';

class MediaPlayerController extends GetxController {

  final userController = Get.find<UserController>();
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

  final bool getLyricsOnline = Hive.box(AppHiveBox.settings.name).get('getLyricsOnline', defaultValue: true) as bool;
  final PanelController panelController = PanelController();

  GlobalKey<FlipCardState> onlineCardKey = GlobalKey<FlipCardState>();
  final Duration time = Duration.zero;
  int mediaItemDuration = 10;


  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t('onInit MediaPlayer Controller');

    try {
      user = userController.user;
      profile = userController.profile;

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if (Get.arguments[0] is AppReleaseItem) {
          appMediaItem.value = AppMediaItem.fromAppReleaseItem(Get.arguments[0]);
          if(appMediaItem.value.artist.contains(' - ')) {
            appMediaItem.value.album = AppUtilities.getMediaName(appMediaItem.value.artist);
            appMediaItem.value.artist = AppUtilities.getArtistName(appMediaItem.value.artist);
          }
        } else if (Get.arguments[0] is AppMediaItem) {
          appMediaItem.value =  Get.arguments.elementAt(0);
        } else if (Get.arguments[0] is String) {
          ///VERIFY IF USEFUL
          ///appMediaItemId = arguments[0];???
        }

        if(Get.arguments.length > 1) {
          reproduceItem = Get.arguments[1] as bool;
        }
      }
      updateMediaItemValues();
      getItemPlaylist();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    isLoading.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        NeomAudioUtilities.getAudioHandler().then((handler) async {
          audioHandler = handler;
          bool alreadyPlaying = audioHandler?.currentMediaItem?.id == appMediaItem.value.id;
          if(reproduceItem && !alreadyPlaying) {
            await NeomPlayerInvoker.init(
              appMediaItems: [appMediaItem.value],
              index: 0,
            );
          } else {
            isLoadingAudio.value = false;
          }
        });
      } catch (e) {
        AppUtilities.logger.e(e.toString());
      }
    });
  }


  void clear() {

  }

  void getItemPlaylist() {
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

    for(Itemlist list in userController.releaseItemlists.values) {
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

  void gotoPlaylistPlayer() {
    getItemPlaylist();
    Get.to(() => PlaylistPlayerPage(itemlist: releaseItemlist));
  }

  ///DEPRECATED
  void setMediaItem({MediaItem? item, AppMediaItem? appItem}) {
    AppUtilities.logger.i('Setting new mediaitem ${item?.title}');
    if(item != null) {
      mediaItem.value = item;
      appMediaItem.value = appItem ?? MediaItemMapper.fromMediaItem(item);
    } else if(appItem != null) {
      mediaItem.value= MediaItemMapper.appMediaItemToMediaItem(appMediaItem:appItem);
      appMediaItem.value = appItem;
    }

    updateMediaItemValues();
    update();
  }

  void updateMediaItemValues() {
    mediaItemTitle.value = appMediaItem.value?.name ?? '';
    mediaItemArtist.value = appMediaItem.value.artist ?? '';
    mediaItemAlbum.value = appMediaItem.value?.album ?? '';
    if(mediaItemTitle.contains(' - ')) {
      mediaItemTitle.value = AppUtilities.getMediaName(appMediaItem.value!.name);
      if(appMediaItem.value?.artist?.isEmpty ?? true) {
        mediaItemArtist.value = AppUtilities.getArtistName(appMediaItem.value!.name);
      }
    }
  }

  void toggleLyricsCard() {
    onlineCardKey.currentState!.toggleCard();
    setFlipped(!flipped);
    update([AppPageIdConstants.mediaPlayer]);
  }

  void setFlipped(bool value) {
    flipped = value;
    if (flipped && mediaLyrics.mediaId != appMediaItem.value.id) {
      fetchLyrics();
    }
    update([AppPageIdConstants.mediaPlayer]);
  }

  Future<void> sharePopUp() async {
    if (!isSharePopupShown.value) {
      isSharePopupShown.value = true;
      final AppMediaItem item = MediaItemMapper.fromMediaItem(mediaItem.value!);
      await CoreUtilities().shareAppWithMediaItem(item).whenComplete(() {
        Timer(const Duration(milliseconds: 600), () {
          isSharePopupShown.value = false;
        });
      });
    }
    update([AppPageIdConstants.mediaPlayer]);
  }

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

  Future<void> fetchLyrics() async {
    AppUtilities.logger.i('Fetching lyrics for ${appMediaItem.value.name}');
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
    // update([AppPageIdConstants.mediaPlayer]);
  }

  Stream<Duration> get bufferedPositionStream => audioHandler?.playbackState.map((state) => state.bufferedPosition).distinct() ?? Stream.value(Duration.zero);
  Stream<Duration?> get durationStream => audioHandler?.mediaItem.map((item) => item?.duration).distinct() ?? Stream.value(Duration.zero);
  Stream<PositionData> get positionDataStream => rx.Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        AudioService.position, bufferedPositionStream, durationStream,
        (position, bufferedPosition, duration) => PositionData(position, bufferedPosition, duration ?? Duration.zero),
  );

  void goToOwnerProfile() async {
    AppUtilities.logger.i('goToOwnerProfile for ${appMediaItem.value.artistId}');

    String ownerId = appMediaItem.value.artistId ?? '';

    try {
      if(profile.id == ownerId || user.email == ownerId) {
        Get.toNamed(AppRouteConstants.profile);
      } else {

        bool isEmail = Validator.isEmail(ownerId);

        if(isEmail) {
          AppUser? bookUser = await UserFirestore().getByEmail(ownerId);
          List<AppProfile> bookUserProfiles = await ProfileFirestore().retrieveProfiles(bookUser?.id ?? '');
          ownerId = bookUserProfiles.isNotEmpty ? bookUserProfiles.first.id : '';
        }

        if(ownerId.isNotEmpty && ownerId.length > 5) {
          Get.toNamed(AppRouteConstants.mateDetails, arguments: ownerId);
        } else {
          AppUtilities.showSnackBar(message: AppTranslationConstants.noItemOwnerFound.tr);
        }

      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  bool isOffline() {
    // mediaItem = MediaItemMapper.appMediaItemToMediaItem(appMediaItem: _.appMediaItem.value);
    return !(mediaItem.value?.extras!['url'].toString() ?? '').startsWith('http');
  }

  void setIsLoadingAudio(bool loading) {
    isLoadingAudio.value = loading;
  }


///DEPRECATED
// Widget createPopMenuOption(BuildContext context, AppMediaItem appMediaItem, {bool offline = false}) {
//   return PopupMenuButton(
//     icon: const Icon(Icons.more_vert_rounded,color: AppColor.white),
//     color: AppColor.getMain(),
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.all(
//         Radius.circular(15.0),
//       ),
//     ),
//     onSelected: (int? value) {
//       if(value != null) {
//         AudioPlayerUtilities.onSelectedPopUpMenu(context, value, appMediaItem, Duration.zero);
//       }
//     },
//     itemBuilder: (context) => offline ? [
//       PopupMenuItem(
//         value: 1,
//         child: Row(
//           children: [
//             Icon(CupertinoIcons.timer,
//               color: Theme.of(context).iconTheme.color,
//             ),
//             const SizedBox(width: 10.0),
//             Text(PlayerTranslationConstants.sleepTimer.tr,),
//           ],
//         ),
//       ),
//       PopupMenuItem(
//         value: 10,
//         child: Row(
//           children: [
//             Icon(Icons.info_rounded,
//               color: Theme.of(context).iconTheme.color,
//             ),
//             AppTheme.widthSpace10,
//             Text("PlayerTranslationConstants.songInfo.tr"),
//           ],
//         ),
//       ),
//     ] : [
//       PopupMenuItem(
//         value: 0,
//         child: Row(
//           children: [
//             Icon(Icons.playlist_add_rounded,
//               color: Theme.of(context).iconTheme.color,
//             ),
//             AppTheme.widthSpace10,
//             Text(PlayerTranslationConstants.addToPlaylist.tr,),],),
//       ),
//       PopupMenuItem(
//         value: 1,
//         child: Row(
//           children: [
//             Icon(
//               CupertinoIcons.timer,
//               color: Theme.of(context).iconTheme.color,
//             ),
//             AppTheme.widthSpace10,
//             Text(
//               PlayerTranslationConstants.sleepTimer.tr,
//             ),
//           ],
//         ),
//       ),
//       PopupMenuItem(
//         value: 10,
//         child: Row(
//           children: [
//             Icon(Icons.info_rounded,
//               color: Theme.of(context).iconTheme.color,
//             ),
//             const SizedBox(width: 10.0),
//             Text("PlayerTranslationConstants.songInfo.tr,"),
//           ],
//         ),
//       ),
//     ],
//   );
// }

}
