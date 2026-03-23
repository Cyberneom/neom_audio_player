import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/deeplink_utilities.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';

import '../../../data/implementations/radio_controller.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/mappers/media_item_mapper.dart';
import '../../home/widgets/collage.dart';
import 'web_context_menu.dart';
import 'web_edit_playlist_dialog.dart';
import 'web_jam_create_dialog.dart';

/// Inline playlist detail view for the web center panel (Spotify-style).
class WebPlaylistDetail extends StatefulWidget {
  final Itemlist itemlist;
  final VoidCallback? onBack;

  const WebPlaylistDetail({
    Key? key,
    required this.itemlist,
    this.onBack,
  }) : super(key: key);

  @override
  State<WebPlaylistDetail> createState() => _WebPlaylistDetailState();
}

class _WebPlaylistDetailState extends State<WebPlaylistDetail> {
  List<AppMediaItem> _items = [];
  bool _isLoading = true;
  bool _isSaved = false;

  @override
  void initState() {
    _checkSaved();
    super.initState();
    _loadItems();
  }

  @override
  void didUpdateWidget(covariant WebPlaylistDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemlist.id != widget.itemlist.id) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = AppMediaItemMapper.mapItemsFromItemlist(widget.itemlist);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _playAll({bool shuffle = false}) {
    if (_items.isEmpty) return;
    Sint.find<AudioPlayerInvokerService>().init(
      mediaItems: _items,
      playItem: true,
      shuffle: shuffle,
    );
  }

  void _playSong(int index) {
    if (_items.isEmpty) return;
    Sint.find<AudioPlayerInvokerService>().updateNowPlaying(
      items: _items,
      index: index,
    );
  }

