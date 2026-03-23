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

        final ownerId = mediaItem.extras?['ownerId']?.toString();
        _fetchArtistProfile(ownerId);
        
        final duration = controller.audioHandler?.player.duration ?? mediaItem.duration ?? Duration.zero;
        final year = mediaItem.extras?['publishedYear'] ?? mediaItem.extras?['releaseDate']?.toString().split('-').first ?? '';

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header Section (Spotify Style) ───
                Container(
                  padding: const EdgeInsets.only(left: 32, right: 32, top: 48, bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColor.getMain().withOpacity(0.5), // Using main brand color as gradient base
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Large Artwork
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 232,
                            height: 232,
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
                      const SizedBox(width: 24),
                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Canción',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Huge Title
                            Text(
                              mediaItem.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 64, // Massive font size
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: -1.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            // Artist & Meta
                            Row(
                              children: [
                                if (_artistPhotoUrl != null && _artistPhotoUrl!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: platformCircleAvatar(
                                      imageUrl: _artistPhotoUrl!,
                                      radius: 12,
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    '${_artistName ?? mediaItem.artist ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (mediaItem.album != null && mediaItem.album!.isNotEmpty)
                                  Text(
                                    ' • ${mediaItem.album}',
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                if (year.toString().isNotEmpty)
                                  Text(
                                    ' • $year',
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                Text(
                                  ' • ${_formatDuration(duration)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Actions Bar ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    children: [
                      // Play/Pause Button (Giant Green/Main Color)
                      StreamBuilder<PlaybackState>(
                        stream: controller.audioHandler?.playbackState,
                        builder: (_, snap) {
                          final playing = snap.data?.playing ?? false;
                          return Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColor.getMain(),
                              shape: BoxShape.circle,
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => playing
                                  ? controller.audioHandler?.pause()
                                  : controller.audioHandler?.play(),
                              child: Icon(
                                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.black, // Dark icon on bright background
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 24),
                      // Add / Like
                      _FullScreenLikeButton(mediaItem: mediaItem),
                      const SizedBox(width: 16),
                      // Download (Offline)
                      Icon(Icons.download_for_offline_outlined, color: Colors.white54, size: 32),
                      const SizedBox(width: 16),
                      // More (Three dots)
                      Icon(Icons.more_horiz_rounded, color: Colors.white54, size: 32),
                    ],
                  ),
                ),

                // ─── Body Content (Lyrics & Artist Profile) ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lyrics Section
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Letras',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              // Using existing lyrics panel but removing its internal background/constraints if needed
                              width: double.infinity,
                              child: WebLyricsPanel(mediaItem: mediaItem),
                            ),
                          ],
                        ),
                      ),
                      // Artist Info Section
                      if (_artistPhotoUrl != null && _artistName != null)
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              if (_artistId != null && _artistId!.isNotEmpty) {
                                Sint.toNamed(
                                  AppRouteConstants.profileDetails
                                      .replaceFirst(':profileId', _artistId!),
                                );
                              }
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    platformCircleAvatar(
                                      imageUrl: _artistPhotoUrl!,
                                      radius: 40,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Artista',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _artistName!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 48), // Bottom padding
              ],
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
