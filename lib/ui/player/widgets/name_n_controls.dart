import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/position_data.dart';
import '../../../utils/constants/app_hive_constants.dart';
import '../../../utils/constants/music_player_constants.dart';
import '../../../utils/constants/player_translation_constants.dart';
import '../../../utils/helpers/media_item_mapper.dart';
import '../../../utils/music_player_utilities.dart';
import '../../widgets/download_button.dart';
import '../../widgets/go_spotify_button.dart';
import '../../widgets/like_button.dart';
import '../media_player_controller.dart';
import 'control_buttons.dart';
import 'seek_bar.dart';
import 'up_next_queue.dart';

class NameNControls extends StatelessWidget {

  final MediaPlayerController mediaPlayerController;
  final double width;
  final double height;
  final PanelController panelController;
  final bool downloadAllowed;

  const NameNControls({super.key,
    required this.mediaPlayerController,
    required this.width,
    required this.height,
    required this.panelController,
    this.downloadAllowed = false,
  });

  @override
  Widget build(BuildContext context) {
    MediaPlayerController _ = mediaPlayerController;

    final double titleBoxHeight = height * 0.3;
    final double seekBoxHeight = height * 0.18;
    final double controlBoxHeight = _.offline ? height * 0.2
        : (height < 350 ? height * 0.4 : height > 500 ? height * 0.2 : height * 0.38);

    final double nowPlayingBoxHeight = min(70, height * 0.15);

    MediaItem mediaItem = MediaItemMapper.appMediaItemToMediaItem(appMediaItem: _.appMediaItem.value);
    ///DEPRECATED final List<String> artists = mediaItem.artist.toString().split(', ');

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Text(mediaItem.title.trim(),
                          style: TextStyle(
                            fontSize: titleBoxHeight/3,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                        AppTheme.heightSpace5,
                        GestureDetector(
                          child: Text(
                            '${(mediaItem.artist ?? '').isNotEmpty ? mediaItem.artist : AppTranslationConstants.unknown.tr.capitalizeFirst}'
                                '${(mediaItem.album ?? '').isNotEmpty && (mediaItem.album ?? '') != (mediaItem.artist ?? '') ? ' • ${mediaItem.album}' : ''}',
                            style: TextStyle(
                              fontSize: titleBoxHeight / 6.75,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                          onTap: () => (_.appMediaItem.value.artistId?.isEmpty ?? true) ? {}
                              : Get.find<UserController>().profile.id == _.appMediaItem.value.artistId ? Get.toNamed(AppRouteConstants.profile)
                              : Get.toNamed(AppRouteConstants.mateDetails, arguments: _.appMediaItem.value.artistId),
                        ),
                        if(!MusicPlayerUtilities.isOwnMediaItem(_.appMediaItem.value))
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: AnimatedTextKit(
                              repeatForever: true,
                              animatedTexts: [
                                FlickerAnimatedText('(${AppTranslationConstants.previewFromSpotify.tr})', textStyle: const TextStyle(fontSize: 12)),
                              ],
                              onTap: () async {
                                await launchUrl(Uri.parse(_.appMediaItem.value.permaUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              /// Seekbar starts from here
              Container(
                height: seekBoxHeight,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: StreamBuilder<PositionData>(
                  stream: _.positionDataStream,
                  builder: (context, snapshot) {
                    Duration position = Duration.zero;
                    ///DEPRECATED Duration bufferedPosition = Duration.zero;
                    Duration duration = Duration.zero;

                    if(MusicPlayerUtilities.isOwnMediaItem(_.appMediaItem.value)) {
                      duration = Duration(seconds: _.appMediaItem.value.duration);
                    } else {
                      duration = const Duration(seconds: MusicPlayerConstants.externalDuration);
                    }

                    if(snapshot.data != null) {
                      PositionData positionData = snapshot.data!;
                      position = positionData.position;
                    }

                    return SeekBar(
                      position: position,
                      duration: duration,
                      offline: _.offline,
                      onChangeEnd: (newPosition) => _.audioHandler.seek(newPosition),
                      audioHandler: _.audioHandler,
                    );
                  },
                ),
              ),
              /// Final row starts from here
              SizedBox(
                height: controlBoxHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppTheme.heightSpace5,
                            StreamBuilder<bool>(
                              stream: _.audioHandler.playbackState
                                  .map((state) => state.shuffleMode == AudioServiceShuffleMode.all,).distinct(),
                              builder: (context, snapshot) {
                                final shuffleModeEnabled = snapshot.data ?? false;
                                return IconButton(icon: shuffleModeEnabled
                                      ? const Icon(Icons.shuffle_rounded,)
                                      : Icon(Icons.shuffle_rounded, color: Theme.of(context).disabledColor,),
                                  tooltip: PlayerTranslationConstants.shuffle.tr,
                                  onPressed: () async {
                                    final enable = !shuffleModeEnabled;
                                    await _.audioHandler.setShuffleMode(enable
                                        ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
                                    );
                                  },
                                );
                              },
                            ),
                            if (!_.offline) LikeButton(appMediaItem: _.appMediaItem.value),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ControlButtons(_.audioHandler, mediaItem: mediaItem,),
                            if(!MusicPlayerUtilities.isOwnMediaItem(_.appMediaItem.value))
                              ElevatedButton(
                                onPressed: () async {
                                  await launchUrl(Uri.parse(_.appMediaItem.value.permaUrl),
                                  mode: LaunchMode.externalApplication,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white, backgroundColor: AppColor.bondiBlue, // Text color
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 10
                                ),
                                child: Text(AppTranslationConstants.playOnSpotify.tr,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppTheme.heightSpace5,
                            StreamBuilder<AudioServiceRepeatMode>(
                              stream: _.audioHandler.playbackState.map((state) => state.repeatMode).distinct(),
                              builder: (context, snapshot) {
                                final repeatMode = snapshot.data ?? AudioServiceRepeatMode.none;
                                const texts = ['None', 'All', 'One'];
                                final icons = [
                                  Icon(Icons.repeat_rounded, color: Theme.of(context).disabledColor,),
                                  const Icon(Icons.repeat_rounded,),
                                  const Icon(Icons.repeat_one_rounded,),
                                ];
                                const cycleModes = [
                                  AudioServiceRepeatMode.none,
                                  AudioServiceRepeatMode.all,
                                  AudioServiceRepeatMode.one,
                                ];
                                final index = cycleModes.indexOf(repeatMode);
                                return IconButton(
                                  icon: icons[index],
                                  tooltip: 'Repeat ${texts[(index + 1) % texts.length]}',
                                  onPressed: () async {
                                    await Hive.box(AppHiveConstants.settings).put(AppHiveConstants.repeatMode, texts[(index + 1) % texts.length],);
                                    await _.audioHandler.setRepeatMode(cycleModes[(cycleModes.indexOf(repeatMode) + 1) % cycleModes.length],
                                    );
                                  },
                                );
                              },
                            ),
                            MusicPlayerUtilities.isOwnMediaItem(_.appMediaItem.value)
                                ? (downloadAllowed ? DownloadButton(mediaItem: MediaItemMapper.fromMediaItem(mediaItem),): const SizedBox.shrink())
                                : GoSpotifyButton(appMediaItem: _.appMediaItem.value),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: nowPlayingBoxHeight,),
            ],
          ),
          UpNextQueue(
            mediaPlayerController: _,
            panelController: _.panelController,
            minHeight: nowPlayingBoxHeight,
          ),
        ],
      ),
    );
  }
}
