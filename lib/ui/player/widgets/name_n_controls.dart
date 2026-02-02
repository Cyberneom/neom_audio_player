import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/user_role.dart';

import '../../../utils/audio_player_utilities.dart';
import '../../../utils/constants/audio_player_constants.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../widgets/add_to_playlist_button.dart';
import '../../widgets/like_button.dart';
import '../audio_player_controller.dart';
import 'control_buttons.dart';
import 'seek_bar.dart';
import 'up_next_queue.dart';

class NameNControls extends StatelessWidget {

  final AudioPlayerController audioPlayerController;
  final double width;
  final double height;
  final bool downloadAllowed;
  final bool isLoading;

  const NameNControls({super.key,
    required this.audioPlayerController,
    required this.width,
    required this.height,
    this.downloadAllowed = false,
    this.isLoading = true
  });

  @override
  Widget build(BuildContext context) {
    AudioPlayerController controller = audioPlayerController;

    final double titleBoxHeight = height * 0.3;
    final double seekBoxHeight = height * 0.15;
    final double controlBoxHeight = controller.offline ? height * 0.2
        : (height < 350 ? height * 0.4 : height > 500 ? height * 0.2 : height * 0.3);

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
                          Text(

                            controller.mediaItemTitle.value == 'null' ? controller.mediaItemAlbum.value
                                : '',
                            style: TextStyle(
                              fontSize: titleBoxHeight/4,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                          AppTheme.heightSpace5,
                          GestureDetector(
                            child: Text(
                              controller.mediaItemArtist.isNotEmpty ? controller.mediaItemArtist.value : AppTranslationConstants.unknown.tr.capitalizeFirst,
                              style: TextStyle(
                                fontSize: titleBoxHeight/6,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                            onTap: () => (controller.mediaItem.value?.extras!['ownerEmail']?.isEmpty ?? true) ? {}
                                : controller.goToOwnerProfile(),
                          ),
                          if(controller.mediaItemAlbum.isNotEmpty) TextButton(
                            onPressed: () {
                              controller.gotoPlaylistPlayer();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              textStyle: TextStyle(
                                fontSize: titleBoxHeight / 7,
                                fontWeight: FontWeight.w600,
                                color: Colors.yellow
                              ),
                            ),
                            child: Text(controller.mediaItemAlbum.value.capitalizeFirst,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                  fontSize: titleBoxHeight / 7,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70
                              ),
                            ),

                          ),
                          ///DEPRECATED EXTERNAL PREVIEW
                          // if(!AudioPlayerUtilities.isOwnMediaItem(controller.appMediaItem.value) && AppConfig.instance.appInUse == AppInUse.g)
                          //   Padding(
                          //     padding: const EdgeInsets.only(top: 5),
                          //     child: AnimatedTextKit(
                          //       repeatForever: true,
                          //       animatedTexts: [
                          //         FlickerAnimatedText('(${AudioPlayerTranslationConstants.releasePreview.tr})', textStyle: const TextStyle(fontSize: 12)),
                          //       ],
                          //       onTap: () async {
                          //         await launchUrl(Uri.parse(controller.appMediaItem.value.permaUrl),
                          //           mode: LaunchMode.externalApplication,
                          //         );
                          //       },
                          //     ),
                          //   ),
                        ],
                      ),
                    ),
                  ),
                ),
                /// Seekbar starts from here
                Container(
                  height: seekBoxHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: StreamBuilder<Duration>(
                    stream: controller.audioHandler?.player.positionStream,
                    builder: (context, snapshot) {
                      Duration position  = snapshot.data ?? Duration.zero;
                      Duration duration = controller.audioHandler?.player.duration ?? Duration.zero;

                      if(AppFlavour.addAudioLimitation() && !AudioPlayerUtilities.isOwnMediaItem(controller.mediaItem.value!)) {
                        duration = const Duration(seconds: AudioPlayerConstants.externalDuration);
                      }

                      return SeekBar(
                        position: position,
                        duration: duration,
                        offline: controller.offline,
                        onChangeEnd: (newPosition) => controller.audioHandler?.seek(newPosition),
                        audioHandler: controller.audioHandler,
                        isAdmin: controller.user.userRole != UserRole.subscriber,
                      );
                    },
                  ),
                ),
                /// Final row starts from here
                isLoading ? CircularProgressIndicator() : SizedBox(
                  height: controlBoxHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
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
                                stream: controller.audioHandler?.playbackState
                                    .map((state) => state.shuffleMode == AudioServiceShuffleMode.all,).distinct(),
                                builder: (context, snapshot) {
                                  final shuffleModeEnabled = snapshot.data ?? false;
                                  return IconButton(icon: shuffleModeEnabled
                                        ? const Icon(Icons.shuffle_rounded,)
                                        : Icon(Icons.shuffle_rounded, color: Theme.of(context).disabledColor,),
                                    tooltip: AudioPlayerTranslationConstants.shuffle.tr,
                                    onPressed: () async {
                                      AuthGuard.protect(context, () async {
                                        final enable = !shuffleModeEnabled;
                                        await controller.audioHandler?.setShuffleMode(enable
                                            ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
                                        );
                                      });
                                    },
                                  );
                                },
                              ),
                              if (!controller.offline) LikeButton(itemId: controller.mediaItem.value?.id, itemName: controller.mediaItem.value?.title,),],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ControlButtons(controller.audioHandler, mediaItem: controller.mediaItem.value,),
                              ///DEPRECATED SYNC WITH SPOTIFY BUTTON
                              // if(!AudioPlayerUtilities.isOwnMediaItem(controller.appMediaItem.value) && AppConfig.instance.appInUse == AppInUse.g)
                              //   ElevatedButton(
                              //     onPressed: () async {
                              //       await launchUrl(Uri.parse(controller.appMediaItem.value.permaUrl),
                              //       mode: LaunchMode.externalApplication,
                              //       );
                              //     },
                              //     style: ElevatedButton.styleFrom(
                              //       foregroundColor: Colors.white, backgroundColor: AppColor.bondiBlue, // Text color
                              //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              //       shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(30),
                              //       ),
                              //       elevation: 10
                              //     ),
                              //     child: Text(AudioPlayerTranslationConstants.playOnSpotify.tr,
                              //       style: const TextStyle(fontSize: 15),
                              //     ),
                              //   ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppTheme.heightSpace5,
                              StreamBuilder<AudioServiceRepeatMode>(
                                stream: controller.audioHandler?.playbackState.map((state) => state.repeatMode).distinct(),
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
                                    onPressed: () {
                                      AuthGuard.protect(context, () {
                                        Hive.box(AppHiveBox.settings.name).put(AppHiveConstants.repeatMode, texts[(index + 1) % texts.length],);
                                        controller.audioHandler?.setRepeatMode(cycleModes[(cycleModes.indexOf(repeatMode) + 1) % cycleModes.length],);
                                      });
                                    },
                                  );
                                },
                              ),
                              ///TO IMPLEMENT WHEN ADDING neom_downloads as dependency
                              // downloadAllowed && controller.mediaItem.value != null ? DownloadButton(mediaItem: MediaItemMapper.toAppMediaItem(controller.mediaItem.value!),): const SizedBox.shrink(),
                              AddToPlaylistButton(
                                appMediaItem: controller.appMediaItem.value,
                                playlists: CoreUtilities.filterItemlists(controller.profile.itemlists?.values.toList() ?? [], ItemlistType.playlist,),
                                currentPlaylist: controller.personalPlaylist,)
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ///DEPRECATED SizedBox(height: nowPlayingBoxHeight,),
              ],
            ),
          ),
          UpNextQueue(
            mediaPlayerController: controller,
            panelController: controller.panelController,
            minHeight: nowPlayingBoxHeight,
          ),
        ],
      ),),
    );
  }
}
