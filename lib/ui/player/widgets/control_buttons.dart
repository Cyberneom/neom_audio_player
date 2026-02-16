import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/domain/model/app_media_item.dart';

import '../../../domain/models/queue_state.dart';
import '../../../neom_audio_handler.dart';
import '../../../utils/constants/audio_player_constants.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/mappers/media_item_mapper.dart';
import '../../widgets/like_button.dart';

class ControlButtons extends StatelessWidget {

  final NeomAudioHandler? audioHandler;
  final bool shuffle;
  final bool miniPlayer;
  final List<String> buttons;
  final Color? dominantColor;
  final MediaItem? mediaItem;
  final bool showPlay;

  const ControlButtons(
      this.audioHandler, {super.key,
        this.shuffle = false,
        this.miniPlayer = false,
        this.buttons = const ['Previous', 'Play/Pause', 'Next'],
        this.dominantColor,
        this.mediaItem,
        this.showPlay = true,
      });

  @override
  Widget build(BuildContext context) {

    AppMediaItem? appMediaItem;
    bool show = showPlay;

    if(mediaItem == null) {
      if(audioHandler?.mediaItem.value != null) {
        appMediaItem = MediaItemMapper.toAppMediaItem(audioHandler!.mediaItem.value!);
      }
    } else {
      appMediaItem = MediaItemMapper.toAppMediaItem(mediaItem!);
    }

    final String url = mediaItem?.extras?['url'].toString() ?? '';

    if(url.isEmpty || url.toLowerCase().contains('null')) {
      show = false;
    }

    final bool isOnline = url.startsWith(RegExp(r'https?://'));

    return SizedBox(
      height: 80,
      width: miniPlayer ? MediaQuery.of(context).size.width/3 : null,
      child: show ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons.map((e) {
          switch (e) {
            case 'Like':
              return !isOnline
                  ? const SizedBox.shrink()
                  : SizedBox(
                height: miniPlayer ? AudioPlayerConstants.miniPlayerHeight : AudioPlayerConstants.audioPlayerHeight,
                width: miniPlayer ? AudioPlayerConstants.miniPlayerWidth : AudioPlayerConstants.audioPlayerWidth,
                child: LikeButton(
                  padding: EdgeInsets.zero,
                  size: 22.0,
                  itemId: appMediaItem?.id,
                  itemName: appMediaItem?.name,
                ),
              );
            case 'Previous':
              return SizedBox(
                height: miniPlayer ? AudioPlayerConstants.miniPlayerHeight : AudioPlayerConstants.audioPlayerHeight,
                width: miniPlayer ? AudioPlayerConstants.miniPlayerWidth : AudioPlayerConstants.audioPlayerWidth,
                child: StreamBuilder<QueueState>(
                stream: audioHandler?.queueState,
                builder: (context, snapshot) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: miniPlayer ? 24.0 : 45.0,
                    tooltip: AudioPlayerTranslationConstants.skipPrevious.tr,
                    color: dominantColor ?? Theme.of(context).iconTheme.color,
                    onPressed: audioHandler?.skipToPrevious,
                  );
                },),
              );
            case 'Play/Pause':
              return SizedBox(
                height: miniPlayer ? AudioPlayerConstants.miniPlayerHeight : AudioPlayerConstants.audioPlayerHeight,
                width: miniPlayer ? AudioPlayerConstants.miniPlayerWidth : AudioPlayerConstants.audioPlayerWidth,
                child: StreamBuilder<PlaybackState>(
                  stream: audioHandler?.playbackState,
                  builder: (context, snapshot) {
                    final playbackState = snapshot.data;
                    final processingState = playbackState?.processingState;
                    final playing = playbackState?.playing ?? true;
                    return Stack(
                      children: [
                        if (processingState == AudioProcessingState.loading ||
                            processingState == AudioProcessingState.buffering)
                          Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).iconTheme.color!,
                                ),
                            ),
                          ),
                          if(miniPlayer)
                            Center(
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: playing ? AppTranslationConstants.toPause.tr
                                    : AppTranslationConstants.toPlay.tr,
                                onPressed: playing ? audioHandler?.pause
                                    : audioHandler?.play,
                                icon: Icon(playing ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,),
                                color: Theme.of(context).iconTheme.color,
                              ),
                            )
                          else
                            Center(
                              child: SizedBox(
                                height: 59,
                                width: 59,
                                child: Center(
                                  child: playing ? FloatingActionButton(
                                    elevation: 10,
                                    tooltip: AppTranslationConstants.toPause.tr,
                                    backgroundColor: Colors.white,
                                    onPressed: audioHandler?.pause,
                                    child: const Icon(
                                      Icons.pause_rounded,
                                      size: 40.0,
                                      color: Colors.black,
                                    ),
                                  ) : FloatingActionButton(
                                    elevation: 10,
                                    tooltip:
                                    AppTranslationConstants.toPlay.tr,
                                    backgroundColor: Colors.white,
                                    onPressed: audioHandler?.play,
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 40.0,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              );
            case 'Next':
              return SizedBox(
                height: miniPlayer ? AudioPlayerConstants.miniPlayerHeight : AudioPlayerConstants.audioPlayerHeight,
                width: miniPlayer ? AudioPlayerConstants.miniPlayerWidth : AudioPlayerConstants.audioPlayerWidth,
                child: StreamBuilder<QueueState>(
                  stream: audioHandler?.queueState,
                  builder: (context, snapshot) {
                    final queueState = snapshot.data;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: miniPlayer ? 24.0 : 45.0,
                      tooltip: AudioPlayerTranslationConstants.skipNext.tr,
                      color: dominantColor ?? Theme.of(context).iconTheme.color,
                      onPressed: queueState?.hasNext ?? true
                          ? audioHandler?.skipToNext : null,
                    );
                  },
                ),
              );
            case 'Download':
              return !isOnline ? const SizedBox.shrink() : SizedBox(
                  height: miniPlayer ? AudioPlayerConstants.miniPlayerHeight : AudioPlayerConstants.audioPlayerHeight,
                  width: miniPlayer ? AudioPlayerConstants.miniPlayerWidth : AudioPlayerConstants.audioPlayerWidth,
                  child: IconButton(
                    icon: Icon(Icons.download_rounded,
                      color: Theme.of(context).disabledColor,
                    ),
                    iconSize: miniPlayer ? 24.0 : 30.0,
                    tooltip: 'Coming soon',
                    onPressed: null,
                  ),
              );
            default:
              break;
          }
          return const SizedBox.shrink();
        }).toList(),
      ) : Center(child: Text(CommonTranslationConstants.noAvailablePreviewUrl.tr, style: const TextStyle(fontSize: 16)),),
    );
  }
}
