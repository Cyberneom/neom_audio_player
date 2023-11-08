import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyric_ui/ui_netease.dart';
import 'package:flutter_lyric/lyrics_model_builder.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:flutter_lyric/lyrics_reader_widget.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:rxdart/rxdart.dart' as rx;

import '../../../domain/entities/queue_state.dart';
import '../../../domain/use_cases/neom_audio_handler.dart';
import '../../../to_delete/lyrics.dart';
import '../../../utils/constants/app_hive_constants.dart';
import '../../../utils/constants/player_translation_constants.dart';
import '../../widgets/add_to_playlist.dart';
import '../../widgets/empty_screen.dart';
import '../../widgets/seek_bar.dart';

class ArtWorkWidget extends StatefulWidget {
  final GlobalKey<FlipCardState>? cardKey;
  final AppMediaItem appMediaItem;
  final bool offline;
  final bool getLyricsOnline;
  final double width;
  final NeomAudioHandler audioHandler;

  const ArtWorkWidget({super.key,
    this.cardKey,
    required this.appMediaItem,
    required this.width,
    this.offline = false,
    required this.getLyricsOnline,
    required this.audioHandler,
  });

  @override
  _ArtWorkWidgetState createState() => _ArtWorkWidgetState();
}

class _ArtWorkWidgetState extends State<ArtWorkWidget> {
  final ValueNotifier<bool> dragging = ValueNotifier<bool>(false);
  final ValueNotifier<bool> tapped = ValueNotifier<bool>(false);
  final ValueNotifier<int> doubletapped = ValueNotifier<int>(0);
  final ValueNotifier<bool> done = ValueNotifier<bool>(false);
  final ValueNotifier<String> lyricsSource = ValueNotifier<String>('');
  Map lyrics = {
    'id': '',
    'lyrics': '',
    'source': '',
    'type': '',
  };
  final lyricUI = UINetease();
  LyricsReaderModel? lyricsReaderModel;
  bool flipped = false;

  void fetchLyrics() {
    AppUtilities.logger.i('Fetching lyrics for ${widget.appMediaItem.name}');
    done.value = false;
    lyricsSource.value = '';
    String appMediaItemLyric = widget.appMediaItem.lyrics.isNotEmpty || (widget.appMediaItem.description?.isNotEmpty ?? false)  ? (widget.appMediaItem.lyrics.isNotEmpty ? widget.appMediaItem.lyrics : widget.appMediaItem.description ?? '') : '';
    if (widget.offline) {
      if(appMediaItemLyric.isNotEmpty) {
        lyricsReaderModel = LyricsModelBuilder.create()
            .bindLyricToMain(appMediaItemLyric).getModel();
      } else {
        Lyrics.getOffLyrics(widget.appMediaItem.permaUrl,
        ).then((value) {
          if (value == '' && widget.getLyricsOnline) {
            Lyrics.getLyrics(
              id: widget.appMediaItem.id,
              isInternalLyric: widget.appMediaItem.lyrics.isNotEmpty,
              title: widget.appMediaItem.name,
              artist: widget.appMediaItem.artist,
            ).then((Map value) {
              lyrics['lyrics'] = value['lyrics'];
              lyrics['type'] = value['type'];
              lyrics['source'] = value['source'];
              lyrics['id'] = widget.appMediaItem.id;
              done.value = true;
              lyricsSource.value = lyrics['source'].toString();
              lyricsReaderModel = LyricsModelBuilder.create()
                  .bindLyricToMain(lyrics['lyrics'].toString())
                  .getModel();
            });
          } else {
            AppUtilities.logger.i('Lyrics found offline');
            lyrics['lyrics'] = value;
            lyrics['type'] = value.startsWith('[00') ? 'lrc' : 'text';
            lyrics['source'] = 'Local';
            lyrics['id'] = widget.appMediaItem.id;
            done.value = true;
            lyricsSource.value = lyrics['source'].toString();
            lyricsReaderModel = LyricsModelBuilder.create()
                .bindLyricToMain(lyrics['lyrics'].toString())
                .getModel();
          }
        });
      }

    } else {
      if(appMediaItemLyric.isNotEmpty) {
        lyrics['lyrics'] = appMediaItemLyric;
        lyrics['source'] = 'Gigmeout';
        lyrics['type'] = 'text';
        lyrics['id'] = widget.appMediaItem.id;

        done.value = true;
        lyricsSource.value = lyrics['source'].toString();
        lyricsReaderModel = LyricsModelBuilder.create()
            .bindLyricToMain(lyrics['lyrics'].toString())
            .getModel();
      } else {
        Lyrics.getLyrics(
          id: widget.appMediaItem.id,
          isInternalLyric: widget.appMediaItem.lyrics.isNotEmpty,
          title: widget.appMediaItem.name,
          artist: widget.appMediaItem.artist.toString(),
        ).then((Map value) {
          if (widget.appMediaItem.id != value['id']) {
            done.value = true;
            return;
          }
          lyrics['lyrics'] = value['lyrics'];
          lyrics['type'] = value['type'];
          lyrics['source'] = value['source'];
          lyrics['id'] = widget.appMediaItem.id;
          done.value = true;
          lyricsSource.value = lyrics['source'].toString();
          lyricsReaderModel = LyricsModelBuilder.create()
              .bindLyricToMain(lyrics['lyrics'].toString())
              .getModel();
        });
      }
    }

    done.value = true;

  }

