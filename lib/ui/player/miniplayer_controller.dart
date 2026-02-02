import 'package:audio_service/audio_service.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/use_cases/miniplayer_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';
import 'package:neom_core/utils/enums/external_media_source.dart';

import '../../audio_player_invoker.dart';
import '../../neom_audio_handler.dart';
import '../../utils/mappers/media_item_mapper.dart';

class MiniPlayerController extends SintController implements MiniPlayerService {

  final userServiceImpl = Sint.find<UserService>();

  AppMediaItem appMediaItem = AppMediaItem();
  Rxn<MediaItem> mediaItem = Rxn<MediaItem>();
  bool isLoading = true;
  bool isTimeline = true;
  bool isButtonDisabled = false;
  bool showInTimeline = true;
  NeomAudioHandler? audioHandler;
  AppMediaSource source = AppMediaSource.internal;
  ExternalSource? externalSource;
  bool isInternal = true;
  Duration? itemDuration;
  bool audioHandlerRegistered = false;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.d('onInit miniPlayer Controller');

    try {

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void onReady() {
    super.onReady();

    try {

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.miniPlayer]);
  }

  void clear() {

  }

  @override
  Future<void> setAppMediaItem(AppMediaItem appMediaItem) async {
    AppConfig.logger.d('Setting new mediaitem ${appMediaItem.name}');
    audioHandler ??= await Sint.find<AudioPlayerInvoker>().getOrInitAudioHandler();
    audioHandlerRegistered = true;
    mediaItem.value = MediaItemMapper.fromAppMediaItem(item: appMediaItem);
    source = EnumToString.fromString(AppMediaSource.values, mediaItem.value?.extras?["source"] ?? AppMediaSource.internal.name) ?? AppMediaSource.internal;
    isInternal = source == AppMediaSource.internal || source == AppMediaSource.offline;

    update([AppPageIdConstants.miniPlayer]);
  }

  Future<void> setMediaItem(MediaItem item) async {
    AppConfig.logger.d('Setting new mediaitem ${item.title}');
    audioHandler ??= await Sint.find<AudioPlayerInvoker>().getOrInitAudioHandler();
    audioHandlerRegistered = true;
    mediaItem.value = item;
    source = EnumToString.fromString(AppMediaSource.values, mediaItem.value?.extras?["source"] ?? AppMediaSource.internal.name) ?? AppMediaSource.internal;
    isInternal = source == AppMediaSource.internal || source == AppMediaSource.offline;

    update([AppPageIdConstants.miniPlayer]);
  }

  @override
  void setIsTimeline(bool value) {
    AppConfig.logger.d('Setting IsTimeline: $value');
    isTimeline = value;
    update([AppPageIdConstants.home, AppPageIdConstants.timeline]);
  }

  @override
  void setShowInTimeline({bool value = true}) {
    AppConfig.logger.i('Setting showInTimeline to $value');
    showInTimeline =  value;
    update([AppPageIdConstants.home, AppPageIdConstants.audioPlayerHome, AppPageIdConstants.miniPlayer]);
  }

  @override
  StreamBuilder<Duration> positionSlider({bool isPreview = false}) {
    return StreamBuilder<Duration>(
      stream: audioHandler?.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data;
        double? maxDuration = audioHandler?.player.duration?.inSeconds.toDouble();

        return position == null || maxDuration == null
            ? const SizedBox.shrink()
            : (position.inSeconds.toDouble() < 0.0 ||
            (position.inSeconds.toDouble() > (maxDuration)))
            ? const SizedBox.shrink() : SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.secondary,
            inactiveTrackColor: Colors.transparent,
            trackHeight: 1,
            thumbColor: Theme.of(context).colorScheme.secondary,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 1.0,
            ),
            overlayColor: Colors.transparent,
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 1.0,
            ),
          ),
          child: Center(
            child: Slider(
              inactiveColor: Colors.transparent,
              value: position.inSeconds.toDouble(),
              max: isPreview ? 30 : maxDuration,
              onChanged: (newPosition) {
                audioHandler?.seek(Duration(seconds: newPosition.round(),),);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void goToMusicPlayerHome() {
    isTimeline = false;
    Sint.toNamed(AppRouteConstants.audioPlayer);
    update([AppPageIdConstants.home, AppPageIdConstants.audioPlayerHome, AppPageIdConstants.miniPlayer]);
  }

  @override
  void goToTimeline(BuildContext context) {
    isTimeline = true;
    showInTimeline = mediaItem.value != null;

    Sint.back();
    update([AppPageIdConstants.home, AppPageIdConstants.audioPlayerHome, AppPageIdConstants.miniPlayer]);
  }

}
