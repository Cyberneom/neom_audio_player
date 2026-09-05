import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/domain/use_cases/miniplayer_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';
import 'package:neom_core/utils/enums/external_media_source.dart';

import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import '../../utils/mappers/media_item_mapper.dart';

class MiniPlayerController extends SintController implements MiniPlayerService {
  final userServiceImpl = Sint.find<UserService>();

  AppMediaItem appMediaItem = AppMediaItem();
  Rxn<MediaItem> mediaItem = Rxn<MediaItem>();
  bool isLoading = true;
  bool isTimeline = true;
  bool isButtonDisabled = false;
  bool showInTimeline = true;
  dynamic audioHandler;
  StreamSubscription? _mediaItemSub;
  AppMediaSource source = AppMediaSource.internal;
  ExternalSource? externalSource;
  bool isInternal = true;
  Duration? itemDuration;
  bool audioHandlerRegistered = false;
  bool? _mediaSessionCanPersist;
  final RxBool isWebPlayerRetracted = true.obs;
  final RxBool isWebPlayerClosed = false.obs;

  /// Position (top-left) of the floating retracted web player card.
  /// `null` means "use the default bottom-right placement". Session-scoped:
  /// survives navigation rebuilds but is not persisted to disk.
  final Rx<Offset?> webPlayerOffset = Rx<Offset?>(null);

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.d('onInit miniPlayer Controller');

    try {
      Sint.find<AudioPlayerInvokerService>().getOrInitAudioHandler().then((
        handler,
      ) {
        audioHandler = handler;
        audioHandlerRegistered = true;
        if (audioHandler != null) {
          if (audioHandler.currentMediaItem != null) {
            setMediaItem(audioHandler.currentMediaItem);
          } else {
            clear();
          }
          _mediaItemSub = audioHandler.mediaItem.listen((item) {
            if (item != null) {
              setMediaItem(item);
            } else {
              clear();
            }
          });
        }
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'MiniPlayerController.onInit',
      );
    }
  }

  @override
  void onReady() {
    super.onReady();

    try {} catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'MiniPlayerController.onReady',
      );
    }

    isLoading = false;
    update([AppPageIdConstants.miniPlayer]);
  }

  void clear() {
    mediaItem.value = null;
    appMediaItem = AppMediaItem();
    _mediaSessionCanPersist = null;
    showInTimeline = false;
    isWebPlayerClosed.value = true;
    update([
      AppPageIdConstants.miniPlayer,
      'web_bottom_player',
      'web_now_playing_full',
    ]);
  }

  @override
  Future<void> setAppMediaItem(AppMediaItem appMediaItem) async {
    AppConfig.logger.d('Setting new mediaitem ${appMediaItem.name}');
    audioHandler ??= await Sint.find<AudioPlayerInvokerService>()
        .getOrInitAudioHandler();
    audioHandlerRegistered = true;
    mediaItem.value = MediaItemMapper.fromAppMediaItem(item: appMediaItem);
    _mediaSessionCanPersist = AppConfig.instance.canPersistUserActivity;
    source =
        EnumToString.fromString(
          AppMediaSource.values,
          mediaItem.value?.extras?["source"] ?? AppMediaSource.internal.name,
        ) ??
        AppMediaSource.internal;
    isInternal =
        source == AppMediaSource.internal || source == AppMediaSource.offline;
    isWebPlayerClosed.value = false;

    update([AppPageIdConstants.miniPlayer, 'web_bottom_player']);
  }

  Future<void> setMediaItem(MediaItem item) async {
    AppConfig.logger.d('Setting new mediaitem ${item.title}');
    audioHandler ??= await Sint.find<AudioPlayerInvokerService>()
        .getOrInitAudioHandler();
    audioHandlerRegistered = true;
    mediaItem.value = item;
    _mediaSessionCanPersist = AppConfig.instance.canPersistUserActivity;
    source =
        EnumToString.fromString(
          AppMediaSource.values,
          mediaItem.value?.extras?["source"] ?? AppMediaSource.internal.name,
        ) ??
        AppMediaSource.internal;
    isInternal =
        source == AppMediaSource.internal || source == AppMediaSource.offline;
    isWebPlayerClosed.value = false;

    update([
      AppPageIdConstants.miniPlayer,
      'web_bottom_player',
      'web_now_playing_full',
    ]);
  }

  /// Synchronous UI-side boundary check. The audio handler performs the
  /// authoritative queue cleanup; this prevents even one frame of the prior
  /// session's title/artwork from appearing while that async cleanup runs.
  MediaItem? get visibleMediaItem {
    if (_mediaSessionCanPersist != null &&
        _mediaSessionCanPersist != AppConfig.instance.canPersistUserActivity) {
      return null;
    }
    return mediaItem.value;
  }

  @override
  void setIsTimeline(bool value) {
    AppConfig.logger.d('Setting IsTimeline: $value');
    isTimeline = value;
    update([AppPageIdConstants.home, AppPageIdConstants.timeline]);
  }

  @override
  void onClose() {
    _mediaItemSub?.cancel();
    super.onClose();
  }

  @override
  void setShowInTimeline({bool value = true}) {
    AppConfig.logger.i('Setting showInTimeline to $value');
    showInTimeline = value;
    update([
      AppPageIdConstants.home,
      AppPageIdConstants.audioPlayerHome,
      AppPageIdConstants.miniPlayer,
    ]);
  }

  @override
  StreamBuilder<Duration> positionSlider({bool isPreview = false}) {
    return StreamBuilder<Duration>(
      stream: audioHandler?.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data;
        double? maxDuration = audioHandler?.player.duration?.inSeconds
            .toDouble();

        return position == null || maxDuration == null
            ? const SizedBox.shrink()
            : (position.inSeconds.toDouble() < 0.0 ||
                  (position.inSeconds.toDouble() > (maxDuration)))
            ? const SizedBox.shrink()
            : SliderTheme(
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
                    value: position.inSeconds.toDouble().clamp(
                      0.0,
                      isPreview ? 30.0 : maxDuration,
                    ),
                    max: isPreview ? 30 : maxDuration,
                    onChanged: (newPosition) {
                      audioHandler?.seek(
                        Duration(seconds: newPosition.round()),
                      );
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
    update([
      AppPageIdConstants.home,
      AppPageIdConstants.audioPlayerHome,
      AppPageIdConstants.miniPlayer,
    ]);
  }

  @override
  bool get isActive =>
      mediaItem.value != null && showInTimeline && !isWebPlayerClosed.value;

  @override
  bool get isWebPlayerRetractedValue => isWebPlayerRetracted.value;

  @override
  void goToTimeline(BuildContext context) {
    isTimeline = true;
    showInTimeline = mediaItem.value != null;

    Sint.back();
    update([
      AppPageIdConstants.home,
      AppPageIdConstants.audioPlayerHome,
      AppPageIdConstants.miniPlayer,
    ]);
  }
}
