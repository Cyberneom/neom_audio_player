import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:rxdart/rxdart.dart' as rx;

import '../../../domain/entities/queue_state.dart';
import '../../../domain/use_cases/neom_audio_handler.dart';
import '../../../utils/constants/music_player_constants.dart';
import '../../../utils/constants/player_translation_constants.dart';
import '../../../utils/helpers/media_item_mapper.dart';
import '../../widgets/download_button.dart';
import '../../widgets/like_button.dart';

class ControlButtons extends StatelessWidget {
  final NeomAudioHandler audioHandler;
  final bool shuffle;
  final bool miniplayer;
  final List<String> buttons;
  final Color? dominantColor;
  MediaItem? mediaItem;
  bool showPlay = true;

  ControlButtons(
      this.audioHandler, {super.key,
        this.shuffle = false,
        this.miniplayer = false,
        this.buttons = const ['Previous', 'Play/Pause', 'Next'],
        this.dominantColor,
        this.mediaItem,
      });

  @override
  Widget build(BuildContext context) {
    if(mediaItem == null && audioHandler.mediaItem.value != null) {
       mediaItem = audioHandler.mediaItem.value;
    } else {
      // NeomPlayerInvoker.init(
      //   appMediaItems: [MediaItemMapper.fromMediaItem(mediaItem!)],
      //   index: 0,
      // );
    }

    final String url = mediaItem?.extras?['url'].toString() ?? '';

    if(url.isEmpty || url.toLowerCase().contains('null')) {
      showPlay = false;
    }

    final bool isOnline = url.startsWith('http');
    return SizedBox(
      height: 80,
      width: miniplayer ? MediaQuery.of(context).size.width/3 : null,
      child: showPlay ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons.map((e) {
          switch (e) {
            case 'Like':
              return !isOnline
                  ? const SizedBox()
                  : SizedBox(
                height: miniplayer ? MusicPlayerConstants.miniPlayerHeight : MusicPlayerConstants.musicPlayerHeight,
                width: miniplayer ? MusicPlayerConstants.miniPlayerWidth : MusicPlayerConstants.musicPlayerWidth,
                child: LikeButton(
                appMediaItem: MediaItemMapper.fromMediaItem(mediaItem!),
                size: 22.0,),
              );
            case 'Previous':
              return SizedBox(
                height: miniplayer ? MusicPlayerConstants.miniPlayerHeight : MusicPlayerConstants.musicPlayerHeight,
                width: miniplayer ? MusicPlayerConstants.miniPlayerWidth : MusicPlayerConstants.musicPlayerWidth,
                child: StreamBuilder<QueueState>(
                stream: audioHandler.queueState,
                builder: (context, snapshot) {
                  final queueState = snapshot.data;
                  return IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: miniplayer ? 24.0 : 45.0,
                    tooltip: PlayerTranslationConstants.skipPrevious.tr,
                    color: dominantColor ?? Theme.of(context).iconTheme.color,
                    onPressed: queueState?.hasPrevious ?? true
                        ? audioHandler.skipToPrevious
                        : null,
                  );
                },),
              );
            case 'Play/Pause':
              return SizedBox(
                height: miniplayer ? MusicPlayerConstants.miniPlayerHeight : MusicPlayerConstants.musicPlayerHeight,
                width: miniplayer ? MusicPlayerConstants.miniPlayerWidth : MusicPlayerConstants.musicPlayerWidth,
                child: StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
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
                          if (miniplayer)
                            Center(
                              child: playing ? IconButton(
                                tooltip: PlayerTranslationConstants.pause.tr,
                                onPressed: audioHandler.pause,
                                icon: const Icon(Icons.pause_rounded,),
                                color: Theme.of(context).iconTheme.color,
                              ) : IconButton(
                                tooltip: PlayerTranslationConstants.play.tr,
                                onPressed: audioHandler.play,
                                icon: const Icon(Icons.play_arrow_rounded,),
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
                                    tooltip: PlayerTranslationConstants.pause.tr,
                                    backgroundColor: Colors.white,
                                    onPressed: audioHandler.pause,
                                    child: const Icon(
                                      Icons.pause_rounded,
                                      size: 40.0,
                                      color: Colors.black,
                                    ),
                                  ) : FloatingActionButton(
                                    elevation: 10,
                                    tooltip:
                                    PlayerTranslationConstants.play.tr,
                                    backgroundColor: Colors.white,
                                    onPressed: audioHandler.play,
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
                  height: miniplayer ? MusicPlayerConstants.miniPlayerHeight : MusicPlayerConstants.musicPlayerHeight,
                  width: miniplayer ? MusicPlayerConstants.miniPlayerWidth : MusicPlayerConstants.musicPlayerWidth,
                  child: StreamBuilder<QueueState>(
                stream: audioHandler.queueState,
                builder: (context, snapshot) {
                  final queueState = snapshot.data;
                  return IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: miniplayer ? 24.0 : 45.0,
                    tooltip: PlayerTranslationConstants.skipNext.tr,
                    color: dominantColor ?? Theme.of(context).iconTheme.color,
                    onPressed: queueState?.hasNext ?? true
                        ? audioHandler.skipToNext
                        : null,
                  );
                },),
              );
            case 'Download':
              return !isOnline ? const SizedBox() : SizedBox(
                  height: miniplayer ? MusicPlayerConstants.miniPlayerHeight : MusicPlayerConstants.musicPlayerHeight,
                  width: miniplayer ? MusicPlayerConstants.miniPlayerWidth : MusicPlayerConstants.musicPlayerWidth,
                  child: DownloadButton(
                    size: 20.0,
                    icon: 'download',
                    mediaItem: MediaItemMapper.fromMediaItem(mediaItem!),
                  ),
              );
            default:
              break;
          }
          return const SizedBox();
        }).toList(),
      ) : Center(child: Text(AppTranslationConstants.noAvailablePreviewUrl.tr),),
    );
  }
}
