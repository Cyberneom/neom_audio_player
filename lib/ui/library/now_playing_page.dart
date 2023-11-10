import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';

import '../../../domain/use_cases/neom_audio_handler.dart';
import '../../../utils/constants/music_player_route_constants.dart';
import '../../../utils/constants/player_translation_constants.dart';
import '../player/widgets/now_playing_stream.dart';
import '../widgets/bouncy_sliver_scroll_view.dart';
import '../widgets/empty_screen.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  _NowPlayingPageState createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
        stream: audioHandler.playbackState,
        builder: (context, snapshot) {
          final playbackState = snapshot.data;
          final processingState = playbackState?.processingState;
          return Scaffold(
            backgroundColor: AppColor.main50,
            appBar: processingState != AudioProcessingState.idle
                ? null
                : AppBarChild(title: PlayerTranslationConstants.nowPlaying.tr,),
            body: processingState == AudioProcessingState.idle
                ? TextButton(onPressed: () => Navigator.pushNamed(context, MusicPlayerRouteConstants.home),
              child: emptyScreen(
                context, 3,
                PlayerTranslationConstants.nothingIs.tr, 14.0,
                PlayerTranslationConstants.playingCap.tr, 38,
                PlayerTranslationConstants.playSomething.tr, 28.0,
              ),
            ) : StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final mediaItem = snapshot.data;
                return mediaItem == null
                    ? const SizedBox()
                    : BouncyImageSliverScrollView(
                  scrollController: _scrollController,
                  title: PlayerTranslationConstants.nowPlaying.tr,
                  localImage: mediaItem.artUri!
                      .toString().startsWith('file:'),
                  imageUrl: mediaItem.artUri!
                      .toString().startsWith('file:')
                      ? mediaItem.artUri!.toFilePath()
                      : mediaItem.artUri!.toString(),
                  sliverList: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        NowPlayingStream(audioHandler: audioHandler,),
                      ],
                    ),
                  ),
                );
                },
            ),
          );
        },
    );
  }
}