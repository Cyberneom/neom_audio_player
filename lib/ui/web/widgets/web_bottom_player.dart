import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:sint/sint.dart';
import 'package:neom_audio_player/ui/player/miniplayer_controller.dart';
import 'package:audio_service/audio_service.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

import '../../../data/implementations/enhanced_playback_controller.dart';
import '../../../data/implementations/playlist_hive_controller.dart';
import '../../../domain/use_cases/jam_session_service.dart';
import '../../../domain/use_cases/radio_service.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/enums/playback_mode.dart';
import '../utils/web_color_extractor.dart';
import '../utils/web_image_resolver.dart';
import '../utils/web_player_helpers.dart';
import '../utils/web_track_transition.dart';
import 'web_pseudo_visualizer.dart';

class WebBottomPlayer extends StatelessWidget {
  final VoidCallback? onQueueToggle;
  final VoidCallback? onArtworkTap;

  const WebBottomPlayer({Key? key, this.onQueueToggle, this.onArtworkTap}) : super(key: key);

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

        final titleText = (mediaItem.title.trim().isNotEmpty && mediaItem.title != 'null')
            ? mediaItem.title
            : ((mediaItem.album?.trim().isNotEmpty ?? false) && mediaItem.album != 'null'
                ? mediaItem.album!
                : AudioPlayerTranslationConstants.lookingForNewMusic.tr);

        final artistText = (mediaItem.artist?.trim().isNotEmpty ?? false) && mediaItem.artist != 'null'
            ? mediaItem.artist!
            : '';

        final isRetracted = controller.isWebPlayerRetracted.value && !isCompact;

