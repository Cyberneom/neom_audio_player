import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/validator.dart';
import 'package:sint/sint.dart';

import '../../../data/implementations/playlist_hive_controller.dart';
import '../../player/miniplayer_controller.dart';
import '../utils/web_color_extractor.dart';
import '../utils/web_image_resolver.dart';
import '../utils/web_player_helpers.dart';
import 'web_lyrics_panel.dart';
import 'web_pseudo_visualizer.dart';

/// Full-screen Now Playing overlay for web.
///
/// * **Standard Mode (`_canvasMode == false`):** Balanced 2-column layout with
///   Album Player on the left and interactive Lyrics Panel on the right.
/// * **Canvas / Arte en Vivo Mode (`_canvasMode == true`):** Pure cinematic,
///   deep-dark centered layout with large Hero Cover, Ken Burns breathing motion,
///   ambient halo glow, and full audio visualizer.
class WebNowPlayingFull extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onToggleQueue;

  const WebNowPlayingFull({
    super.key,
    required this.onClose,
    this.onToggleQueue,
  });

  @override
  State<WebNowPlayingFull> createState() => _WebNowPlayingFullState();
}

class _WebNowPlayingFullState extends State<WebNowPlayingFull> {
  /// Canvas mode = true switches to centered Hero Artwork + deep dark live visualizer.
  /// Standard mode = false shows the 2-column view with lyrics.
  bool _canvasMode = false;

  /// Currently extracted dominant color (cached by WebColorExtractor).
  Color _ambientColor = Colors.transparent;
  String? _ambientColorKey;

  /// Artist profile state
  String? _artistPhotoUrl;
  String? _artistName;
  String? _artistId;
  String? _currentOwnerId;

  /// Navigates to the artist profile (or current user profile if ownerId matches).
  Future<void> _navigateToArtist(String? ownerId) async {
    String targetId = _artistId ?? ownerId ?? '';
    if (targetId.isEmpty) {
      AppUtilities.showSnackBar(
        message: CommonTranslationConstants.noItemOwnerFound.tr,
      );
      return;
    }

    widget.onClose();
    try {
      if (Validator.isEmail(targetId)) {
        final user = await UserFirestore().getByEmail(targetId);
        if (user != null) {
          final profiles = await ProfileFirestore().retrieveByUserId(user.id);
          if (profiles.isNotEmpty) targetId = profiles.first.id;
        }
      }

      final canPersist = AppConfig.instance.canPersistUserActivity;
      final currentUserId = canPersist
          ? PlaylistHiveController().userServiceImpl.profile.id
          : '';
      if (canPersist && targetId == currentUserId) {
        Sint.toNamed(AppRouteConstants.profile);
      } else if (targetId.length > 5) {
        Sint.toNamed(AppRouteConstants.matePath(targetId), arguments: targetId);
      } else {
        AppUtilities.showSnackBar(
          message: CommonTranslationConstants.noItemOwnerFound.tr,
        );
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'WebNowPlayingFull._navigateToArtist',
      );
    }
  }

