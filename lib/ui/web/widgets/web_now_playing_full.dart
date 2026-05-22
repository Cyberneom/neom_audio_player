import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:sint/sint.dart';

import '../../../data/implementations/playlist_hive_controller.dart';
import '../../player/miniplayer_controller.dart';
import '../utils/web_color_extractor.dart';
import '../utils/web_image_resolver.dart';
import 'web_lyrics_panel.dart';
import 'web_pseudo_visualizer.dart';

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
  /// Canvas mode = artwork zooms in slowly (Ken Burns) and ambient gradient
  /// dominates the screen.
  bool _canvasMode = false;

  /// Currently extracted dominant color (cached by WebColorExtractor).
  Color _ambientColor = Colors.transparent;
  String? _ambientColorKey;

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

  /// Triggers async palette extraction for [mediaItem]; rebuilds with the
  /// resolved color when ready. Cached so repeated tracks are free.
  void _ensureAmbientColor(MediaItem mediaItem) {
    if (_ambientColorKey == mediaItem.id) return;
    _ambientColorKey = mediaItem.id;
    _ambientColor = WebColorExtractor.cachedOrFallback(mediaItem.id);
    final url = mediaItem.artUri?.toString();
    if (url == null || url.isEmpty) return;
    WebColorExtractor.extract(cacheKey: mediaItem.id, imageUrl: url)
        .then((color) {
      if (mounted && _ambientColorKey == mediaItem.id) {
        setState(() => _ambientColor = color);
      }
    });
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

        _ensureAmbientColor(mediaItem);
        final ownerId = mediaItem.extras?['ownerId']?.toString();
        _fetchArtistProfile(ownerId);
        
        final duration = controller.audioHandler?.player.duration ?? mediaItem.duration ?? Duration.zero;
        final year = mediaItem.extras?['publishedYear'] ?? mediaItem.extras?['releaseDate']?.toString().split('-').first ?? '';

        return Material(
          color: const Color(0xFF0B1424),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.6),
                radius: 1.4,
                colors: [
                  _ambientColor.withValues(alpha: 0.55),
                  _ambientColor.withValues(alpha: 0.18),
                  const Color(0xFF0B1424),
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
            child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header Section (Spotify Style) ───
                    Container(
                  padding: const EdgeInsets.only(left: 32, right: 32, top: 72, bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _ambientColor.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Large Artwork — Canvas mode applies a slow Ken Burns zoom.
                      _CanvasArtwork(
                        mediaItem: mediaItem,
                        canvasMode: _canvasMode,
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
                      // Pseudo visualizer reacting to playback state
                      StreamBuilder<bool>(
                        stream: controller.audioHandler?.playbackState
                            .map((s) => s.playing)
                            .distinct(),
                        builder: (_, snap) {
                          final playing = snap.data ?? false;
                          return WebPseudoVisualizer(
                            color: _ambientColor == Colors.transparent
                                ? AppColor.getMain()
                                : _ambientColor,
                            barCount: 12,
                            width: 96,
                            height: 36,
                            playing: playing,
                          );
                        },
                      ),
                      const Spacer(),
                      // Canvas mode toggle (Ken Burns + bigger artwork)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(() => _canvasMode = !_canvasMode),
                          child: Tooltip(
                            message: 'Canvas',
                            waitDuration: const Duration(milliseconds: 500),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                _canvasMode
                                    ? Icons.fit_screen_rounded
                                    : Icons.aspect_ratio_rounded,
                                color: _canvasMode
                                    ? (_ambientColor == Colors.transparent
                                        ? AppColor.getMain()
                                        : _ambientColor)
                                    : Colors.white54,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // More (Three dots)
                      const Icon(Icons.more_horiz_rounded, color: Colors.white54, size: 32),
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
              // Close button (top-right) — restores ability to dismiss the overlay
              Positioned(
                top: 16,
                right: 16,
                child: Material(
                  color: Colors.black.withOpacity(0.45),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    onPressed: widget.onClose,
                    tooltip: 'Cerrar',
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

}

/// Large artwork wrapper. Applies a slow scale animation when [canvasMode]
/// is enabled (Ken Burns effect) and otherwise renders a static thumbnail.
class _CanvasArtwork extends StatefulWidget {
  final MediaItem mediaItem;
  final bool canvasMode;

  const _CanvasArtwork({
    required this.mediaItem,
    required this.canvasMode,
  });

  @override
  State<_CanvasArtwork> createState() => _CanvasArtworkState();
}

class _CanvasArtworkState extends State<_CanvasArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (widget.canvasMode) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _CanvasArtwork old) {
    super.didUpdateWidget(old);
    if (widget.canvasMode != old.canvasMode) {
      if (widget.canvasMode) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: widget.canvasMode ? 320 : 232,
      height: widget.canvasMode ? 320 : 232,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            final scale = widget.canvasMode ? 1.0 + _controller.value * 0.12 : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: WebImageResolver.build(
            imageUrl: widget.mediaItem.artUri?.toString(),
            cacheKey: widget.mediaItem.id,
            width: widget.canvasMode ? 320 : 232,
            height: widget.canvasMode ? 320 : 232,
            borderRadius: 6,
          ),
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
