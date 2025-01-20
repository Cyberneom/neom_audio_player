import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';

import '../../../domain/entities/queue_state.dart';
import '../../../utils/constants/app_hive_constants.dart';
import '../../../utils/constants/player_translation_constants.dart';
import '../../../utils/enums/lyrics_source.dart';
import '../../../utils/enums/lyrics_type.dart';
import '../../widgets/empty_screen.dart';
import '../media_player_controller.dart';

class ArtWorkWidget extends StatelessWidget {

  final MediaPlayerController mediaPlayerController;
  final GlobalKey<FlipCardState>? cardKey;
  final bool offline;
  final bool? getLyricsOnline;
  final double height;
  final double width;


  const ArtWorkWidget({super.key,
    required this.mediaPlayerController,
    required this.height,
    required this.width,
    this.cardKey,
    this.offline = false,
    this.getLyricsOnline
  });

  @override
  Widget build(BuildContext context) {
    MediaPlayerController _ = mediaPlayerController;
    double flipCardWidth = width * 0.75;

    return SizedBox(
      height: height,
      width: flipCardWidth,
      child: Hero(
        tag: 'currentArtwork_',
        child: FlipCard(
          key: cardKey,
          flipOnTouch: false,
          onFlipDone: (value) {
            _.setFlipped(value);
          },
          back: GestureDetector(
            onTap: () => cardKey?.currentState!.toggleCard(),
            onDoubleTap: () => cardKey?.currentState!.toggleCard(),
            child: Stack(
              children: [
                ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent, Colors.black,
                        Colors.black, Colors.black,
                        Colors.transparent,
                      ],
                    ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height),);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        vertical: 60,
                        horizontal: 20,
                      ),
                      child: ValueListenableBuilder(
                        valueListenable: _.done,
                        child: const CircularProgressIndicator(),
                        builder: (
                            BuildContext context,
                            bool value,
                            Widget? child,
                            ) {
                          return value ? _.mediaLyrics.lyrics.isEmpty ? emptyScreen(
                            context, 0,
                            ':( ', 80.0,
                            PlayerTranslationConstants.lyrics.tr, 40.0,
                            PlayerTranslationConstants.notAvailable.tr, 20.0,
                            useWhite: true,
                          ) : _.mediaLyrics.type == LyricsType.text
                              ? SelectableText(_.mediaLyrics.lyrics,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                          ) : StreamBuilder<Duration>(
                            stream: AudioService.position,
                            builder: (context, snapshot) {
                              final position =
                                  snapshot.data ?? Duration.zero;
                              return LyricsReader(
                                model: _.lyricsReaderModel,
                                position: position.inMilliseconds,
                                lyricUi: UINetease(highlight: false),
                                playing: true,
                                size: Size(flipCardWidth, flipCardWidth,),
                                emptyBuilder: () => Center(
                                  child: Text('Lyrics Not Found',
                                    style: _.lyricUI.getOtherMainTextStyle(),
                                  ),
                                ),
                              );
                            },
                          ) : child!;
                        },
                      ),
                    ),
                  ),
                ),
                if(_.mediaLyrics.lyrics.isNotEmpty) ValueListenableBuilder(
                  valueListenable: _.lyricsSource,
                  child: const CircularProgressIndicator(),
                  builder: (BuildContext context, String value, Widget? child,) {
                    if (value == '' || value == AppFlavour.getAppName() || value == LyricsSource.internal.name) {
                      return const SizedBox.shrink();
                    }
                    return Align(
                      alignment: Alignment.bottomRight,
                      child: Text('${AppTranslationConstants.poweredBy.tr} ${value.capitalizeFirst}',
                        style: Theme.of(context).textTheme.bodySmall!
                            .copyWith(fontSize: 10.0, color: Colors.white70),
                      ),
                    );
                  },
                ),
                if(_.mediaLyrics.lyrics.isNotEmpty) Align(
                  alignment: Alignment.bottomRight,
                  child: Card(
                    elevation: 10.0,
                    margin: const EdgeInsets.symmetric(vertical: 20.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    color: AppColor.main75,
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      tooltip: PlayerTranslationConstants.copy.tr,
                      onPressed: () {
                        Feedback.forLongPress(context);
                        CoreUtilities.copyToClipboard(text: _.mediaLyrics.lyrics,);
                      },
                      icon: const Icon(Icons.copy_rounded),
                      color:
                      Theme.of(context).iconTheme.color!.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          front: StreamBuilder<QueueState>(
            stream: _.audioHandler?.queueState,
            builder: (context, snapshot) {
              final queueState = snapshot.data ?? QueueState.empty;
              final bool enabled = Hive.box(AppHiveConstants.settings).get('enableGesture', defaultValue: true) as bool;
              return GestureDetector(
                onTap: !enabled ? null : () {
                  // AddToPlaylist().addToPlaylist(context, _.appMediaItem.value,);
                  ///TODO WHEN ADDING MORE FUNCTIONS
                  // tapped.value = true;
                  // Future.delayed(const Duration(seconds: 2), () async {
                  //   tapped.value = false;
                  // });
                },
                onDoubleTapDown: (details) {
                  if (details.globalPosition.dx <= width * 2 / 5) {
                    _.audioHandler?.customAction('rewind');
                    _.doubleTapped.value = -1;
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      _.doubleTapped.value = 0;
                    });
                  }
                  if (details.globalPosition.dx > width * 2 / 5 &&
                      details.globalPosition.dx < width * 3 / 5) {
                    cardKey?.currentState!.toggleCard();
                  }
                  if (details.globalPosition.dx >= width * 3 / 5) {
                    _.audioHandler?.customAction('fastForward');
                    _.doubleTapped.value = 1;
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      _.doubleTapped.value = 0;
                    });
                  }
                },
                onDoubleTap: !enabled ? null : () {
                  Feedback.forLongPress(context);
                },
                onHorizontalDragEnd: !enabled ? null : (DragEndDetails details) {
                  if ((details.primaryVelocity ?? 0) > 100) {
                    if (queueState.hasPrevious) {
                      _.audioHandler?.skipToPrevious();
                    }
                  }

                  if ((details.primaryVelocity ?? 0) < -100) {
                    if (queueState.hasNext) {
                      _.audioHandler?.skipToNext();
                    }
                  }
                },
                onLongPress: !enabled ? null : () {
                  if (!_.offline) {
                    Feedback.forLongPress(context);
                    // AddToPlaylist().addToPlaylist(context, MediaItemMapper.appMediaItemToMediaItem(appMediaItem: _.appMediaItem));
                  }
                },
                onVerticalDragStart: !enabled ? null : (details) {
                  _.dragging.value = true;
                },
                onVerticalDragEnd: !enabled ? null : (details) {
                  _.dragging.value = false;
                },
                onVerticalDragUpdate: !enabled ? null
                    : (DragUpdateDetails details) {
                  if (details.delta.dy != 0.0) {
                    double volume = _.audioHandler?.volume.value ?? 0;
                    volume -= details.delta.dy / 150;
                    if (volume < 0) {
                      volume = 0;
                    }
                    if (volume > 1.0) {
                      volume = 1.0;
                    }
                    _.audioHandler?.setVolume(volume);
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Card(
                      elevation: 10.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _.appMediaItem.value.imgUrl.startsWith('file')
                          ? Image(
                        fit: BoxFit.contain,
                        width: flipCardWidth,
                        gaplessPlayback: true,
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace,) {
                          return const Image(fit: BoxFit.cover,
                            image: AssetImage(AppAssets.audioPlayerCover),
                          );
                        },
                        image: FileImage(File(_.appMediaItem.value.imgUrl,),),
                      ) : CachedNetworkImage(
                        fit: BoxFit.contain,
                        errorWidget: (BuildContext context, _, __) =>
                        const Image(fit: BoxFit.cover,
                          image: AssetImage(AppAssets.audioPlayerCover),
                        ),
                        placeholder: (BuildContext context, _) =>
                        const Image(fit: BoxFit.cover,
                          image: AssetImage(AppAssets.audioPlayerCover),
                        ),
                        imageUrl: _.appMediaItem.value.imgUrl,
                        width: flipCardWidth,
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _.doubleTapped,
                      child: const Icon(
                        Icons.forward_10_rounded,
                        size: 60.0,
                      ),
                      builder: (
                          BuildContext context,
                          int value,
                          Widget? child,
                          ) {
                        return Visibility(
                          visible: value != 0,
                          child: Card(
                            color: Colors.transparent,
                            elevation: 0.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SizedBox.expand(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: value == 1
                                        ? [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.4),
                                      Colors.black.withOpacity(0.7),
                                    ] : [
                                      Colors.black.withOpacity(0.7),
                                      Colors.black.withOpacity(0.4),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Visibility(
                                      visible: value == -1,
                                      child: const Icon(
                                        Icons.replay_10_rounded,
                                        size: 60.0,
                                      ),
                                    ),
                                    const SizedBox.shrink(),
                                    Visibility(
                                      visible: value == 1,
                                      child: child!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable: _.dragging,
                      child: StreamBuilder<double>(
                        stream: _.audioHandler?.volume,
                        builder: (context, snapshot) {
                          final double volumeValue = snapshot.data ?? 1.0;
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              width: 60.0,
                              height: flipCardWidth,
                              child: Card(
                                color: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    RotatedBox(
                                      quarterTurns: -1,
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: Theme.of(context).iconTheme.color,
                                          inactiveTrackColor: Theme.of(context).iconTheme.color!.withOpacity(0.3),
                                          thumbColor: Theme.of(context).iconTheme.color,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0,),
                                          trackShape: const RoundedRectSliderTrackShape(),
                                        ),
                                        child: Slider(
                                          value: _.audioHandler?.volume.value ?? 0,
                                          onChanged: (_) {},
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 20.0,),
                                      child: Icon(
                                        volumeValue == 0 ? Icons.volume_off_rounded : volumeValue > 0.6
                                            ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      builder: (BuildContext context, bool value, Widget? child,) {
                        return Visibility(visible: value, child: child!,);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
