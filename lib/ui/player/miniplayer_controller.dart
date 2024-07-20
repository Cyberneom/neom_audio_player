import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';

import '../../domain/use_cases/neom_audio_handler.dart';

class MiniPlayerController extends GetxController {

  final userController = Get.find<UserController>();

  final Rx<AppMediaItem> appMediaItem = AppMediaItem().obs;
  final Rxn<MediaItem> mediaItem = Rxn<MediaItem>();
  final RxBool isLoading = true.obs;
  final RxBool isTimeline = true.obs;
  final RxBool isButtonDisabled = false.obs;
  final RxBool showInTimeline = true.obs;
  late final NeomAudioHandler audioHandler;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t('onInit miniPlayer Controller');

    try {
      audioHandler = await GetIt.I.getAsync<NeomAudioHandler>();
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
    AppUtilities.logger.d('Setting new mediaitem ${item.title}');
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