        if (isRetracted) {
          return Container(
            width: 320,
            height: 180,
            decoration: BoxDecoration(
              color: AppColor.surfaceElevated,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Top Row: Title, Artist & Expand Button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            artistText,
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _WebLikeButton(mediaItem: mediaItem),
                    const SizedBox(width: 4),
                    _WebControlButton(
                      icon: Icons.open_in_full_rounded,
                      size: 18,
                      color: Colors.white70,
                      tooltip: 'Stretches the player horizontally',
                      onTap: () {
                        controller.isWebPlayerRetracted.value = false;
                        controller.update(['web_bottom_player']);
                      },
                    ),
                  ],
                ),
                // Middle Row: Artwork on the left, Playback controls on the right
                Row(
                  children: [
                    _WebHoverArtwork(
                      mediaItem: mediaItem,
                      size: 52,
                      onTap: onArtworkTap,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Previous
                              _WebControlButton(
                                icon: Icons.skip_previous_rounded,
                                size: 20,
                                tooltip: AudioPlayerTranslationConstants.skipPrevious.tr,
                                onTap: () => controller.audioHandler?.skipToPrevious(),
                              ),
                              const SizedBox(width: 12),
                              // Play/Pause
                              StreamBuilder<PlaybackState>(
                                stream: controller.audioHandler?.playbackState,
                                builder: (context, snapshot) {
                                  final playing = snapshot.data?.playing ?? false;
                                  return Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => playing ? controller.audioHandler?.pause() : controller.audioHandler?.play(),
                                      child: Icon(
                                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              // Next
                              _WebControlButton(
                                icon: Icons.skip_next_rounded,
                                size: 20,
                                tooltip: AudioPlayerTranslationConstants.skipNext.tr,
                                onTap: () => controller.audioHandler?.skipToNext(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Bottom Row: Seek Bar
                StreamBuilder<Duration>(
                  stream: controller.audioHandler?.player.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final duration = controller.audioHandler?.player.duration ?? Duration.zero;
                    final sliderValue = computeSliderValue(position, duration);

                    return Row(
                      children: [
                        Text(
                          formatPlayerDuration(position),
                          style: TextStyle(color: Colors.grey[400], fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HoverSeekSlider(
                            value: sliderValue,
                            duration: duration,
                            onSeek: (target) {
                              controller.audioHandler?.seek(target);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatPlayerDuration(duration),
                          style: TextStyle(color: Colors.grey[400], fontSize: 10),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }

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
                child: WebTrackTransition(
                  trackKey: mediaItem.id,
                  child: Row(
                    key: ValueKey('track-info-${mediaItem.id}'),
                    children: [
                      // Artwork — tap to open full-screen, hover for preview.
                      _WebHoverArtwork(
                        mediaItem: mediaItem,
                        size: 52,
                        onTap: onArtworkTap,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText,
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
                              // Mini "now playing" visualizer reacts to playback state.
                              StreamBuilder<bool>(
                                stream: controller.audioHandler?.playbackState
                                    .map((s) => s.playing)
                                    .distinct()
                                    .cast<bool>(),
                                builder: (context, snap) {
                                  final playing = snap.data ?? false;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: WebPseudoVisualizer(
                                      color: WebColorExtractor.cachedOrFallback(mediaItem.id),
                                      width: 16,
                                      height: 12,
                                      barCount: 4,
                                      playing: playing,
                                    ),
                                  );
                                },
                              ),
                              Flexible(
                                child: Text(
                                  artistText,
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
                              // Radio badge — uses RadioService interface so the
                              // player has no dependency on the concrete impl
                              // (which lives in neom_audio_platform).
                              if (Sint.isRegistered<RadioService>() && Sint.find<RadioService>().currentStation != null) ...[
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
                              // Jam Session badge — uses JamSessionService
                              // interface (impl lives in neom_audio_platform).
                              if (Sint.isRegistered<JamSessionService>() && Sint.find<JamSessionService>().isInSession) ...[
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
                              .distinct()
                              .cast<bool>(),
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
                                    ? Padding(
                                        padding: const EdgeInsets.all(9),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.85, end: 1.0),
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeInOut,
                                          builder: (_, value, child) =>
                                              Opacity(opacity: value, child: child),
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 1.8,
                                            color: Colors.black,
                                          ),
                                        ),
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
                              .distinct()
                              .cast<AudioServiceRepeatMode>(),
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
                        final sliderValue = computeSliderValue(position, duration);

                        return ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isCompact ? 300 : 500),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Text(
                                  formatPlayerDuration(position),
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _HoverSeekSlider(
                                  value: sliderValue,
                                  duration: duration,
                                  onSeek: (target) {
                                    controller.audioHandler?.seek(target);
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  formatPlayerDuration(duration),
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
                  width: 350,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Playback speed
                      _WebSpeedButton(controller: controller),
                      const SizedBox(width: 4),
                      // Crossfade
                      const _WebCrossfadeButton(),
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
                      const SizedBox(width: 8),
                      _WebControlButton(
                        icon: Icons.close_fullscreen_rounded,
                        size: 18,
                        color: Colors.white70,
                        tooltip: 'Minimize player to the right',
                        onTap: () {
                          controller.isWebPlayerRetracted.value = true;
                          controller.update(['web_bottom_player']);
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

}

/// Artwork thumbnail with hover-to-preview overlay and palette extraction.
///
/// On hover, an [OverlayEntry] anchored above the thumbnail shows a 140×140
/// preview of the same artwork. Tapping the thumbnail triggers [onTap]
/// (typically opening the full-screen now playing view).
class _WebHoverArtwork extends StatefulWidget {
  final MediaItem mediaItem;
  final double size;
  final VoidCallback? onTap;

  const _WebHoverArtwork({
    required this.mediaItem,
    required this.size,
    this.onTap,
  });

  @override
  State<_WebHoverArtwork> createState() => _WebHoverArtworkState();
}

class _WebHoverArtworkState extends State<_WebHoverArtwork> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _previewEntry;

  @override
  void initState() {
    super.initState();
    _scheduleExtraction();
  }

  @override
  void didUpdateWidget(covariant _WebHoverArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaItem.id != widget.mediaItem.id) {
      _removePreview();
      _scheduleExtraction();
    }
  }

  @override
  void dispose() {
    _removePreview();
    super.dispose();
  }

  void _scheduleExtraction() {
    final url = widget.mediaItem.artUri?.toString();
    if (url == null || url.isEmpty) return;
    // Fire and forget — caches the dominant color for the rest of the UI.
    WebColorExtractor.extract(cacheKey: widget.mediaItem.id, imageUrl: url);
  }

  void _showPreview() {
    if (_previewEntry != null) return;
    final url = widget.mediaItem.artUri?.toString();
    if (url == null || url.isEmpty) return;

    _previewEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: 140,
        height: 140,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          // Anchor above the thumbnail with a small gap.
          offset: const Offset(-44, -150),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: WebImageResolver.build(
                imageUrl: url,
                cacheKey: widget.mediaItem.id,
                width: 140,
                height: 140,
                borderRadius: 8,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_previewEntry!);
  }

  void _removePreview() {
    _previewEntry?.remove();
    _previewEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _showPreview(),
        onExit: (_) => _removePreview(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: WebImageResolver.build(
            imageUrl: widget.mediaItem.artUri?.toString(),
            cacheKey: widget.mediaItem.id,
            width: widget.size,
            height: widget.size,
          ),
        ),
      ),
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

/// Crossfade duration popup. Lazily registers [EnhancedPlaybackController]
/// the first time the button mounts so the rest of the app does not need to
/// wire it up explicitly.
class _WebCrossfadeButton extends StatefulWidget {
  const _WebCrossfadeButton();

  @override
  State<_WebCrossfadeButton> createState() => _WebCrossfadeButtonState();
}

class _WebCrossfadeButtonState extends State<_WebCrossfadeButton> {
  EnhancedPlaybackController? _enhanced;

  @override
  void initState() {
    super.initState();
    if (!Sint.isRegistered<EnhancedPlaybackController>()) {
      try {
        Bind.put<EnhancedPlaybackController>(
          EnhancedPlaybackController(),
          permanent: true,
        );
      } catch (_) {
        // Swallow: button hides itself below if registration failed.
      }
    }
    if (Sint.isRegistered<EnhancedPlaybackController>()) {
      _enhanced = Sint.find<EnhancedPlaybackController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enhanced = _enhanced;
    if (enhanced == null) return const SizedBox.shrink();

    return PopupMenuButton<CrossfadeMode>(
      tooltip: 'Crossfade',
      icon: Icon(
        Icons.compare_arrows_rounded,
        color: enhanced.isCrossfadeEnabled ? Colors.white : Colors.white70,
        size: 20,
      ),
      color: AppColor.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (mode) async {
        await enhanced.setCrossfadeMode(mode);
        if (mounted) setState(() {});
      },
      itemBuilder: (_) => CrossfadeMode.values
          .where((m) => m != CrossfadeMode.custom)
          .map((mode) {
        final isActive = enhanced.crossfadeMode == mode;
        final label = mode == CrossfadeMode.off
            ? mode.displayName
            : '${mode.displayName} (${mode.duration.inSeconds}s)';
        return PopupMenuItem<CrossfadeMode>(
          value: mode,
          height: 36,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.check_rounded : Icons.compare_arrows_rounded,
                color: isActive ? AppColor.getMain() : Colors.white54,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
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

/// A seek slider that shows the thumb only on hover (web-friendly) and uses
/// a **drag-and-release** pattern: while the user is dragging, the slider is
/// driven by a local pending value and the upstream `positionStream` is
/// ignored, so the thumb does not snap back. `onSeek` is called exactly once
/// per gesture, on `onChangeEnd`.
class _HoverSeekSlider extends StatefulWidget {
  final double value;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _HoverSeekSlider({
    required this.value,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<_HoverSeekSlider> createState() => _HoverSeekSliderState();
}

class _HoverSeekSliderState extends State<_HoverSeekSlider> {
  bool _hovered = false;
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = (_dragValue ?? widget.value).clamp(0.0, 1.0);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: _hovered ? 5 : 3,
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: _hovered || _dragValue != null ? 6 : 0,
          ),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          activeTrackColor: _hovered ? AppColor.getMain() : Colors.white,
          inactiveTrackColor: Colors.white24,
          thumbColor: Colors.white,
        ),
        child: Slider(
          value: effectiveValue,
          onChangeStart: (v) => setState(() => _dragValue = v),
          onChanged: (v) => setState(() => _dragValue = v),
          onChangeEnd: (v) {
            final target = sliderValueToPosition(v, widget.duration);
            widget.onSeek(target);
            // Clear pending so the next position tick from the stream takes
            // over again.
            setState(() => _dragValue = null);
          },
        ),
      ),
    );
  }
}
