import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';

import '../../domain/use_cases/neom_audio_handler.dart';
import '../../utils/helpers/media_item_mapper.dart';
import '../widgets/image_card.dart';
import 'media_player_page.dart';
import 'widgets/control_buttons.dart';

class MiniPlayerController extends GetxController {

  final userController = Get.find<UserController>();

  final Rx<AppMediaItem> appMediaItem = AppMediaItem().obs;
  final Rxn<MediaItem> mediaItem = Rxn<MediaItem>();
  final RxBool isLoading = true.obs;
  final RxBool isTimeline = true.obs;
  final RxBool isButtonDisabled = false.obs;
  final RxBool showInTimeline = true.obs;
  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t('onInit miniPlayer Controller');

    try {

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
    update();
  }

  void setIsTimeline(bool value) {
    AppUtilities.logger.d('Setting IsTimeline: $value');
    isTimeline.value = value;
    update();
  }

  void setShowInTimeline({bool value = true}) {
    AppUtilities.logger.i('Setting showInTimeline to $value');
    showInTimeline.value =  value;
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
      onTap: item == null ? null : () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPlayerPage(appMediaItem: MediaItemMapper.fromMediaItem(item)),
        ),
      ),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(!isTimeline)
            IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => goToTimeline(context), ),
          if(item != null || isTimeline)
            SizedBox(
              height: item == null ? 80 : 78,
              width: isTimeline && item == null ? (MediaQuery.of(context).size.width/6) : null,
              child: Hero(tag: 'currentArtwork',
                child: imageCard(
                  elevation: 8,
                  boxDimension: useDense ? 40.0 : 50.0,
                  localImage: item == null ? false : item.artUri?.toString().startsWith('file:') ?? false,
                  imageUrl: item == null ? AppFlavour.getAppLogoUrl() : (item.artUri?.toString().startsWith('file:') ?? false
                      ? item.artUri?.toFilePath() : item.artUri?.toString()) ?? '',
                ),
              ),
            ),
        ],
      ),
      title: Text(
        item == null ? (isTimeline ? AppTranslationConstants.lookingForNewMusic.tr : AppTranslationConstants.lookingForInspiration.tr) : item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: isTimeline || item != null ? TextAlign.left : TextAlign.right,
      ),
      subtitle: Text(
        item == null ? (isTimeline ? AppTranslationConstants.tryOurPlatform.tr : AppTranslationConstants.goBackHome.tr) : item.artist ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: isTimeline || item != null ? TextAlign.left : TextAlign.right,
      ),
      trailing: SizedBox(
        width: item != null || isTimeline ? null : (MediaQuery.of(context).size.width/(item == null ? 6 : 3)),
        child: item == null
            ? (isTimeline ? IconButton(onPressed: () => goToMusicPlayerHome(), icon: const Icon(Icons.arrow_forward_ios))
            : Hero(tag: 'currentArtwork',
                child: imageCard(
                  elevation: 8,
                  boxDimension: useDense ? 40.0 : 50.0,
                  localImage: item == null ? false : item.artUri?.toString().startsWith('file:') ?? false,
                  imageUrl: item == null ? AppFlavour.getAppLogoUrl() : (item.artUri?.toString().startsWith('file:') ?? false
                      ? item.artUri?.toFilePath() : item.artUri?.toString()) ?? '',
                ),
              )
            ) : ControlButtons(audioHandler, miniplayer: true,
          buttons: isLocalImage ? <String>['Like', 'Play/Pause', 'Next'] : preferredMiniButtons,
          mediaItem: item,
        ),
      ),
    );
  }

  void goToMusicPlayerHome() {
    isTimeline.value = false;
    Get.toNamed(AppRouteConstants.musicPlayerHome);
    update();
  }

  void goToTimeline(BuildContext context) {
    isTimeline.value = true;
    showInTimeline.value = true;
    Get.back();
    update();
  }



}
