import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:sint/sint.dart';
import 'package:neom_audio_player/ui/player/miniplayer_controller.dart';
import 'package:audio_service/audio_service.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

import '../../../data/implementations/jam_session_controller.dart';
import '../../../data/implementations/playlist_hive_controller.dart';
import '../../../data/implementations/radio_controller.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/mappers/media_item_mapper.dart';

class WebBottomPlayer extends StatelessWidget {
  final VoidCallback? onQueueToggle;
  final VoidCallback? onArtworkTap;

  const WebBottomPlayer({Key? key, this.onQueueToggle, this.onArtworkTap}) : super(key: key);

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return SintBuilder<MiniPlayerController>(
      id: 'web_bottom_player',
      builder: (controller) {
        if (controller.mediaItem.value == null) {
          return const SizedBox.shrink();
        }

        final mediaItem = controller.mediaItem.value!;
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 900;

        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColor.surfaceElevated,
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 16),
          child: Row(
            children: [
              // ─── Left: Track Info ───
              SizedBox(
                width: isCompact ? 180 : 280,
                child: Row(
                  children: [
                    // Artwork — tap to open full-screen Now Playing
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onArtworkTap,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: (mediaItem.artUri != null && mediaItem.artUri.toString().isNotEmpty)
                              ? SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: platformNetworkImage(
                                    imageUrl: mediaItem.artUri.toString(),
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorWidget: _artworkPlaceholder(),
                                  ),
                                )
                              : _artworkPlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mediaItem.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  mediaItem.artist ?? '',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (mediaItem.extras?['casete'] == true) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColor.getMain().withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'CASETE',
                                    style: TextStyle(
                                      color: AppColor.getMain(),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                              // Radio badge
                              if (Sint.isRegistered<RadioController>() && Sint.find<RadioController>().currentStation != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'RADIO',
                                    style: TextStyle(color: Colors.purpleAccent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ),
                              ],
                              // Jam Session badge
                              if (Sint.isRegistered<JamSessionController>() && Sint.find<JamSessionController>().isInSession) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'JAM',
                                    style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ─── Like button ───
                    _WebLikeButton(mediaItem: mediaItem),
                  ],
                ),
              ),

              // ─── Center: Playback Controls + Seek ───
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Transport controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Shuffle
                        StreamBuilder<bool>(
                          stream: controller.audioHandler?.playbackState
                              .map((state) => state.shuffleMode == AudioServiceShuffleMode.all)
                              .distinct(),
                          builder: (context, snapshot) {
                            final shuffleOn = snapshot.data ?? false;
                            return _WebControlButton(
                              icon: Icons.shuffle_rounded,
                              size: 18,
                              color: shuffleOn ? Colors.white : Colors.white38,
                              tooltip: AudioPlayerTranslationConstants.shuffle.tr,
                              onTap: () {
                                AuthGuard.protect(context, () {
                                  controller.audioHandler?.setShuffleMode(
                                    shuffleOn ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
                                  );
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // Previous
                        _WebControlButton(
                          icon: Icons.skip_previous_rounded,
                          size: 22,
                          tooltip: AudioPlayerTranslationConstants.skipPrevious.tr,
                          onTap: () => controller.audioHandler?.skipToPrevious(),
                        ),
                        const SizedBox(width: 6),
                        // Play/Pause
                        StreamBuilder<PlaybackState>(
                          stream: controller.audioHandler?.playbackState,
                          builder: (context, snapshot) {
                            final playbackState = snapshot.data;
                            final playing = playbackState?.playing ?? false;
                            final isBuffering = playbackState?.processingState == AudioProcessingState.loading
                                || playbackState?.processingState == AudioProcessingState.buffering;

                            return Tooltip(
                              message: playing ? AppTranslationConstants.pause.tr : AppTranslationConstants.play.tr,
                              waitDuration: const Duration(milliseconds: 500),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: isBuffering
                                    ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                      )
                                    : InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () => playing ? controller.audioHandler?.pause() : controller.audioHandler?.play(),
                                        child: Icon(
                                          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.black,
                                          size: 22,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        // Next
                        _WebControlButton(
                          icon: Icons.skip_next_rounded,
                          size: 22,
                          tooltip: AudioPlayerTranslationConstants.skipNext.tr,
                          onTap: () => controller.audioHandler?.skipToNext(),
                        ),
                        const SizedBox(width: 8),
                        // Repeat
                        StreamBuilder<AudioServiceRepeatMode>(
                          stream: controller.audioHandler?.playbackState
                              .map((state) => state.repeatMode)
                              .distinct(),
                          builder: (context, snapshot) {
                            final repeatMode = snapshot.data ?? AudioServiceRepeatMode.none;
                            final isActive = repeatMode != AudioServiceRepeatMode.none;
                            final isOne = repeatMode == AudioServiceRepeatMode.one;

                            return _WebControlButton(
                              icon: isOne ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                              size: 18,
                              color: isActive ? Colors.white : Colors.white38,
                              tooltip: 'Repeat',
                              onTap: () {
                                AuthGuard.protect(context, () {
                                  const modes = [
                                    AudioServiceRepeatMode.none,
                                    AudioServiceRepeatMode.all,
                                    AudioServiceRepeatMode.one,
                                  ];
                                  const texts = ['None', 'All', 'One'];
                                  final idx = modes.indexOf(repeatMode);
                                  final nextIdx = (idx + 1) % modes.length;
                                  Hive.box(AppHiveBox.settings.name).put(AppHiveConstants.repeatMode, texts[nextIdx]);
                                  controller.audioHandler?.setRepeatMode(modes[nextIdx]);
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Seek bar
                    StreamBuilder<Duration>(
                      stream: controller.audioHandler?.player.positionStream,
                      builder: (context, positionSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;
                        final duration = controller.audioHandler?.player.duration ?? Duration.zero;

                        double sliderValue = 0.0;
                        if (duration.inMilliseconds > 0) {
                          sliderValue = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
                        }

                        return ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isCompact ? 300 : 500),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Text(
                                  _formatDuration(position),
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _HoverSeekSlider(
                                  value: sliderValue,
                                  onChanged: (v) {
                                    final newPosition = Duration(
                                      milliseconds: (v * duration.inMilliseconds).round(),
                                    );
                                    controller.audioHandler?.seek(newPosition);
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  _formatDuration(duration),
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ─── Right: Speed + Sleep Timer + Queue + Volume ───
              if (!isCompact)
                SizedBox(
                  width: 320,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Playback speed
                      _WebSpeedButton(controller: controller),
                      const SizedBox(width: 4),
                      // Sleep timer
                      _WebSleepTimerButton(controller: controller),
                      const SizedBox(width: 4),
                      // Queue toggle button
                      if (onQueueToggle != null)
                        _WebControlButton(
                          icon: Icons.queue_music_rounded,
                          size: 20,
                          color: Colors.white70,
                          tooltip: AudioPlayerTranslationConstants.upNext.tr,
                          onTap: onQueueToggle,
                        ),
                      const SizedBox(width: 8),
                      // Volume
                      StreamBuilder<double>(
                        stream: controller.audioHandler?.volume,
                        builder: (context, snapshot) {
                          final volume = snapshot.data ?? 1.0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: volume == 0 ? 'Unmute' : 'Mute',
                                waitDuration: const Duration(milliseconds: 500),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      controller.audioHandler?.setVolume(volume == 0 ? 1.0 : 0.0);
                                    },
                                    child: Icon(
                                      volume == 0
                                          ? Icons.volume_off_rounded
                                          : volume < 0.5
                                              ? Icons.volume_down_rounded
                                              : Icons.volume_up_rounded,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: volume,
                                    onChanged: (v) => controller.audioHandler?.setVolume(v),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _artworkPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColor.getMain().withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 24),
    );
  }
}

/// Like button that toggles favorite status.
class _WebLikeButton extends StatefulWidget {
  final MediaItem mediaItem;
  const _WebLikeButton({required this.mediaItem});

  @override
  State<_WebLikeButton> createState() => _WebLikeButtonState();
}

class _WebLikeButtonState extends State<_WebLikeButton> {
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkLiked();
  }

  @override
  void didUpdateWidget(covariant _WebLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaItem.id != widget.mediaItem.id) _checkLiked();
  }

  Future<void> _checkLiked() async {
    final liked = await PlaylistHiveController().checkPlaylist(
      AppHiveBox.favoriteItems.name,
      widget.mediaItem.id,
    );
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    if (_isLiked) {
      await PlaylistHiveController().removeLiked(widget.mediaItem.id);
    } else {
      await PlaylistHiveController().addItemToPlaylist(
        AppHiveBox.favoriteItems.name,
        widget.mediaItem,
      );
    }
    if (mounted) setState(() => _isLiked = !_isLiked);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _isLiked
          ? AppTranslationConstants.favorite.tr
          : AppTranslationConstants.like.tr,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggleLike,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isLiked ? AppColor.getMain() : Colors.white54,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// Playback speed popup.
class _WebSpeedButton extends StatelessWidget {
  final MiniPlayerController controller;
  const _WebSpeedButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: AudioPlayerTranslationConstants.playbackSpeed.tr,
      icon: const Icon(Icons.speed_rounded, color: Colors.white70, size: 20),
      color: AppColor.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (speed) => controller.audioHandler?.setSpeed(speed),
      itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
        return PopupMenuItem<double>(
          value: speed,
          height: 36,
          child: Text(
            '${speed}x',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        );
      }).toList(),
    );
  }
}

/// Sleep timer popup.
class _WebSleepTimerButton extends StatelessWidget {
  final MiniPlayerController controller;
  const _WebSleepTimerButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: AudioPlayerTranslationConstants.sleepTimer.tr,
      icon: const Icon(Icons.bedtime_outlined, color: Colors.white70, size: 20),
      color: AppColor.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (minutes) {
        controller.audioHandler?.customAction('sleepTimer', {'minutes': minutes});
      },
      itemBuilder: (_) => [15, 30, 45, 60, 90].map((min) {
        return PopupMenuItem<int>(
          value: min,
          height: 36,
          child: Text(
            '$min min',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        );
      }).toList(),
    );
  }
}

/// Small icon button used in web transport controls with optional tooltip.
class _WebControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback? onTap;
  final String? tooltip;

  const _WebControlButton({
    required this.icon,
    required this.size,
    this.color = Colors.white,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      child = Tooltip(
        message: tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: child,
      );
    }

    return child;
  }
}

/// A seek slider that shows the thumb only on hover (web-friendly).
class _HoverSeekSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _HoverSeekSlider({required this.value, required this.onChanged});

  @override
  State<_HoverSeekSlider> createState() => _HoverSeekSliderState();
}

class _HoverSeekSliderState extends State<_HoverSeekSlider> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: _hovered ? 5 : 3,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: _hovered ? 6 : 0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          activeTrackColor: _hovered ? AppColor.getMain() : Colors.white,
          inactiveTrackColor: Colors.white24,
          thumbColor: Colors.white,
        ),
        child: Slider(
          value: widget.value,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
