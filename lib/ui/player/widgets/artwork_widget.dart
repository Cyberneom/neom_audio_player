import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/device_utilities.dart';
import 'package:neom_core/app_properties.dart';

import '../../../data/implementations/player_hive_controller.dart';
import '../../../domain/models/queue_state.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/enums/lyrics_source.dart';
import '../../../utils/enums/lyrics_type.dart';
import '../../widgets/empty_screen.dart';
import '../audio_player_controller.dart';

class ArtWorkWidget extends StatelessWidget {

  final AudioPlayerController mediaPlayerController;
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
    AudioPlayerController controller = mediaPlayerController;
    double flipCardWidth = width * 0.75;
    String artworkUrl = controller.mediaItem.value?.artUri.toString() ?? '';
    final bool enabled = PlayerHiveController().enableGesture;
    return SizedBox(
      height: height,
      width: flipCardWidth,
      child: FlipCard(
          key: cardKey,
          flipOnTouch: false,
          onFlipDone: (value) {
            controller.setFlipped(value);
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
                        valueListenable: controller.done,
                        child: const CircularProgressIndicator(),
                        builder: (BuildContext context, bool value, Widget? child,) {
                          return value ? controller.mediaLyrics.lyrics.isEmpty ? emptyScreen(
                            context, 0,
                            ':( ', 80.0,
                            AudioPlayerTranslationConstants.lyrics.tr, 40.0,
                            CommonTranslationConstants.notAvailable.tr, 20.0,
                            useWhite: true,
                          ) : controller.mediaLyrics.type == LyricsType.text
                              ? SelectableText(controller.mediaLyrics.lyrics,
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
                                model: controller.lyricsReaderModel,
                                position: position.inMilliseconds,
                                lyricUi: UINetease(highlight: false),
                                playing: true,
                                size: Size(flipCardWidth, flipCardWidth,),
                                emptyBuilder: () => Center(
                                  child: Text(AudioPlayerTranslationConstants.lyricsNotFound,
                                    style: controller.lyricUI.getOtherMainTextStyle(),
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
                if(controller.mediaLyrics.lyrics.isNotEmpty) ValueListenableBuilder(
                  valueListenable: controller.lyricsSource,
                  child: const CircularProgressIndicator(),
                  builder: (BuildContext context, String value, Widget? child,) {
                    if (value == '' || value == AppProperties.getAppName() || value == LyricsSource.internal.name) {
                      return const SizedBox.shrink();
                    }
                    return Align(
                      alignment: Alignment.bottomRight,
                      child: Text('${AudioPlayerTranslationConstants.poweredBy.tr} ${value.capitalizeFirst}',
                        style: Theme.of(context).textTheme.bodySmall!
                            .copyWith(fontSize: 10.0, color: Colors.white70),
                      ),
                    );
                  },
                ),
                if(controller.mediaLyrics.lyrics.isNotEmpty) Align(
                  alignment: Alignment.bottomRight,
                  child: Card(
                    elevation: 10.0,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: AppColor.main75,
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      tooltip: AppTranslationConstants.copy.tr,
                      onPressed: () {
                        Feedback.forLongPress(context);
                        DeviceUtilities.copyToClipboard(text: controller.mediaLyrics.lyrics,);
                      },
                      icon: const Icon(Icons.copy_rounded),
                      color:
                      Theme.of(context).iconTheme.color!.withAlpha(156),
                    ),
                  ),
                ),
              ],
            ),
          ),
          front: StreamBuilder<QueueState>(
            stream: controller.audioHandler?.queueState,
            builder: (context, snapshot) {
              final queueState = snapshot.data ?? QueueState.empty;
              return GestureDetector(
                onTap: !enabled ? null : () {
                  ///TODO WHEN ADDING MORE FUNCTIONS
                  // tapped.value = true;
                  // Future.delayed(const Duration(seconds: 2), () async {
                  //   tapped.value = false;
                  // });
                },
                onDoubleTapDown: (details) {
                  if (details.globalPosition.dx <= width * 2 / 5) {
                    controller.audioHandler?.customAction('rewind');
                    controller.doubleTapped.value = -1;
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      controller.doubleTapped.value = 0;
                    });
                  }
                  if (details.globalPosition.dx > width * 2 / 5 &&
                      details.globalPosition.dx < width * 3 / 5) {
                    cardKey?.currentState!.toggleCard();
                  }
                  if (details.globalPosition.dx >= width * 3 / 5) {
                    controller.audioHandler?.customAction('fastForward');
                    controller.doubleTapped.value = 1;
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      controller.doubleTapped.value = 0;
                    });
                  }
                },
                onDoubleTap: !enabled ? null : () {
                  Feedback.forLongPress(context);
                },
                onHorizontalDragEnd: !enabled ? null : (DragEndDetails details) {
                  if ((details.primaryVelocity ?? 0) > 100) {
                    if (queueState.hasPrevious) {
                      controller.audioHandler?.skipToPrevious();
                    }
                  }

                  if ((details.primaryVelocity ?? 0) < -100) {
                    if (queueState.hasNext) {
                      controller.audioHandler?.skipToNext();
                    }
                  }
                },
                onLongPress: !enabled ? null : () {
                  if (!controller.offline) {
                    Feedback.forLongPress(context);
                  }
                },
                onVerticalDragStart: !enabled ? null : (details) {
                  controller.dragging.value = true;
                },
                onVerticalDragEnd: !enabled ? null : (details) {
                  controller.dragging.value = false;
                },
                onVerticalDragUpdate: !enabled ? null
                    : (DragUpdateDetails details) {
                  if (details.delta.dy != 0.0) {
                    double volume = controller.audioHandler?.volume.value ?? 0;
                    volume -= details.delta.dy / 150;
                    if (volume < 0) {
                      volume = 0;
                    }
                    if (volume > 1.0) {
                      volume = 1.0;
                    }
                    controller.audioHandler?.setVolume(volume);
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 10.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: artworkUrl.startsWith('file')
                          ? Image(
                        fit: BoxFit.contain,
                        width: flipCardWidth,
                        gaplessPlayback: true,
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace,) {
                          return const Image(fit: BoxFit.cover,
                            image: AssetImage(AppAssets.audioPlayerCover),
                          );
                        },
                        image: FileImage(File(artworkUrl,),),
                      ) : CachedNetworkImage(
                        fit: BoxFit.contain,
                        errorWidget: (BuildContext context, _, _) =>
                        const Image(fit: BoxFit.cover,
                          image: AssetImage(AppAssets.audioPlayerCover),
                        ),
                        placeholder: (BuildContext context, _) =>
                        const Image(fit: BoxFit.cover,
                          image: AssetImage(AppAssets.audioPlayerCover),
                        ),
                        imageUrl: artworkUrl,
                        width: flipCardWidth,
                        memCacheWidth: flipCardWidth.toInt() * 2,
                        memCacheHeight: flipCardWidth.toInt() * 2,
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: controller.doubleTapped,
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
                                      Colors.black.withAlpha(104),
                                      Colors.black.withAlpha(178),
                                    ] : [
                                      Colors.black.withAlpha(178),
                                      Colors.black.withAlpha(104),
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
                      valueListenable: controller.dragging,
                      child: StreamBuilder<double>(
                        stream: controller.audioHandler?.volume,
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
                                          inactiveTrackColor: Theme.of(context).iconTheme.color!.withAlpha(78),
                                          thumbColor: Theme.of(context).iconTheme.color,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0,),
                                          trackShape: const RoundedRectSliderTrackShape(),
                                        ),
                                        child: Slider(
                                          value: controller.audioHandler?.volume.value ?? 0,
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
    );
  }
}
