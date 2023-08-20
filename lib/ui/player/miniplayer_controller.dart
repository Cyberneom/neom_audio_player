
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/ui/player/widgets/control_buttons.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';


class MiniPlayerController extends GetxController {

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

  final RxBool _isTimeline = true.obs;
  bool get isTimeline => _isTimeline.value;
  set isTimeline(bool isTimeline) => _isTimeline.value = isTimeline;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  @override
  void onInit() async {
    super.onInit();
    logger.d("");

    try {

    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    try {

    } catch (e) {

    }
    isLoading = false;
    update();
  }


  void clear() {

  }

  void setMediaItem(MediaItem item) {
    AppUtilities.logger.i("Setting new mediaitem");
    mediaItem = item;
    update();
  }

  void setIsTimeline(bool value) {
    AppUtilities.logger.i("Setting IsTimeline");
    isTimeline = value;
    update();
  }

  StreamBuilder<Duration> positionSlider(double? maxDuration) {
    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data;
        return position == null
            ? const SizedBox()
            : (position.inSeconds.toDouble() < 0.0 ||
            (position.inSeconds.toDouble() > (maxDuration ?? 180.0)))
            ? const SizedBox()
            : SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.secondary,
            inactiveTrackColor: Colors.transparent,
            trackHeight: 0.5,
            thumbColor: Theme.of(context).colorScheme.secondary,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 1.0,
            ),
            overlayColor: Colors.transparent,
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 2.0,
            ),
          ),
          child: Center(
            child: Slider(
              inactiveColor: Colors.transparent,
              // activeColor: Colors.white,
              value: position.inSeconds.toDouble(),
              max: maxDuration ?? 180.0,
              onChanged: (newPosition) {
                audioHandler.seek(
                  Duration(
                    seconds: newPosition.round(),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Container miniplayerTile({
  //   required BuildContext context,
  //   MediaItem? item,
  //   required List<String> preferredMiniButtons,
  //   bool useDense = false,
  //   bool isLocalImage = false,
  //   bool isTimeline = true,
  // }) {
  //   return Container(
  //     color: AppColor.main75,
  //     height: 75,
  //     width: MediaQuery.of(context).size.width,
  //     // onTap: item == null ? null : () => Navigator.pushNamed(context, '/player'),
  //     child:
  //     Row(children: [
  //       Row(
  //         children: [
  //           if(!isTimeline)
  //             IconButton(
  //                 padding: EdgeInsets.zero,
  //                 onPressed: () => goToTimeline(context), icon: Icon(Icons.arrow_back_ios)),
  //           if(item != null || isTimeline)
  //             Container(
  //               height: item == null ? 80 : 78,
  //               width: isTimeline && item == null ? (MediaQuery.of(context).size.width/6) : null,
  //               child: Hero(tag: 'currentArtwork',
  //                 child: imageCard(
  //                   elevation: 8,
  //                   boxDimension: useDense ? 40.0 : 50.0,
  //                   localImage: item == null ? false : item.artUri?.toString().startsWith('file:') ?? false,
  //                   imageUrl: item == null ? AppFlavour.getAppLogoUrl() : (item?.artUri?.toString().startsWith('file:') ?? false
  //                       ? item?.artUri?.toFilePath() : item?.artUri?.toString()) ?? '',
  //                 ),
  //               ),
  //             )
  //         ],
  //       ),
  //       Column(
  //         children: [
  //           Text(
  //             item == null ? (isTimeline ? '¿Buscando nueva música?' : '¿Buscando nuevas influencias?') : item.title,
  //             maxLines: 1,
  //             overflow: TextOverflow.ellipsis,
  //             textAlign: isTimeline || item != null ? TextAlign.left : TextAlign.right,
  //           ),
  //           Text(
  //             item == null ? (isTimeline ? 'Prueba nuestra nueva plataforma' : 'Volver al inicio') : item.artist ?? '',
  //             maxLines: 1,
  //             overflow: TextOverflow.ellipsis,
  //             textAlign: isTimeline || item != null ? TextAlign.left : TextAlign.right,
  //           ),
  //         ],
  //       ),
  //       Container(
  //         height: item == null ? 80 : 78,
  //         width: item != null || isTimeline ? null : (MediaQuery.of(context).size.width/(item == null ? 6 : 3)),
  //         child: item == null ? (isTimeline
  //             ? IconButton(onPressed: () => goToMusicPlayerHome(), icon: Icon(Icons.arrow_forward_ios))
  //             : Hero(tag: 'currentArtwork',
  //           child: imageCard(
  //             elevation: 8,
  //             boxDimension: useDense ? 40.0 : 50.0,
  //             localImage: item == null ? false : item.artUri?.toString().startsWith('file:') ?? false,
  //             imageUrl: item == null ? AppFlavour.getAppLogoUrl() : (item?.artUri?.toString().startsWith('file:') ?? false
  //                 ? item?.artUri?.toFilePath() : item?.artUri?.toString()) ?? '',
  //           ),
  //         ))
  //             : ControlButtons(audioHandler, miniplayer: true,
  //           buttons: isLocalImage ? <String>['Like', 'Play/Pause', 'Next'] : preferredMiniButtons,
  //         ),),
  //     ],),
  //
  //
  //
  //   );
  // }

  ListTile miniplayerTile({
    required BuildContext context,
    MediaItem? item,
    required List<String> preferredMiniButtons,
    bool useDense = false,
    bool isLocalImage = false,
    bool isTimeline = true,
  }) {
    return ListTile(
      tileColor: AppColor.main75,
      onTap: item == null ? null : () => Navigator.pushNamed(context, '/player'),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(!isTimeline)
            IconButton(
              padding: EdgeInsets.zero,
                onPressed: () => goToTimeline(context), icon: Icon(Icons.arrow_back_ios)),
          if(item != null || isTimeline)
            Container(
              height: item == null ? 80 : 78,
              width: isTimeline && item == null ? (MediaQuery.of(context).size.width/6) : null,
              child: Hero(tag: 'currentArtwork',
                child: imageCard(
                  elevation: 8,
                  boxDimension: useDense ? 40.0 : 50.0,
                  localImage: item == null ? false : item.artUri?.toString().startsWith('file:') ?? false,
                  imageUrl: item == null ? AppFlavour.getAppLogoUrl() : (item?.artUri?.toString().startsWith('file:') ?? false
                      ? item?.artUri?.toFilePath() : item?.artUri?.toString()) ?? '',
                ),
              ),
            )
        ],
      ),
      title: Text(
        item == null ? (isTimeline ? '¿Buscando nueva música?' : '¿Buscando nuevas influencias?') : item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: isTimeline || item != null ? TextAlign.left : TextAlign.right,
      ),
      subtitle: Text(
        item == null ? (isTimeline ? 'Prueba nuestra nueva plataforma' : 'Volver al inicio') : item.artist ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: isTimeline || item != null ? TextAlign.left : TextAlign.right,
      ),
      trailing: Container(
        width: item != null || isTimeline ? null : (MediaQuery.of(context).size.width/(item == null ? 6 : 3)),
        child: item == null ? (isTimeline
          ? IconButton(onPressed: () => goToMusicPlayerHome(), icon: Icon(Icons.arrow_forward_ios))
          : Hero(tag: 'currentArtwork',
              child: imageCard(
                elevation: 8,
                boxDimension: useDense ? 40.0 : 50.0,
                localImage: item == null ? false : item.artUri?.toString().startsWith('file:') ?? false,
                imageUrl: item == null ? AppFlavour.getAppLogoUrl() : (item?.artUri?.toString().startsWith('file:') ?? false
                    ? item?.artUri?.toFilePath() : item?.artUri?.toString()) ?? '',
              ),
            ))
          : ControlButtons(audioHandler, miniplayer: true,
          buttons: isLocalImage ? <String>['Like', 'Play/Pause', 'Next'] : preferredMiniButtons,
          mediaItem: item,
        ),
      ),
    );
  }

  void goToMusicPlayerHome() {
    isTimeline = false;
    Get.toNamed(AppRouteConstants.musicPlayerHome);
    update();
  }

  void goToTimeline(BuildContext context) {
    isTimeline = true;
    Get.back();
    update();
  }



}
