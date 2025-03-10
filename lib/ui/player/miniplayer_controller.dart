import 'package:audio_service/audio_service.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_hive_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';

import '../../domain/use_cases/neom_audio_handler.dart';
import '../../utils/neom_audio_utilities.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MiniPlayerController extends GetxController {

  final userController = Get.find<UserController>();

  AppMediaItem appMediaItem = AppMediaItem();
  MediaItem? mediaItem;
  bool isLoading = true;
  bool isTimeline = true;
  bool isButtonDisabled = false;
  bool showInTimeline = true;
  NeomAudioHandler? audioHandler;
  AppMediaSource source = AppMediaSource.internal;
  bool isInternal = true;
  Duration? itemDuration;
  bool audioHandlerRegistered = false;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.d('onInit miniPlayer Controller');

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

    isLoading = false;
    update([AppPageIdConstants.miniPlayer]);
  }

  void clear() {

  }

  Future<void> setMediaItem(MediaItem item) async {
    AppUtilities.logger.d('Setting new mediaitem ${item.title}');
    audioHandler ??= await NeomAudioUtilities.getAudioHandler();
    audioHandlerRegistered = true;
    mediaItem = item;
    source = EnumToString.fromString(AppMediaSource.values, mediaItem?.extras?["source"] ?? AppMediaSource.internal.name) ?? AppMediaSource.internal;
    isInternal = source == AppMediaSource.internal || source == AppMediaSource.offline;

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
    update([AppPageIdConstants.home, AppPageIdConstants.audioPlayerHome, AppPageIdConstants.miniPlayer]);
  }

  StreamBuilder<Duration> positionSlider({bool isPreview = false}) {
    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data;
        double? maxDuration = audioHandler?.player.duration?.inSeconds.toDouble();
        return position == null || maxDuration == null
            ? const SizedBox.shrink()
            : (position.inSeconds.toDouble() < 0.0 ||
            (position.inSeconds.toDouble() > (maxDuration)))
            ? const SizedBox.shrink()
            : SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.secondary,
            inactiveTrackColor: Colors.transparent,
            trackHeight: 5,
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
              value: position.inSeconds.toDouble(),
              max: isPreview ? 30 : maxDuration,
              onChanged: (newPosition) {
                audioHandler?.seek(
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
    Get.toNamed(AppRouteConstants.audioPlayerHome);
    update([AppPageIdConstants.home, AppPageIdConstants.audioPlayerHome, AppPageIdConstants.miniPlayer]);
  }

  void goToTimeline(BuildContext context) {
    isTimeline = true;
    showInTimeline = mediaItem != null;

    Get.back();
    update([AppPageIdConstants.home, AppPageIdConstants.audioPlayerHome, AppPageIdConstants.miniPlayer]);
  }

  List<String> getPreferredMiniButtons() {
    List preferredButtons = Hive.box(AppHiveBox.settings.name)
        .get(AppHiveConstants.preferredMiniButtons,
      defaultValue: ['Like', 'Play/Pause', 'Next'],)?.toList() as List<dynamic>;

    return preferredButtons.map((e) => e.toString()).toList();
  }

}