  @override
  Widget build(BuildContext context) {
    if (flipped && lyrics['id'] != widget.appMediaItem.id) {
      fetchLyrics();
    }
    return SizedBox(
      height: widget.width * 0.85,
      width: widget.width * 0.85,
      child: Hero(
        tag: 'currentArtwork_',
        child: FlipCard(
          key: widget.cardKey,
          flipOnTouch: false,
          onFlipDone: (value) {
            flipped = value;
            if (flipped && lyrics['id'] != widget.appMediaItem.id) {
              fetchLyrics();
            }
          },
          back: GestureDetector(
            onTap: () => widget.cardKey?.currentState!.toggleCard(),
            onDoubleTap: () => widget.cardKey?.currentState!.toggleCard(),
            child: Stack(
              children: [
                ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                    ).createShader(
                      Rect.fromLTRB(0, 0, rect.width, rect.height),
                    );
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
                        valueListenable: done,
                        child: const CircularProgressIndicator(),
                        builder: (
                            BuildContext context,
                            bool value,
                            Widget? child,
                            ) {
                          return value ? lyrics['lyrics'] == '' ? emptyScreen(
                            context, 0,
                            ':( ', 80.0,
                            PlayerTranslationConstants.lyrics.tr, 40.0,
                            PlayerTranslationConstants.notAvailable.tr, 20.0,
                            useWhite: true,
                          ) : lyrics['type'] == 'text'
                              ? SelectableText(
                            lyrics['lyrics'].toString(),
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
                                model: lyricsReaderModel,
                                position: position.inMilliseconds,
                                lyricUi: UINetease(highlight: false),
                                playing: true,
                                size: Size(
                                  widget.width * 0.85,
                                  widget.width * 0.85,
                                ),
                                emptyBuilder: () => Center(
                                  child: Text('Lyrics Not Found',
                                    style: lyricUI.getOtherMainTextStyle(),
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
                ValueListenableBuilder(
                  valueListenable: lyricsSource,
                  child: const CircularProgressIndicator(),
                  builder: (
                      BuildContext context,
                      String value,
                      Widget? child,
                      ) {
                    if (value == '' || value == AppFlavour.getAppName()) {
                      return const SizedBox();
                    }
                    return Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        '${AppTranslationConstants.poweredBy.tr} $value',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontSize: 10.0, color: Colors.white70),
                      ),
                    );
                  },
                ),
                Align(
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
                        CoreUtilities.copyToClipboard(
                          context: context,
                          text: lyrics['lyrics'].toString(),
                        );
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
            stream: widget.audioHandler.queueState,
            builder: (context, snapshot) {
              final queueState = snapshot.data ?? QueueState.empty;

              final bool enabled = Hive.box(AppHiveConstants.settings).get('enableGesture', defaultValue: true) as bool;
              return GestureDetector(
                onTap: !enabled ? null : () {
                  AddToPlaylist().addToPlaylist(context, widget.appMediaItem,);
                  ///TODO WHEN ADDING MORE FUNCTIONS
                  // tapped.value = true;
                  // Future.delayed(const Duration(seconds: 2), () async {
                  //   tapped.value = false;
                  // });
                },
                onDoubleTapDown: (details) {
                  if (details.globalPosition.dx <= widget.width * 2 / 5) {
                    widget.audioHandler.customAction('rewind');
                    doubletapped.value = -1;
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      doubletapped.value = 0;
                    });
                  }
                  if (details.globalPosition.dx > widget.width * 2 / 5 &&
                      details.globalPosition.dx < widget.width * 3 / 5) {
                    widget.cardKey?.currentState!.toggleCard();
                  }
                  if (details.globalPosition.dx >= widget.width * 3 / 5) {
                    widget.audioHandler.customAction('fastForward');
                    doubletapped.value = 1;
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      doubletapped.value = 0;
                    });
                  }
                },
                onDoubleTap: !enabled ? null : () {
                  Feedback.forLongPress(context);
                },
                onHorizontalDragEnd: !enabled ? null : (DragEndDetails details) {
                  if ((details.primaryVelocity ?? 0) > 100) {
                    if (queueState.hasPrevious) {
                      widget.audioHandler.skipToPrevious();
                    }
                  }

                  if ((details.primaryVelocity ?? 0) < -100) {
                    if (queueState.hasNext) {
                      widget.audioHandler.skipToNext();
                    }
                  }
                },
                onLongPress: !enabled ? null : () {
                  if (!widget.offline) {
                    Feedback.forLongPress(context);
                    // AddToPlaylist().addToPlaylist(context, MediaItemMapper.appMediaItemToMediaItem(appMediaItem: widget.appMediaItem));
                  }
                },
                onVerticalDragStart: !enabled ? null : (_) {
                  dragging.value = true;
                },
                onVerticalDragEnd: !enabled ? null : (_) {
                  dragging.value = false;
                },
                onVerticalDragUpdate: !enabled ? null
                    : (DragUpdateDetails details) {
                  if (details.delta.dy != 0.0) {
                    double volume = widget.audioHandler.volume.value ?? 0;
                    volume -= details.delta.dy / 150;
                    if (volume < 0) {
                      volume = 0;
                    }
                    if (volume > 1.0) {
                      volume = 1.0;
                    }
                    widget.audioHandler.setVolume(volume);
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
                      child: widget.appMediaItem.imgUrl.startsWith('file')
                          ? Image(
                        fit: BoxFit.contain,
                        width: widget.width * 0.85,
                        gaplessPlayback: true,
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace,) {
                          return const Image(fit: BoxFit.cover,
                            image: AssetImage(AppAssets.musicPlayerCover),
                          );
                        },
                        image: FileImage(File(widget.appMediaItem.imgUrl,),),
                      ) : CachedNetworkImage(
                        fit: BoxFit.contain,
                        errorWidget: (BuildContext context, _, __) =>
                        const Image(fit: BoxFit.cover,
                          image: AssetImage(AppAssets.musicPlayerCover),
                        ),
                        placeholder: (BuildContext context, _) =>
                        const Image(fit: BoxFit.cover,
                          image: AssetImage(AppAssets.musicPlayerCover),
                        ),
                        imageUrl: widget.appMediaItem.imgUrl,
                        width: widget.width * 0.85,
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: dragging,
                      child: StreamBuilder<double>(
                        stream: widget.audioHandler.volume,
                        builder: (context, snapshot) {
                          final double volumeValue = snapshot.data ?? 1.0;
                          return Center(
                            child: SizedBox(
                              width: 60.0,
                              height: widget.width * 0.7,
                              child: Card(
                                color: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.fitHeight,
                                        child: RotatedBox(
                                          quarterTurns: -1,
                                          child: SliderTheme(
                                            data: SliderTheme.of(context)
                                                .copyWith(
                                              thumbShape: HiddenThumbComponentShape(),
                                              activeTrackColor: Theme.of(context).colorScheme.secondary,
                                              inactiveTrackColor: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                                              trackShape: const RoundedRectSliderTrackShape(),
                                            ),
                                            child: ExcludeSemantics(
                                              child: Slider(
                                                value: widget.audioHandler.volume.valueWrapper!.value,
                                                onChanged: (_) {},
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 20.0,),
                                      child: Icon(
                                        volumeValue == 0
                                            ? Icons.volume_off_rounded
                                            : volumeValue > 0.6
                                            ? Icons.volume_up_rounded
                                            : Icons.volume_down_rounded,
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
                    ValueListenableBuilder(
                      valueListenable: doubletapped,
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
                                    const SizedBox(),
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