  /// Navigates to the album in playlist format (AppRouteConstants.listItems).
  Future<void> _navigateToAlbum(MediaItem mediaItem) async {
    final albumId =
        mediaItem.extras?['metaId']?.toString() ??
        mediaItem.extras?['albumId']?.toString() ??
        mediaItem.extras?['releaseId']?.toString() ??
        mediaItem.extras?['itemlistId']?.toString() ??
        '';
    final albumName = mediaItem.album?.trim() ?? '';

    widget.onClose();

    Itemlist? matchedList;
    try {
      // 1. Check in-memory releaseItemlists
      if (albumId.isNotEmpty &&
          AppConfig.instance.releaseItemlists.containsKey(albumId)) {
        matchedList = AppConfig.instance.releaseItemlists[albumId];
      }
      if (matchedList == null && albumName.isNotEmpty) {
        for (Itemlist list in AppConfig.instance.releaseItemlists.values) {
          if ((albumId.isNotEmpty && list.id == albumId) ||
              (list.name.toLowerCase() == albumName.toLowerCase()) ||
              (list.appReleaseItems?.any(
                    (r) =>
                        r.id == mediaItem.id ||
                        r.name.toLowerCase() == mediaItem.title.toLowerCase(),
                  ) ==
                  true) ||
              (list.appMediaItems?.any((m) => m.id == mediaItem.id) == true)) {
            matchedList = list;
            break;
          }
        }
      }
      // 2. Check in-memory personal playlists
      if (matchedList == null && AppConfig.instance.canPersistUserActivity) {
        final userLists =
            PlaylistHiveController()
                .userServiceImpl
                .profile
                .itemlists
                ?.values ??
            [];
        for (Itemlist list in userLists) {
          if ((albumId.isNotEmpty && list.id == albumId) ||
              (albumName.isNotEmpty &&
                  list.name.toLowerCase() == albumName.toLowerCase()) ||
              (list.appReleaseItems?.any((r) => r.id == mediaItem.id) ==
                  true) ||
              (list.appMediaItems?.any((m) => m.id == mediaItem.id) == true)) {
            matchedList = list;
            break;
          }
        }
      }
    } catch (_) {}

    // If matchedList was found and has items loaded, navigate directly
    if (matchedList != null &&
        (matchedList.appReleaseItems?.isNotEmpty == true ||
            matchedList.appMediaItems?.isNotEmpty == true)) {
      matchedList.isModifiable = false;
      Sint.toNamed(
        AppRouteConstants.listItems,
        arguments: [matchedList, true, false],
      );
      return;
    }

    // 3. Query Firestore for album/metaId items
    try {
      // A. Try ItemlistFirestore if albumId exists
      if (albumId.isNotEmpty) {
        final fetchedList = await ItemlistFirestore().retrieve(albumId);
        if (fetchedList.id.isNotEmpty &&
            (fetchedList.appReleaseItems?.isNotEmpty == true ||
                fetchedList.appMediaItems?.isNotEmpty == true)) {
          fetchedList.isModifiable = false;
          Sint.toNamed(
            AppRouteConstants.listItems,
            arguments: [fetchedList, true, false],
          );
          return;
        }
      }

      // B. Query appReleaseItems collection by metaId or metaName
      Query query = FirebaseFirestore.instance.collection(
        AppFirestoreCollectionConstants.appReleaseItems,
      );
      if (albumId.isNotEmpty) {
        query = query.where('metaId', isEqualTo: albumId);
      } else if (albumName.isNotEmpty) {
        query = query.where('metaName', isEqualTo: albumName);
      }

      final querySnap = await query.get();
      if (querySnap.docs.isNotEmpty) {
        final releaseItems = querySnap.docs.map((doc) {
          final rel = AppReleaseItem.fromJSON(
            doc.data() as Map<String, dynamic>,
          );
          rel.id = doc.id;
          return rel;
        }).toList();

        final albumItemList = Itemlist(
          id: albumId.isNotEmpty
              ? albumId
              : (albumName.isNotEmpty ? albumName : 'album_${mediaItem.id}'),
          name: albumName.isNotEmpty
              ? albumName
              : (releaseItems.first.metaName ?? mediaItem.title),
          description: mediaItem.extras?['description']?.toString() ?? '',
          ownerId:
              mediaItem.extras?['ownerId']?.toString() ??
              releaseItems.first.ownerEmail,
          ownerName: mediaItem.artist ?? releaseItems.first.ownerName,
          imgUrl: mediaItem.artUri?.toString() ?? releaseItems.first.imgUrl,
          appReleaseItems: releaseItems,
          type: ItemlistType.album,
          isModifiable: false,
          public: true,
        );

        Sint.toNamed(
          AppRouteConstants.listItems,
          arguments: [albumItemList, true, false],
        );
        return;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'WebNowPlayingFull._navigateToAlbum',
      );
    }

    // 4. Fallback: Build album playlist with current track
    final fallbackItem = AppReleaseItem(
      id: mediaItem.id,
      name: mediaItem.title,
      ownerName: mediaItem.artist ?? '',
      ownerEmail: mediaItem.extras?['ownerEmail']?.toString() ?? '',
      ownerProfileId: mediaItem.extras?['ownerId']?.toString() ?? '',
      metaId: albumId,
      metaName: albumName.isNotEmpty ? albumName : mediaItem.title,
      imgUrl: mediaItem.artUri?.toString() ?? '',
      previewUrl: mediaItem.extras?['url']?.toString() ?? '',
      duration: mediaItem.duration?.inSeconds ?? 0,
      lyrics: mediaItem.extras?['lyrics']?.toString() ?? '',
    );

    final singleAlbumList = Itemlist(
      id: albumId.isNotEmpty
          ? albumId
          : (albumName.isNotEmpty ? albumName : 'album_${mediaItem.id}'),
      name: albumName.isNotEmpty ? albumName : mediaItem.title,
      ownerName: mediaItem.artist ?? '',
      ownerId: mediaItem.extras?['ownerId']?.toString() ?? '',
      imgUrl: mediaItem.artUri?.toString() ?? '',
      appReleaseItems: [fallbackItem],
      type: ItemlistType.album,
      isModifiable: false,
      public: true,
    );

    Sint.toNamed(
      AppRouteConstants.listItems,
      arguments: [singleAlbumList, true, false],
    );
  }