  void _removeItem(int index) {
    final item = _items[index];
    setState(() => _items.removeAt(index));
    // Persist removal if itemlist has an ID (not virtual)
    if (widget.itemlist.id.isNotEmpty) {
      widget.itemlist.appMediaItems?.removeWhere((m) => m.id == item.id);
      widget.itemlist.appReleaseItems?.removeWhere((r) => r.id == item.id);
      ItemlistFirestore().update(widget.itemlist);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    // Persist new order if itemlist has an ID
    if (widget.itemlist.id.isNotEmpty) {
      widget.itemlist.appMediaItems = List.from(_items);
      ItemlistFirestore().update(widget.itemlist);
    }
  }

  /// Whether the current user owns this playlist.
  bool get _isOwner {
    try {
      return widget.itemlist.ownerId == Sint.find<UserService>().profile.id;
    } catch (_) {
      return false;
    }
  }

  void _checkSaved() {
    try {
      final profile = Sint.find<UserService>().profile;
      _isSaved = profile.savedItemlistIds?.contains(widget.itemlist.id) ?? false;
    } catch (_) {}
  }

  Future<void> _toggleSave() async {
    try {
      final userService = Sint.find<UserService>();
      final profileId = userService.profile.id;
      final itemlistId = widget.itemlist.id;

      if (_isSaved) {
        await ProfileFirestore().unsaveItemlist(profileId, itemlistId);
        userService.profile.savedItemlistIds?.remove(itemlistId);
      } else {
        await ProfileFirestore().saveItemlist(profileId, itemlistId);
        userService.profile.savedItemlistIds ??= [];
        userService.profile.savedItemlistIds!.add(itemlistId);
      }
      if (mounted) {
        setState(() => _isSaved = !_isSaved);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSaved
                ? AudioPlayerTranslationConstants.savedToLibrary.tr
                : AudioPlayerTranslationConstants.removedFromLibrary.tr),
            backgroundColor: AppColor.getMain(),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColor.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(AudioPlayerTranslationConstants.deletePlaylist.tr,
            style: const TextStyle(color: Colors.white)),
        content: Text('${AppTranslationConstants.delete.tr} "${widget.itemlist.name}"?',
            style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton(
            onPressed: () => Sint.back(),
            child: Text(AppTranslationConstants.cancel.tr,
                style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () async {
              Sint.back();
              await ItemlistFirestore().delete(widget.itemlist.id);
              widget.onBack?.call();
            },
            child: Text(AppTranslationConstants.delete.tr,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _startRadio() async {
    try {
      final radio = Sint.find<RadioController>();
      final genre = widget.itemlist.categories?.firstOrNull
          ?? widget.itemlist.tags?.firstOrNull;

      final station = genre != null && genre.isNotEmpty
          ? await radio.createStationFromGenre(genre)
          : _items.isNotEmpty
              ? await radio.createStationFromSong(_items.first.id)
              : await radio.createPersonalMix();

      if (station.queue.isNotEmpty && mounted) {
        final items = station.queue.map((m) => MediaItemMapper.toAppMediaItem(m)).toList();
        Sint.find<AudioPlayerInvokerService>().init(mediaItems: items, playItem: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AudioPlayerTranslationConstants.radioStarted.tr}: ${station.name}'),
            backgroundColor: AppColor.surfaceElevated,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  void _startJam() {
    WebJamCreateDialog.show(context, sourcePlaylist: widget.itemlist);
  }

  void _sharePlaylist() {
    final url = DeeplinkUtilities.generateVanityUrl(
      type: 'playlist',
      id: widget.itemlist.id,
    );
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AudioPlayerTranslationConstants.linkCopied.tr),
        backgroundColor: AppColor.getMain(),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemlist = widget.itemlist;
    final imgUrls = itemlist.getImgUrls();

    return Column(
      children: [
        // ─── Header ───
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColor.getMain().withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Back button
              if (widget.onBack != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 8),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onBack,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),

              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 192,
                  height: 192,
                  child: imgUrls.isNotEmpty
                      ? Collage(
                          borderRadius: 8,
                          imageList: imgUrls,
                          showGrid: true,
                          placeholderImage: AppAssets.audioPlayerCover,
                        )
                      : Container(
                          color: AppColor.getMain().withOpacity(0.3),
                          child: const Icon(Icons.library_music, color: Colors.white54, size: 64),
                        ),
                ),
              ),
              const SizedBox(width: 24),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppTranslationConstants.playlists.tr.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Name — clickable to edit if owner
                    MouseRegion(
                      cursor: _isOwner ? SystemMouseCursors.click : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: _isOwner
                            ? () => WebEditPlaylistDialog.show(
                                    context, itemlist,
                                    onUpdated: () => setState(() {}))
                            : null,
                        child: Text(
                          itemlist.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (itemlist.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        itemlist.description,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${itemlist.ownerName} \u2022 ${_items.length} ${AudioPlayerTranslationConstants.mediaItems.tr}',
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ─── Action buttons ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              // Play All
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _playAll(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColor.getMain(),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Shuffle
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _playAll(shuffle: true),
                  child: Icon(Icons.shuffle_rounded, color: Colors.grey[400], size: 28),
                ),
              ),
              const SizedBox(width: 16),
              // Start Radio
              Tooltip(
                message: AudioPlayerTranslationConstants.startRadio.tr,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _startRadio,
                    child: Icon(Icons.radio, color: Colors.grey[400], size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Start Jam
              Tooltip(
                message: AudioPlayerTranslationConstants.startJam.tr,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _startJam,
                    child: Icon(Icons.podcasts, color: Colors.grey[400], size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Share
              if (itemlist.id.isNotEmpty)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _sharePlaylist,
                    child: Icon(Icons.share_outlined, color: Colors.grey[400], size: 24),
                  ),
                ),
              // Save to Library (for non-owners)
              if (!_isOwner && itemlist.id.isNotEmpty) ...[
                const SizedBox(width: 16),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _toggleSave,
                    child: Icon(
                      _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isSaved ? AppColor.getMain() : Colors.grey[400],
                      size: 26,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // More options (owner only)
              if (_isOwner)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, color: Colors.grey[400], size: 28),
                  color: AppColor.surfaceElevated,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      WebEditPlaylistDialog.show(context, itemlist,
                          onUpdated: () => setState(() {}));
                    } else if (value == 'delete') {
                      _confirmDelete(context);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text(AudioPlayerTranslationConstants.editPlaylist.tr,
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(AudioPlayerTranslationConstants.deletePlaylist.tr,
                              style: const TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ─── Column header ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('#', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
              const Expanded(
                flex: 4,
                child: Text('', style: TextStyle(color: Colors.transparent)),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  AudioPlayerTranslationConstants.artist.tr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ),
              SizedBox(
                width: 60,
                child: Icon(Icons.access_time_rounded, color: Colors.grey[500], size: 16),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        Divider(color: Colors.white.withOpacity(0.1), height: 1),

        // ─── Song list (reorderable) ───
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColor.getMain()))
              : _items.isEmpty
                  ? Center(
                      child: Text(
                        AudioPlayerTranslationConstants.nothingPlaying.tr,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: _items.length,
                      onReorder: _onReorder,
                      itemBuilder: (context, index) {
                        return _SongRow(
                          key: ValueKey(_items[index].id),
                          index: index,
                          item: _items[index],
                          onTap: () => _playSong(index),
                          onRemove: () => _removeItem(index),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

/// Individual song row in the playlist detail (Spotify table-style).
class _SongRow extends StatefulWidget {
  final int index;
  final AppMediaItem item;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _SongRow({
    Key? key,
    required this.index,
    required this.item,
    required this.onTap,
    this.onRemove,
  }) : super(key: key);

  @override
  State<_SongRow> createState() => _SongRowState();
}

class _SongRowState extends State<_SongRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final duration = Duration(seconds: item.duration);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) {
          WebContextMenu.show(context, details.globalPosition, item);
        },
        child: Container(
          color: _isHovered ? Colors.white.withOpacity(0.08) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              // Drag handle (visible on hover)
              SizedBox(
                width: 20,
                child: _isHovered
                    ? ReorderableDragStartListener(
                        index: widget.index,
                        child: const Icon(Icons.drag_handle_rounded, color: Colors.white38, size: 16),
                      )
                    : const SizedBox.shrink(),
              ),
              // Index / Play icon
              SizedBox(
                width: 24,
                child: _isHovered
                    ? const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18)
                    : Text(
                        '${widget.index + 1}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
              ),
              const SizedBox(width: 8),
              // Artwork + Title
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: item.imgUrl.isNotEmpty
                          ? platformNetworkImage(
                              imageUrl: item.imgUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorWidget: _artPlaceholder(),
                            )
                          : _artPlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Artist
              Expanded(
                flex: 3,
                child: Text(
                  item.ownerName,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Duration
              SizedBox(
                width: 60,
                child: Text(
                  duration.inSeconds > 0
                      ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
                      : '',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
              // Delete + More menu (hover-reveal)
              SizedBox(
                width: 64,
                child: _isHovered
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onRemove != null)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: widget.onRemove,
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.remove_circle_outline_rounded, color: Colors.white38, size: 18),
                                ),
                              ),
                            ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTapDown: (details) {
                                WebContextMenu.show(context, details.globalPosition, item);
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.more_horiz_rounded, color: Colors.white54, size: 20),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      color: AppColor.getMain().withOpacity(0.3),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 18),
    );
  }
}
