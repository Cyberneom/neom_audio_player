import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_hive_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/itemlist_type.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';
import 'package:neom_media_player/ui/widgets/download_button.dart';
import 'package:neom_media_player/utils/constants/player_translation_constants.dart';
import 'package:neom_media_player/utils/helpers/media_item_mapper.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/position_data.dart';
import '../../../utils/audio_player_utilities.dart';
import '../../../utils/constants/audio_player_constants.dart';
import '../../widgets/add_to_playlist_button.dart';
import '../../widgets/like_button.dart';
import '../audio_player_controller.dart';
import 'control_buttons.dart';
import 'seek_bar.dart';
import 'up_next_queue.dart';

class NameNControls extends StatelessWidget {

  final AudioPlayerController mediaPlayerController;
  final double width;
  final double height;
  final bool downloadAllowed;
  final bool isLoading;

  const NameNControls({super.key,
    required this.mediaPlayerController,
    required this.width,
    required this.height,
    this.downloadAllowed = false,
    this.isLoading = true
  });

  @override
  Widget build(BuildContext context) {
    AudioPlayerController _ = mediaPlayerController;

    final double titleBoxHeight = height * 0.3;
    final double seekBoxHeight = height * 0.18;
    final double controlBoxHeight = _.offline ? height * 0.2
        : (height < 350 ? height * 0.4 : height > 500 ? height * 0.2 : height * 0.38);

    final double nowPlayingBoxHeight = min(70, height * 0.15);

    return SizedBox(
      width: width,
      height: height,
      child: Obx(()=>Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          Text(_.mediaItemTitle.value,
                            style: TextStyle(
                              fontSize: titleBoxHeight/3.2,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                          AppTheme.heightSpace5,
                          GestureDetector(
                            child: Text(
                              _.mediaItemArtist.isNotEmpty ? _.mediaItemArtist.value : AppTranslationConstants.unknown.tr.capitalizeFirst,
                              style: TextStyle(
                                fontSize: titleBoxHeight / 6,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                            onTap: () => (_.appMediaItem.value.artistId?.isEmpty ?? true) ? {}
                                : _.goToOwnerProfile(),
                          ),
                          if(_.mediaItemAlbum.isNotEmpty) TextButton(
                            onPressed: () {
                              _.gotoPlaylistPlayer();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              textStyle: TextStyle(
                                fontSize: titleBoxHeight / 7,
                                fontWeight: FontWeight.w600,
                                color: Colors.yellow
                              ),
                            ),
                            child: Text(_.mediaItemAlbum.value.capitalizeFirst,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                  fontSize: titleBoxHeight / 7,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70
                              ),
                            ),

                          ),
                          if(!AudioPlayerUtilities.isOwnMediaItem(_.appMediaItem.value) && AppFlavour.appInUse == AppInUse.g)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: AnimatedTextKit(
                                repeatForever: true,
                                animatedTexts: [
                                  FlickerAnimatedText('(${AppTranslationConstants.releasePreview.tr})', textStyle: const TextStyle(fontSize: 12)),
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

                      if(!AudioPlayerUtilities.isOwnMediaItem(_.appMediaItem.value) && AppFlavour.appInUse == AppInUse.g) {
                        duration = const Duration(seconds: AudioPlayerConstants.externalDuration);
                      } else {
                        duration = Duration(seconds: _.audioHandler?.player.duration?.inSeconds ?? 0);
                      }

                      if(snapshot.data != null) {
                        PositionData positionData = snapshot.data!;
                        position = positionData.position;
                      }

                      return SeekBar(
                        position: position,
                        duration: duration,
                        offline: _.offline,
                        onChangeEnd: (newPosition) => _.audioHandler?.seek(newPosition),
                        audioHandler: _.audioHandler,
                        isAdmin: _.user.userRole != UserRole.subscriber,
                      );
                    },
                  ),
                ),
                /// Final row starts from here
                isLoading ? CircularProgressIndicator() : SizedBox(
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
                                stream: _.audioHandler?.playbackState
                                    .map((state) => state.shuffleMode == AudioServiceShuffleMode.all,).distinct(),
                                builder: (context, snapshot) {
                                  final shuffleModeEnabled = snapshot.data ?? false;
                                  return IconButton(icon: shuffleModeEnabled
                                        ? const Icon(Icons.shuffle_rounded,)
                                        : Icon(Icons.shuffle_rounded, color: Theme.of(context).disabledColor,),
                                    tooltip: PlayerTranslationConstants.shuffle.tr,
                                    onPressed: () async {
                                      final enable = !shuffleModeEnabled;
                                      await _.audioHandler?.setShuffleMode(enable
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
                              ControlButtons(_.audioHandler, mediaItem: _.mediaItem.value,),
                              if(!AudioPlayerUtilities.isOwnMediaItem(_.appMediaItem.value) && AppFlavour.appInUse == AppInUse.g)
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
                                stream: _.audioHandler?.playbackState.map((state) => state.repeatMode).distinct(),
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
                                      await Hive.box(AppHiveBox.settings.name).put(AppHiveConstants.repeatMode, texts[(index + 1) % texts.length],);
                                      await _.audioHandler?.setRepeatMode(cycleModes[(cycleModes.indexOf(repeatMode) + 1) % cycleModes.length],
                                      );
                                    },
                                  );
                                },
                              ),
                              downloadAllowed && _.mediaItem.value != null ? DownloadButton(mediaItem: MediaItemMapper.toAppMediaItem(_.mediaItem.value!),): const SizedBox.shrink(),
                              AddToPlaylistButton(appMediaItem: _.appMediaItem.value, playlists: AppUtilities.filterItemlists(_.profile.itemlists?.values.toList() ?? [], ItemlistType.playlist,),
                                currentPlaylist: _.personalPlaylist,)
                              // _.createPopMenuOption(context, _.appMediaItem.value),
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
          ),
          UpNextQueue(
            mediaPlayerController: _,
            panelController: _.panelController,
            minHeight: nowPlayingBoxHeight,
          ),
        ],
      ),),
    );
  }
}
