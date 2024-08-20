import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';

import '../../data/implementations/app_hive_controller.dart';
import '../../data/providers/neom_audio_provider.dart';
import '../../domain/use_cases/neom_audio_handler.dart';
import '../../utils/constants/app_hive_constants.dart';

class MiniPlayerController extends GetxController {

  final userController = Get.find<UserController>();

  AppMediaItem appMediaItem = AppMediaItem();
  MediaItem? mediaItem;
  bool isLoading = true;
  bool isTimeline = true;
  bool isButtonDisabled = false;
  bool showInTimeline = true;
  late final NeomAudioHandler audioHandler;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t('onInit miniPlayer Controller');

    try {
      // await initAudioPlayerModule();
      // audioHandler = await GetIt.I.getAsync<NeomAudioHandler>();
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

    isLoading = false;
    update([AppPageIdConstants.miniPlayer]);
  }


  void clear() {

  }

  void setMediaItem(MediaItem item) {
    AppUtilities.logger.d('Setting new mediaitem ${item.title}');
    mediaItem = item;
    update([AppPageIdConstants.miniPlayer]);
  }

  void setIsTimeline(bool value) {
    AppUtilities.logger.d('Setting IsTimeline: $value');
    isTimeline = value;
    update([AppPageIdConstants.home, AppPageIdConstants.timeline]);
  }

  void setShowInTimeline({bool value = true}) {
    AppUtilities.logger.i('Setting showInTimeline to $value');
    showInTimeline =  value;
    update([AppPageIdConstants.home, AppPageIdConstants.musicPlayerHome, AppPageIdConstants.miniPlayer]);
  }

  StreamBuilder<Duration> positionSlider(double? maxDuration) {
    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data;
        return position == null
            ? const SizedBox.shrink()
            : (position.inSeconds.toDouble() < 0.0 ||
            (position.inSeconds.toDouble() > (maxDuration ?? 180.0)))
            ? const SizedBox.shrink()
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
    isTimeline = false;
    Get.toNamed(AppRouteConstants.musicPlayerHome);
    update([AppPageIdConstants.home, AppPageIdConstants.musicPlayerHome, AppPageIdConstants.miniPlayer]);
  }

  void goToTimeline(BuildContext context) {
    isTimeline = true;
    showInTimeline = mediaItem != null;

    Get.back();
    update([AppPageIdConstants.home, AppPageIdConstants.musicPlayerHome, AppPageIdConstants.miniPlayer]);
  }

  Future<void> initHiveMeta() async {
    AppUtilities.logger.d('initHiveMeta');

    await Hive.initFlutter();
    for (final box in AppHiveConstants.hiveBoxes) {
      await AppHiveController.openHiveBox(
        box[AppHiveConstants.name].toString(),
        limit: box[AppHiveConstants.limit] as bool? ?? false,
      );
    }
    await AppHiveController().onInit();
    MetadataGod.initialize();
  }

  Future<void> initAudioPlayerModule() async {
    AppUtilities.logger.d('initAudioPlayerModule');

    try {
      GetIt.I.registerLazySingletonAsync<NeomAudioHandler>(() async {
        final neomAudioProvider = NeomAudioProvider();
        audioHandler = await neomAudioProvider.getAudioHandler();
        return audioHandler;
      });
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

}
