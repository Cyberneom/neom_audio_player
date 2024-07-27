import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyric_ui/ui_netease.dart';
import 'package:flutter_lyric/lyrics_model_builder.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../domain/entities/media_lyrics.dart';
import '../../domain/entities/position_data.dart';
import '../../domain/use_cases/neom_audio_handler.dart';
import '../../neom_player_invoker.dart';
import '../../utils/constants/app_hive_constants.dart';
import '../../utils/helpers/media_item_mapper.dart';
import 'lyrics/lyrics.dart';

class MediaPlayerController extends GetxController {

  final userController = Get.find<UserController>();
  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  final Rxn<MediaItem> mediaItem = Rxn<MediaItem>();
  final Rx<AppMediaItem> appMediaItem = AppMediaItem().obs;
  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;
  final RxBool isSharePopupShown = false.obs;
  final RxBool reproduceItem = true.obs;
  final bool offline = false;

  final bool getLyricsOnline = Hive.box(AppHiveConstants.settings).get('getLyricsOnline', defaultValue: true) as bool;
  final PanelController panelController = PanelController();

  GlobalKey<FlipCardState> onlineCardKey = GlobalKey<FlipCardState>();
  final Duration time = Duration.zero;


  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t('onInit MediaPlayer Controller');

    try {

      List<dynamic> arguments  = Get.arguments;

      if(arguments.isNotEmpty) {
        if (arguments[0] is AppMediaItem) {
          appMediaItem.value =  arguments.elementAt(0);
        } else if (arguments[0] is String) {
          ///VERIFY IF USEFUL
          ///appMediaItemId = arguments[0];???
        }

        if(arguments.length > 1) {
          reproduceItem.value = arguments[1] as bool;
        }
      }

      bool alreadyPlaying = audioHandler.currentMediaItem != null
          && audioHandler.currentMediaItem!.id == appMediaItem.value.id;

      if(reproduceItem.value && !alreadyPlaying) {
        Future.delayed(const Duration(milliseconds: 500)).then((value) {
          NeomPlayerInvoker.init(
            appMediaItems: [appMediaItem.value],
            index: 0,
          );
          // audioHandler.play();
        });
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();

    try {

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading.value = false;
    update();
  }


  void clear() {

  }

  void setMediaItem(MediaItem item) {
    AppUtilities.logger.i('Setting new mediaitem ${item.title}');
    mediaItem.value = item;
    appMediaItem.value = MediaItemMapper.fromMediaItem(item);
    update();
  }

  ///DEPRECATED
  // StreamBuilder<Duration> positionSlider(double? maxDuration) {
  //   return StreamBuilder<Duration>(
  //     stream: AudioService.position,
  //     builder: (context, snapshot) {
  //       final position = snapshot.data;
  //       return position == null
  //           ? const SizedBox.shrink()
  //           : (position.inSeconds.toDouble() < 0.0 ||
  //           (position.inSeconds.toDouble() > (maxDuration ?? 180.0)))
  //           ? const SizedBox.shrink()
  //           : SliderTheme(
  //         data: SliderTheme.of(context).copyWith(
  //           activeTrackColor: Theme.of(context).colorScheme.secondary,
  //           inactiveTrackColor: Colors.transparent,
  //           trackHeight: 0.5,
  //           thumbColor: Theme.of(context).colorScheme.secondary,
  //           thumbShape: const RoundSliderThumbShape(
  //             enabledThumbRadius: 1.0,
  //           ),
  //           overlayColor: Colors.transparent,
  //           overlayShape: const RoundSliderOverlayShape(
  //             overlayRadius: 2.0,
  //           ),
  //         ),
  //         child: Center(
  //           child: Slider(
  //             inactiveColor: Colors.transparent,
  //             // activeColor: Colors.white,
  //             value: position.inSeconds.toDouble(),
  //             max: maxDuration ?? 180.0,
  //             onChanged: (newPosition) {
  //               audioHandler.seek(
  //                 Duration(
  //                   seconds: newPosition.round(),
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

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
      mediaLyrics.lyrics = appMediaItemLyric;
      mediaLyrics.mediaId = appMediaItem.value.id;
      lyricsReaderModel = LyricsModelBuilder.create().bindLyricToMain(mediaLyrics.lyrics).getModel();
    } else {
      mediaLyrics = await Lyrics.getLyrics(id: appMediaItem.value.id,
        title: appMediaItem.value.name, artist: appMediaItem.value.artist.toString(),);
    }

    lyricsSource.value = mediaLyrics.source.name.capitalizeFirst;
    lyricsReaderModel = LyricsModelBuilder.create().bindLyricToMain(mediaLyrics.lyrics).getModel();
    done.value = true;
    // update([AppPageIdConstants.mediaPlayer]);
  }

  Stream<Duration> get bufferedPositionStream => audioHandler.playbackState.map((state) => state.bufferedPosition).distinct();

  Stream<Duration?> get durationStream => audioHandler.mediaItem.map((item) => item?.duration).distinct();

  Stream<PositionData> get positionDataStream =>
      rx.Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        AudioService.position, bufferedPositionStream, durationStream,
        (position, bufferedPosition, duration) => PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );


  ///NOT IN USE
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
  //         MusicPlayerUtilities.onSelectedPopUpMenu(context, value, appMediaItem, _time);
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
  //             Text(PlayerTranslationConstants.songInfo.tr,),
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
  //             Text(PlayerTranslationConstants.songInfo.tr,),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

}
