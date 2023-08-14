/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/ui/widgets/bouncy_sliver_scroll_view.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/player/audioplayer.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:get/get.dart';

class NowPlayingPage extends StatefulWidget {
  @override
  _NowPlayingPageState createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  final AudioPlayerHandler audioHandler = GetIt.I<AudioPlayerHandler>();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: StreamBuilder<PlaybackState>(
        stream: audioHandler.playbackState,
        builder: (context, snapshot) {
          final playbackState = snapshot.data;
          final processingState = playbackState?.processingState;
          return Scaffold(
            backgroundColor: AppColor.main75,
            appBar: processingState != AudioProcessingState.idle
                ? null
                : AppBar(
                    title: Text(PlayerTranslationConstants.nowPlaying.tr),
                    centerTitle: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
            body: processingState == AudioProcessingState.idle
                ? emptyScreen(
                    context,
                    3,
                    PlayerTranslationConstants.nothingIs.tr,
                    18.0,
                    PlayerTranslationConstants.playingCap.tr,
                    60,
                    PlayerTranslationConstants.playSomething.tr,
                    23.0,
                  )
                : StreamBuilder<MediaItem?>(
                    stream: audioHandler.mediaItem,
                    builder: (context, snapshot) {
                      final mediaItem = snapshot.data;
                      return mediaItem == null
                          ? const SizedBox()
                          : BouncyImageSliverScrollView(
                              scrollController: _scrollController,
                              title: PlayerTranslationConstants.nowPlaying.tr,
                              localImage: mediaItem.artUri!
                                  .toString()
                                  .startsWith('file:'),
                              imageUrl: mediaItem.artUri!
                                      .toString()
                                      .startsWith('file:')
                                  ? mediaItem.artUri!.toFilePath()
                                  : mediaItem.artUri!.toString(),
                              sliverList: SliverList(
                                delegate: SliverChildListDelegate(
                                  [
                                    NowPlayingStream(
                                      audioHandler: audioHandler,
                                    )
                                  ],
                                ),
                              ),
                            );
                    },
                  ),
          );
        },
      ),
    );
  }
}
