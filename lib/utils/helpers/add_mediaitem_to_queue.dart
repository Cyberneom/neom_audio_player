import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import '../../domain/use_cases/neom_audio_handler.dart';
import '../../ui/widgets/snackbar.dart';
import '../constants/player_translation_constants.dart';

void addToNowPlaying({
  required BuildContext context,
  required MediaItem mediaItem,
  bool showNotification = true,
}) {
  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();
  final MediaItem? currentMediaItem = audioHandler.mediaItem.valueWrapper?.value;
  if (currentMediaItem != null &&
      currentMediaItem.extras!['url'].toString().startsWith('http')) {
    if (audioHandler.queue.valueWrapper!.value.contains(mediaItem) && showNotification) {
      ShowSnackBar().showSnackBar(
        context,
        PlayerTranslationConstants.alreadyInQueue.tr,
      );
    } else {
      audioHandler.addQueueItem(mediaItem);

      if (showNotification) {
        ShowSnackBar().showSnackBar(
          context,
          PlayerTranslationConstants.addedToQueue.tr,
        );
      }
    }
  } else {
    if (showNotification) {
      ShowSnackBar().showSnackBar(
        context,
        currentMediaItem == null
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
  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();
  final MediaItem? currentMediaItem = audioHandler.mediaItem.valueWrapper?.value;
  if (currentMediaItem != null &&
      currentMediaItem.extras!['url'].toString().startsWith('http')) {
    final queue = audioHandler.queue.valueWrapper?.value;
    if (queue?.contains(mediaItem) ?? false) {
      audioHandler.moveQueueItem(
        queue!.indexOf(mediaItem),
        queue.indexOf(currentMediaItem) + 1,
      );
    } else {
      audioHandler.addQueueItem(mediaItem).then(
            (value) => audioHandler.moveQueueItem(
              queue!.length,
              queue.indexOf(currentMediaItem) + 1,
            ),
          );
    }

    ShowSnackBar().showSnackBar(
      context,
      '"${mediaItem.title}" ${PlayerTranslationConstants.willPlayNext.tr}',
    );
  } else {
    ShowSnackBar().showSnackBar(
      context,
      currentMediaItem == null
          ? PlayerTranslationConstants.nothingPlaying.tr
          : PlayerTranslationConstants.cantAddToQueue.tr,
    );
  }
}