  /// Fetches artist profile image and name from Firestore via ownerId with race-condition guard.
  Future<void> _fetchArtistProfile(String? ownerId) async {
    if (ownerId == null || ownerId.isEmpty || ownerId == _currentOwnerId)
      return;
    _currentOwnerId = ownerId;
    try {
      String targetId = ownerId;
      if (Validator.isEmail(ownerId)) {
        final user = await UserFirestore().getByEmail(ownerId);
        if (user != null) {
          final profiles = await ProfileFirestore().retrieveByUserId(user.id);
          if (profiles.isNotEmpty) targetId = profiles.first.id;
        }
      }

      final profile = await ProfileFirestore().retrieveSimple(targetId);
      if (profile != null && mounted && _currentOwnerId == ownerId) {
        setState(() {
          _artistPhotoUrl = profile.photoUrl.isNotEmpty
              ? profile.photoUrl
              : null;
          _artistName = profile.name.isNotEmpty ? profile.name : null;
          _artistId = profile.id;
        });
      } else if (mounted && _currentOwnerId == ownerId) {
        setState(() {
          _artistPhotoUrl = null;
          _artistName = null;
          _artistId = null;
        });
      }
    } catch (_) {
      if (mounted && _currentOwnerId == ownerId) {
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
    WebColorExtractor.extract(cacheKey: mediaItem.id, imageUrl: url).then((
      color,
    ) {
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
        final mediaItem = controller.visibleMediaItem;
        if (mediaItem == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onClose();
          });
          return const SizedBox.shrink();
        }

        _ensureAmbientColor(mediaItem);
        final ownerId = mediaItem.extras?['ownerId']?.toString();
        _fetchArtistProfile(ownerId);

        final rawYear =
            mediaItem.extras?['publishedYear']?.toString() ??
            mediaItem.extras?['releaseDate']?.toString().split('-').first ??
            '';
        final year = (rawYear == '0' || rawYear == 'null') ? '' : rawYear;

        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 920;

        return Material(
          color: _canvasMode
              ? const Color(0xFF030509)
              : const Color(0xFF070D18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ─── Layer 1: Ambient Background Glow ───
              _AmbientLiveCanvasBackground(
                imageUrl: mediaItem.artUri?.toString(),
                canvasMode: _canvasMode,
                ambientColor: _ambientColor,
              ),

              // ─── Layer 2: Main Content Container ───
              SafeArea(
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    constraints: BoxConstraints(
                      maxWidth: (_canvasMode || !isDesktop) ? 680 : 1260,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: _canvasMode
                        ? _buildCenteredCanvasView(
                            controller,
                            mediaItem,
                            ownerId,
                            year,
                          )
                        : (isDesktop
                              ? _buildDesktopTwoColumn(
                                  controller,
                                  mediaItem,
                                  ownerId,
                                  year,
                                )
                              : _buildMobileSingleColumn(
                                  controller,
                                  mediaItem,
                                  ownerId,
                                  year,
                                )),
                  ),
                ),
              ),

              // ─── Layer 3: Top Close Button ───
              Positioned(
                top: 24,
                right: 24,
                child: SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: 'Cerrar vista completa (ESC)',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ─── Standard 2-Column Desktop View (Player on Left + Lyrics on Right) ───
  Widget _buildDesktopTwoColumn(
    MiniPlayerController controller,
    MediaItem mediaItem,
    String? ownerId,
    String year,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Player & Artwork (~300px)
        Expanded(
          flex: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Tooltip(
                message: 'Reproducir álbum completo',
                waitDuration: const Duration(milliseconds: 400),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _navigateToAlbum(mediaItem),
                    child: _CanvasArtwork(
                      mediaItem: mediaItem,
                      canvasMode: false,
                      ambientColor: _ambientColor,
                      size: 300.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Song Title
              Text(
                mediaItem.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Artist & Album Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_artistPhotoUrl != null && _artistPhotoUrl!.isNotEmpty)
                    Tooltip(
                      message: 'Ver perfil del artista',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _navigateToArtist(ownerId),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: platformCircleAvatar(
                              imageUrl: _artistPhotoUrl!,
                              radius: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Flexible(
                    child: _WebHoverLinkText(
                      text: _artistName ?? mediaItem.artist ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      tooltip: 'Ver perfil del artista',
                      onTap: () => _navigateToArtist(ownerId),
                    ),
                  ),
                  if (mediaItem.album != null &&
                      mediaItem.album!.isNotEmpty) ...[
                    const Text(
                      ' • ',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    Flexible(
                      child: _WebHoverLinkText(
                        text: mediaItem.album!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        tooltip: 'Reproducir álbum completo',
                        onTap: () => _navigateToAlbum(mediaItem),
                      ),
                    ),
                  ],
                  if (year.isNotEmpty)
                    Text(
                      ' • $year',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 18),

              // Scrubber
              _NowPlayingSeekSection(
                controller: controller,
                ambientColor: _ambientColor,
              ),

              const SizedBox(height: 14),

              // Controls Bar (Scales down gracefully if horizontal width is constrained)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FullScreenLikeButton(mediaItem: mediaItem),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      tooltip: 'Canción anterior',
                      onPressed: () =>
                          controller.audioHandler?.skipToPrevious(),
                    ),
                    const SizedBox(width: 8),
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
                            boxShadow: [
                              BoxShadow(
                                color: AppColor.getMain().withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 32,
                            ),
                            onPressed: () => playing
                                ? controller.audioHandler?.pause()
                                : controller.audioHandler?.play(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      tooltip: 'Siguiente canción',
                      onPressed: () => controller.audioHandler?.skipToNext(),
                    ),
                    const SizedBox(width: 10),

                    // Button to activate Canvas / Arte en Vivo Mode
                    Tooltip(
                      message: 'Activar Modo Canvas / Arte Vivo',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                          onPressed: () => setState(() => _canvasMode = true),
                        ),
                      ),
                    ),

                    if (widget.onToggleQueue != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.queue_music_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                        tooltip: 'Cola de reproducción',
                        onPressed: widget.onToggleQueue,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 48),

        // Right Column: Lyrics Screen
        Expanded(
          flex: 6,
          child: SizedBox(
            height: 560,
            child: WebLyricsPanel(mediaItem: mediaItem),
          ),
        ),
      ],
    );
  }

  /// ─── Canvas Mode Centered View (Hero Artwork + Deep Dark Visualizer) ───
  Widget _buildCenteredCanvasView(
    MiniPlayerController controller,
    MediaItem mediaItem,
    String? ownerId,
    String year,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── Central Large Hero Artwork with Ken Burns Live Motion ───
          Tooltip(
            message: 'Reproducir álbum completo',
            waitDuration: const Duration(milliseconds: 400),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _navigateToAlbum(mediaItem),
                child: _CanvasArtwork(
                  mediaItem: mediaItem,
                  canvasMode: true,
                  ambientColor: _ambientColor,
                  size: 380.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ─── Track Title ───
          Text(
            mediaItem.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // ─── Artist & Album Meta ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_artistPhotoUrl != null && _artistPhotoUrl!.isNotEmpty)
                Tooltip(
                  message: 'Ver perfil del artista',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _navigateToArtist(ownerId),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: platformCircleAvatar(
                          imageUrl: _artistPhotoUrl!,
                          radius: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: _WebHoverLinkText(
                  text: _artistName ?? mediaItem.artist ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  tooltip: 'Ver perfil del artista',
                  onTap: () => _navigateToArtist(ownerId),
                ),
              ),
              if (mediaItem.album != null && mediaItem.album!.isNotEmpty) ...[
                const Text(
                  ' • ',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
                Flexible(
                  child: _WebHoverLinkText(
                    text: mediaItem.album!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    tooltip: 'Reproducir álbum completo',
                    onTap: () => _navigateToAlbum(mediaItem),
                  ),
                ),
              ],
              if (year.isNotEmpty)
                Text(
                  ' • $year',
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Centered Scrubber & Visualizer ───
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _NowPlayingSeekSection(
              controller: controller,
              ambientColor: _ambientColor,
              expandedVisualizer: true,
            ),
          ),

          const SizedBox(height: 16),

          // ─── Centered Controls Bar ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Like Button
              _FullScreenLikeButton(mediaItem: mediaItem),

              const SizedBox(width: 14),

              // Previous Track
              IconButton(
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                tooltip: 'Canción anterior',
                onPressed: () => controller.audioHandler?.skipToPrevious(),
              ),

              const SizedBox(width: 12),

              // Giant Play/Pause Central Button
              StreamBuilder<PlaybackState>(
                stream: controller.audioHandler?.playbackState,
                builder: (_, snap) {
                  final playing = snap.data?.playing ?? false;
                  return Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColor.getMain(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.getMain().withValues(alpha: 0.5),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 38,
                      ),
                      onPressed: () => playing
                          ? controller.audioHandler?.pause()
                          : controller.audioHandler?.play(),
                    ),
                  );
                },
              ),

              const SizedBox(width: 12),

              // Next Track
              IconButton(
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                tooltip: 'Siguiente canción',
                onPressed: () => controller.audioHandler?.skipToNext(),
              ),

              const SizedBox(width: 14),

              // Active Canvas Button (Click to return to standard lyrics view)
              Tooltip(
                message: 'Volver a vista con letras',
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColor.getMain().withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColor.getMain().withValues(alpha: 0.5),
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColor.getMain(),
                      size: 24,
                    ),
                    onPressed: () => setState(() => _canvasMode = false),
                  ),
                ),
              ),

              // Queue Drawer Toggle
              if (widget.onToggleQueue != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(
                    Icons.queue_music_rounded,
                    color: Colors.white54,
                    size: 24,
                  ),
                  tooltip: 'Cola de reproducción',
                  onPressed: widget.onToggleQueue,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Mobile / Tablet Layout (Single Column)
  Widget _buildMobileSingleColumn(
    MiniPlayerController controller,
    MediaItem mediaItem,
    String? ownerId,
    String year,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _CanvasArtwork(
            mediaItem: mediaItem,
            canvasMode: _canvasMode,
            ambientColor: _ambientColor,
            size: 280.0,
          ),
          const SizedBox(height: 20),
          Text(
            mediaItem.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          _WebHoverLinkText(
            text: _artistName ?? mediaItem.artist ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            onTap: () => _navigateToArtist(ownerId),
          ),
          const SizedBox(height: 18),
          _NowPlayingSeekSection(
            controller: controller,
            ambientColor: _ambientColor,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FullScreenLikeButton(mediaItem: mediaItem),
              IconButton(
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => controller.audioHandler?.skipToPrevious(),
              ),
              StreamBuilder<PlaybackState>(
                stream: controller.audioHandler?.playbackState,
                builder: (_, snap) {
                  final playing = snap.data?.playing ?? false;
                  return Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColor.getMain(),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 30,
                      ),
                      onPressed: () => playing
                          ? controller.audioHandler?.pause()
                          : controller.audioHandler?.play(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => controller.audioHandler?.skipToNext(),
              ),
              IconButton(
                icon: Icon(
                  _canvasMode
                      ? Icons.auto_awesome_rounded
                      : Icons.aspect_ratio_rounded,
                  color: _canvasMode ? AppColor.getMain() : Colors.white70,
                ),
                onPressed: () => setState(() => _canvasMode = !_canvasMode),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!_canvasMode)
            SizedBox(
              height: 380,
              child: WebLyricsPanel(mediaItem: mediaItem, compact: true),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Now Playing Seek Bar Section connected to `player.positionStream`.
class _NowPlayingSeekSection extends StatelessWidget {
  final MiniPlayerController controller;
  final Color ambientColor;
  final bool expandedVisualizer;

  const _NowPlayingSeekSection({
    required this.controller,
    required this.ambientColor,
    this.expandedVisualizer = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: controller.audioHandler?.player.positionStream,
      builder: (context, posSnap) {
        final position = posSnap.data ?? Duration.zero;
        final duration =
            controller.audioHandler?.player.duration ??
            controller.visibleMediaItem?.duration ??
            Duration.zero;
        final sliderValue = computeSliderValue(position, duration);

        return Column(
          children: [
            _FullSeekSlider(
              value: sliderValue,
              duration: duration,
              onSeek: (target) {
                controller.audioHandler?.seek(target);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatPlayerDuration(position),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Pseudo Visualizer
                  SizedBox(
                    height: 20,
                    width: expandedVisualizer ? 200 : 130,
                    child: StreamBuilder<bool>(
                      stream: controller.audioHandler?.playbackState
                          .map((s) => s.playing)
                          .distinct()
                          .cast<bool>(),
                      builder: (_, snap) {
                        final playing = snap.data ?? false;
                        return WebPseudoVisualizer(
                          color: ambientColor == Colors.transparent
                              ? AppColor.getMain()
                              : ambientColor,
                          barCount: expandedVisualizer ? 20 : 14,
                          width: expandedVisualizer ? 200 : 130,
                          height: 20,
                          playing: playing,
                        );
                      },
                    ),
                  ),
                  Text(
                    formatPlayerDuration(duration),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Interactive seek slider with instant click-to-seek and smooth drag handling.
class _FullSeekSlider extends StatefulWidget {
  final double value;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _FullSeekSlider({
    required this.value,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<_FullSeekSlider> createState() => _FullSeekSliderState();
}

class _FullSeekSliderState extends State<_FullSeekSlider> {
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
          trackHeight: _hovered || _dragValue != null ? 6 : 4,
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: _hovered || _dragValue != null ? 7 : 4,
          ),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          activeTrackColor: AppColor.getMain(),
          inactiveTrackColor: Colors.white12,
          thumbColor: Colors.white,
        ),
        child: Slider(
          value: effectiveValue,
          onChangeStart: (v) => setState(() => _dragValue = v),
          onChanged: (v) => setState(() => _dragValue = v),
          onChangeEnd: (v) {
            final target = sliderValueToPosition(v, widget.duration);
            widget.onSeek(target);
            setState(() => _dragValue = null);
          },
        ),
      ),
    );
  }
}

/// Fullscreen Ambient Live Canvas Background.
class _AmbientLiveCanvasBackground extends StatelessWidget {
  final String? imageUrl;
  final bool canvasMode;
  final Color ambientColor;

  const _AmbientLiveCanvasBackground({
    required this.imageUrl,
    required this.canvasMode,
    required this.ambientColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = ambientColor == Colors.transparent
        ? AppColor.getMain()
        : ambientColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base dark container
        Container(
          color: canvasMode ? const Color(0xFF030509) : const Color(0xFF070D18),
        ),

        // Ambient radial backlighting
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: canvasMode
                  ? const Alignment(0.0, -0.25)
                  : const Alignment(-0.35, -0.3),
              radius: canvasMode ? 0.95 : 1.25,
              colors: [
                effectiveColor.withValues(alpha: canvasMode ? 0.32 : 0.45),
                effectiveColor.withValues(alpha: canvasMode ? 0.08 : 0.14),
                canvasMode ? const Color(0xFF030509) : const Color(0xFF070D18),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

/// Canvas mode large artwork component with Ken Burns slow zoom and live art glowing border.
class _CanvasArtwork extends StatefulWidget {
  final MediaItem mediaItem;
  final bool canvasMode;
  final Color ambientColor;
  final double size;

  const _CanvasArtwork({
    required this.mediaItem,
    required this.canvasMode,
    required this.ambientColor,
    this.size = 300.0,
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
      duration: const Duration(seconds: 14),
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
    final glowColor = widget.ambientColor == Colors.transparent
        ? AppColor.getMain()
        : widget.ambientColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.canvasMode
                ? glowColor.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.6),
            blurRadius: widget.canvasMode ? 44 : 20,
            spreadRadius: widget.canvasMode ? 4 : 0,
            offset: const Offset(0, 10),
          ),
          if (widget.canvasMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = widget.canvasMode
                    ? 1.0 + _controller.value * 0.12
                    : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: WebImageResolver.build(
                imageUrl: widget.mediaItem.artUri?.toString(),
                cacheKey: widget.mediaItem.id,
                width: widget.size,
                height: widget.size,
                borderRadius: 24,
              ),
            ),
          ),

          // Live Canvas Badge
          if (widget.canvasMode)
            Positioned(
              bottom: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColor.getMain(),
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ARTE EN VIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dynamic hoverable link text widget for web interfaces.
class _WebHoverLinkText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final String? tooltip;
  final VoidCallback onTap;

  const _WebHoverLinkText({
    required this.text,
    required this.style,
    required this.onTap,
    this.tooltip,
  });

  @override
  State<_WebHoverLinkText> createState() => _WebHoverLinkTextState();
}

class _WebHoverLinkTextState extends State<_WebHoverLinkText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style.copyWith(
      color: _isHovered ? Colors.white : widget.style.color,
      decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
      decorationColor: Colors.white,
    );

    final textWidget = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: effectiveStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 300),
        child: textWidget,
      );
    }
    return textWidget;
  }
}

/// Full-screen Like button that toggles favorite status and synchronizes with Firestore.
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
    if (!AppConfig.instance.canPersistUserActivity) {
      if (mounted) setState(() => _isLiked = false);
      return;
    }

    final liked = await PlaylistHiveController().checkPlaylist(
      AppHiveBox.favoriteItems.name,
      widget.mediaItem.id,
    );
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    if (!AppConfig.instance.canPersistUserActivity) return;

    final profile = PlaylistHiveController().userServiceImpl.profile;
    final itemId = widget.mediaItem.id;
    if (itemId.isEmpty) return;

    final newLiked = !_isLiked;
    if (mounted) setState(() => _isLiked = newLiked);

    try {
      if (newLiked) {
        await PlaylistHiveController().addItemToPlaylist(
          AppHiveBox.favoriteItems.name,
          widget.mediaItem,
        );
        if (profile.id.isNotEmpty) {
          profile.favoriteItems ??= [];
          if (!profile.favoriteItems!.contains(itemId)) {
            profile.favoriteItems!.add(itemId);
          }
          ProfileFirestore().addFavoriteItem(profile.id, itemId);
        }
        AppUtilities.showSnackBar(
          title: widget.mediaItem.title,
          message: CommonTranslationConstants.addedToFav.tr,
        );
      } else {
        await PlaylistHiveController().removeLiked(itemId);
        if (profile.id.isNotEmpty) {
          profile.favoriteItems?.remove(itemId);
          ProfileFirestore().removeFavoriteItem(profile.id, itemId);
        }
        AppUtilities.showSnackBar(
          title: widget.mediaItem.title,
          message: CommonTranslationConstants.removedFromFav.tr,
        );
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_audio_player',
        operation: '_FullScreenLikeButton._toggleLike',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _isLiked ? 'Eliminar de favoritos' : 'Guardar en favoritos',
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            AuthGuard.protect(context, () {
              _toggleLike();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isLiked ? AppColor.getMain() : Colors.white54,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
