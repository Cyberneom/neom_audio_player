import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_media_player/utils/helpers/media_item_mapper.dart';

import '../../../domain/entities/queue_state.dart';
import '../../../domain/use_cases/neom_audio_handler.dart';
import '../../../utils/constants/audio_player_constants.dart';
import '../../../utils/constants/player_translation_constants.dart';
import '../../widgets/download_button.dart';
import '../../widgets/go_spotify_button.dart';
import '../../widgets/like_button.dart';

// ignore: must_be_immutable
class ControlButtons extends StatelessWidget {

  final NeomAudioHandler? audioHandler;
  final bool shuffle;
  final bool miniplayer;
  final List<String> buttons;
  final Color? dominantColor;
  MediaItem? mediaItem;
  bool showPlay;

  ControlButtons(
      this.audioHandler, {super.key,
        this.shuffle = false,
        this.miniplayer = false,
        this.buttons = const ['Previous', 'Play/Pause', 'Next'],
        this.dominantColor,
        this.mediaItem,
        this.showPlay = true,
      });

  @override
  Widget build(BuildContext context) {
    if(mediaItem == null && audioHandler?.mediaItem.value != null) {
       mediaItem = audioHandler?.mediaItem.value;
    } else {
      ///DEPRECATED
      // NeomPlayerInvoker.init(
      //   appMediaItems: [MediaItemMapper.toAppMediaItem(mediaItem!)],
      //   index: 0,
      // );
    }

    final String url = mediaItem?.extras?['url'].toString() ?? '';

    if(url.isEmpty || url.toLowerCase().contains('null')) {
      showPlay = false;
    }

    final bool isOnline = url.startsWith(RegExp(r'https?://'));

    return SizedBox(
      height: 80,
      width: miniplayer ? MediaQuery.of(context).size.width/3 : null,
      child: showPlay ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons.map((e) {
          switch (e) {
            case 'Like':
              return !isOnline
                  ? const SizedBox.shrink()
                  : SizedBox(
                height: miniplayer ? AudioPlayerConstants.miniPlayerHeight : AudioPlayerConstants.audioPlayerHeight,
                width: miniplayer ? AudioPlayerConstants.miniPlayerWidth : AudioPlayerConstants.audioPlayerWidth,
                child: LikeButton(
                  padding: EdgeInsets.zero,
                  size: 22.0,
                  appMediaItem: MediaItemMapper.toAppMediaItem(mediaItem!),
                ),
              );
            case 'Previous':
              return SizedBox(
                height: miniplayer ? AudioPlayerConstants.miniPlayerHeight : AudioPlayerConstants.audioPlayerHeight,
                width: miniplayer ? AudioPlayerConstants.miniPlayerWidth : AudioPlayerConstants.audioPlayerWidth,
                child: StreamBuilder<QueueState>(
                stream: audioHandler?.queueState,
                builder: (context, snapshot) {
                  ///DEPRECATED final queueState = snapshot.data;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: miniplayer ? 24.0 : 45.0,
                    tooltip: PlayerTranslationConstants.skipPrevious.tr,
                    color: dominantColor ?? Theme.of(context).iconTheme.color,
                    onPressed: audioHandler?.skipToPrevious,
                  );
                },),
              );
            case 'Play/Pause':
              return SizedBox(
                height: miniplayer ? AudioPlayerConstants.miniPlayerHeight : AudioPlayerConstants.audioPlayerHeight,
                width: miniplayer ? AudioPlayerConstants.miniPlayerWidth : AudioPlayerConstants.audioPlayerWidth,
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
                          if(miniplayer)
                            Center(
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: playing ? PlayerTranslationConstants.pause.tr
                                    : PlayerTranslationConstants.play.tr,
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
                                    tooltip: PlayerTranslationConstants.pause.tr,
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
                                    PlayerTranslationConstants.play.tr,
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
                height: miniplayer ? AudioPlayerConstants.miniPlayerHeight : AudioPlayerConstants.audioPlayerHeight,
                width: miniplayer ? AudioPlayerConstants.miniPlayerWidth : AudioPlayerConstants.audioPlayerWidth,
                child: StreamBuilder<QueueState>(
                  stream: audioHandler?.queueState,
                  builder: (context, snapshot) {
                    final queueState = snapshot.data;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: miniplayer ? 24.0 : 45.0,
                      tooltip: PlayerTranslationConstants.skipNext.tr,
                      color: dominantColor ?? Theme.of(context).iconTheme.color,
                      onPressed: queueState?.hasNext ?? true
                          ? audioHandler?.skipToNext : null,
                    );
                  },
                ),
              );
            case 'Download':
              return !isOnline ? const SizedBox.shrink() : SizedBox(
                  height: miniplayer ? AudioPlayerConstants.miniPlayerHeight : AudioPlayerConstants.audioPlayerHeight,
                  width: miniplayer ? AudioPlayerConstants.miniPlayerWidth : AudioPlayerConstants.audioPlayerWidth,
                  child: DownloadButton(size: 20.0,
                    mediaItem: MediaItemMapper.toAppMediaItem(mediaItem!),
                  ),
              );
            case 'Spotify':
              return !isOnline
                  ? const SizedBox.shrink()
                  : SizedBox(
                height: miniplayer ? AudioPlayerConstants.miniPlayerHeight : AudioPlayerConstants.audioPlayerHeight,
                width: miniplayer ? AudioPlayerConstants.miniPlayerWidth : AudioPlayerConstants.audioPlayerWidth,
                child: GoSpotifyButton(
                  size: 20.0,
                  padding: EdgeInsets.zero,
                  appMediaItem: MediaItemMapper.toAppMediaItem(mediaItem!)
                ),
              );
            default:
              break;
          }
          return const SizedBox.shrink();
        }).toList(),
      ) : Center(child: Text(AppTranslationConstants.noAvailablePreviewUrl.tr, style: const TextStyle(fontSize: 16)),),
    );
  }
}
