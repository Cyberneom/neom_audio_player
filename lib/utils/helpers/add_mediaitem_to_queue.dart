import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import '../../domain/use_cases/neom_audio_handler.dart';

import '../constants/player_translation_constants.dart';

void addToNowPlaying({
  required BuildContext context,
  required MediaItem mediaItem,
  bool showNotification = true,
}) {

  final NeomAudioHandler audioHandler = Get.find<NeomAudioHandler>();
  final MediaItem? currentMediaItem = audioHandler.mediaItem.value;
  if (currentMediaItem != null &&
      currentMediaItem.extras!['url'].toString().startsWith('http')) {
    if (audioHandler.queue.value.contains(mediaItem) && showNotification) {
      AppUtilities.showSnackBar(
        message: PlayerTranslationConstants.alreadyInQueue.tr,
      );
    } else {
      audioHandler.addQueueItem(mediaItem);

      if (showNotification) {
        AppUtilities.showSnackBar(
          message: '${mediaItem.title} - ${PlayerTranslationConstants.addedToQueue.tr}',
        );
      }
    }
  } else {
    if (showNotification) {
      AppUtilities.showSnackBar(
        message: currentMediaItem == null
            ? PlayerTranslationConstants.nothingPlaying.tr
            : PlayerTranslationConstants.cantAddToQueue.tr,
      );
    }
  }
}

void playNext(
  MediaItem mediaItem,
  BuildContext context,
) {
  final NeomAudioHandler audioHandler = Get.find<NeomAudioHandler>();

  final MediaItem? currentMediaItem = audioHandler.mediaItem.value;
  if (currentMediaItem != null &&
      currentMediaItem.extras!['url'].toString().startsWith('http')) {
    final queue = audioHandler.queue.value;
    if (queue.contains(mediaItem)) {
      audioHandler.moveQueueItem(
        queue.indexOf(mediaItem),
        queue.indexOf(currentMediaItem) + 1,
      );
    } else {
      audioHandler.addQueueItem(mediaItem).then(
            (value) => audioHandler.moveQueueItem(
              queue.length,
              queue.indexOf(currentMediaItem) + 1,
            ),
          );
    }

    AppUtilities.showSnackBar(
      message: '"${mediaItem.title}" ${PlayerTranslationConstants.willPlayNext.tr}',
    );
  } else {
    AppUtilities.showSnackBar(
      message: currentMediaItem == null
          ? PlayerTranslationConstants.nothingPlaying.tr
          : PlayerTranslationConstants.cantAddToQueue.tr,
    );
  }
}
