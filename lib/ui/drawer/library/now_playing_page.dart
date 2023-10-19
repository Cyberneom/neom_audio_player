import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/ui/player/widgets/now_playing_stream.dart';
import 'package:neom_music_player/ui/widgets/bouncy_sliver_scroll_view.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/utils/constants/music_player_route_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';

class NowPlayingPage extends StatefulWidget {
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
                ? TextButton(onPressed: () => Navigator.pushNamed(context, MusicPlayerRouteConstants.home),
              child: emptyScreen(
                context, 3,
                PlayerTranslationConstants.nothingIs.tr, 18.0,
                PlayerTranslationConstants.playingCap.tr, 45,
                PlayerTranslationConstants.playSomething.tr, 30.0,
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
      ),
    );
  }
}
