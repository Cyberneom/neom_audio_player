import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:sint/sint.dart';

import '../../../data/implementations/playlist_hive_controller.dart';
import '../../../neom_audio_handler.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/mappers/media_item_mapper.dart';
import '../../player/miniplayer_controller.dart';
import 'web_lyrics_panel.dart';

/// Full-screen Now Playing overlay for web (Spotify-style).
class WebNowPlayingFull extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onToggleQueue;

  const WebNowPlayingFull({
    Key? key,
    required this.onClose,
    this.onToggleQueue,
  }) : super(key: key);

  @override
  State<WebNowPlayingFull> createState() => _WebNowPlayingFullState();
}

class _WebNowPlayingFullState extends State<WebNowPlayingFull> {
  bool _showLyrics = false;

  /// Artist profile state
  String? _artistPhotoUrl;
  String? _artistName;
  String? _artistId;
  String? _currentOwnerId;

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  /// Fetches artist profile image and name from Firestore via ownerId.
  Future<void> _fetchArtistProfile(String? ownerId) async {
    if (ownerId == null || ownerId.isEmpty || ownerId == _currentOwnerId) return;
    _currentOwnerId = ownerId;
    try {
      final profile = await ProfileFirestore().retrieveSimple(ownerId);
      if (profile != null && mounted) {
        setState(() {
          _artistPhotoUrl = profile.photoUrl.isNotEmpty ? profile.photoUrl : null;
          _artistName = profile.name.isNotEmpty ? profile.name : null;
          _artistId = profile.id;
        });
      } else if (mounted) {
        setState(() {
          _artistPhotoUrl = null;
          _artistName = null;
          _artistId = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _artistPhotoUrl = null;
          _artistName = null;
          _artistId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SintBuilder<MiniPlayerController>(
      id: 'web_now_playing_full',
      builder: (controller) {
        final mediaItem = controller.mediaItem.value;
        if (mediaItem == null) {
          widget.onClose();
          return const SizedBox.shrink();
        }

        // Fetch artist profile when song changes
        final ownerId = mediaItem.extras?['ownerId']?.toString();
        _fetchArtistProfile(ownerId);

        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColor.surfaceBright,
                  AppColor.surfaceElevated,
                  AppColor.scaffold,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ─── Top bar ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: widget.onClose,
                            child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                          ),
                        ),
                        Text(
                          AudioPlayerTranslationConstants.nowPlaying.tr.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Row(
                          children: [
                            // Lyrics toggle
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => setState(() => _showLyrics = !_showLyrics),
                                child: Icon(
                                  Icons.lyrics_outlined,
                                  color: _showLyrics ? AppColor.getMain() : Colors.white54,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Queue toggle
                            if (widget.onToggleQueue != null)
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: widget.onToggleQueue,
                                  child: const Icon(Icons.queue_music_rounded, color: Colors.white54, size: 22),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ─── Main content ───
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Artwork
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: (mediaItem.artUri != null && mediaItem.artUri.toString().isNotEmpty)
                                      ? platformNetworkImage(
                                          imageUrl: mediaItem.artUri.toString(),
                                          fit: BoxFit.cover,
                                          errorWidget: _artworkPlaceholder(),
                                        )
                                      : _artworkPlaceholder(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Lyrics panel (right side)
                        if (_showLyrics)
                          SizedBox(
                            width: 400,
                            child: WebLyricsPanel(mediaItem: mediaItem),
                          ),
                      ],
                    ),
                  ),

                  // ─── Track info + Artist ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mediaItem.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Artist row with profile image (Spotify-style)
                              if (_artistPhotoUrl != null && _artistName != null)
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_artistId != null && _artistId!.isNotEmpty) {
                                        Sint.toNamed(
                                          AppRouteConstants.profileDetails
                                              .replaceFirst(':profileId', _artistId!),
                                        );
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        platformCircleAvatar(
                                          imageUrl: _artistPhotoUrl!,
                                          radius: 14,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _artistName!,
                                            style: TextStyle(
                                              color: Colors.grey[300],
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  mediaItem.artist ?? '',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        _FullScreenLikeButton(mediaItem: mediaItem),
                      ],
                    ),
                  ),

                  // ─── Seek bar ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: StreamBuilder<Duration>(
                      stream: controller.audioHandler?.player.positionStream,
                      builder: (context, positionSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;
                        final duration = controller.audioHandler?.player.duration ?? Duration.zero;

                        double sliderValue = 0.0;
                        if (duration.inMilliseconds > 0) {
                          sliderValue = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
                        }

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: sliderValue,
                                onChanged: (v) {
                                  final newPosition = Duration(
                                    milliseconds: (v * duration.inMilliseconds).round(),
                                  );
                                  controller.audioHandler?.seek(newPosition);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // ─── Transport controls ───
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32, top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Shuffle
                        StreamBuilder<bool>(
                          stream: controller.audioHandler?.playbackState
                              .map((s) => s.shuffleMode == AudioServiceShuffleMode.all)
                              .distinct(),
                          builder: (_, snap) {
                            final on = snap.data ?? false;
                            return _FullControlButton(
                              icon: Icons.shuffle_rounded,
                              size: 24,
                              color: on ? Colors.white : Colors.white38,
                              onTap: () {
                                AuthGuard.protect(context, () {
                                  controller.audioHandler?.setShuffleMode(
                                    on ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
                                  );
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                        // Previous
                        _FullControlButton(
                          icon: Icons.skip_previous_rounded,
                          size: 36,
                          onTap: () => controller.audioHandler?.skipToPrevious(),
                        ),
                        const SizedBox(width: 16),
                        // Play/Pause
                        StreamBuilder<PlaybackState>(
                          stream: controller.audioHandler?.playbackState,
                          builder: (_, snap) {
                            final playing = snap.data?.playing ?? false;
                            return Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => playing
                                    ? controller.audioHandler?.pause()
                                    : controller.audioHandler?.play(),
                                child: Icon(
                                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        // Next
                        _FullControlButton(
                          icon: Icons.skip_next_rounded,
                          size: 36,
                          onTap: () => controller.audioHandler?.skipToNext(),
                        ),
                        const SizedBox(width: 24),
                        // Repeat
                        StreamBuilder<AudioServiceRepeatMode>(
                          stream: controller.audioHandler?.playbackState
                              .map((s) => s.repeatMode)
                              .distinct(),
                          builder: (_, snap) {
                            final mode = snap.data ?? AudioServiceRepeatMode.none;
                            final active = mode != AudioServiceRepeatMode.none;
                            final isOne = mode == AudioServiceRepeatMode.one;
                            return _FullControlButton(
                              icon: isOne ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                              size: 24,
                              color: active ? Colors.white : Colors.white38,
                              onTap: () {
                                AuthGuard.protect(context, () {
                                  const modes = [
                                    AudioServiceRepeatMode.none,
                                    AudioServiceRepeatMode.all,
                                    AudioServiceRepeatMode.one,
                                  ];
                                  const texts = ['None', 'All', 'One'];
                                  final idx = modes.indexOf(mode);
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _artworkPlaceholder() {
    return Container(
      color: AppColor.getMain().withOpacity(0.3),
      child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 80),
    );
  }
}

class _FullControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback? onTap;

  const _FullControlButton({
    required this.icon,
    required this.size,
    this.color = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }
}

class _FullScreenLikeButton extends StatefulWidget {
  final MediaItem mediaItem;
  const _FullScreenLikeButton({required this.mediaItem});

  @override
  State<_FullScreenLikeButton> createState() => _FullScreenLikeButtonState();
}

class _FullScreenLikeButtonState extends State<_FullScreenLikeButton> {
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkLiked();
  }

  @override
  void didUpdateWidget(covariant _FullScreenLikeButton oldWidget) {
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _toggleLike,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _isLiked ? AppColor.getMain() : Colors.white54,
            size: 28,
          ),
        ),
      ),
    );
  }
}
