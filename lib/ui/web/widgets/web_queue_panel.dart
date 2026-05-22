import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import '../../../neom_audio_handler.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/mappers/media_item_mapper.dart';
import '../utils/web_color_extractor.dart';
import '../utils/web_duration_formatter.dart';
import '../utils/web_image_resolver.dart';
import 'web_context_menu.dart';

/// Right-side queue panel showing the current playback queue (Spotify-style).
class WebQueuePanel extends StatelessWidget {
  final VoidCallback? onClose;

  const WebQueuePanel({Key? key, this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioHandler = Sint.find<NeomAudioHandler>();

    return Container(
      decoration: BoxDecoration(
        color: AppColor.appBlack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // ─── Header ───
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AudioPlayerTranslationConstants.upNext.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.1), height: 1),

          // ─── Now Playing ───
          StreamBuilder<MediaItem?>(
            stream: audioHandler.mediaItem,
            builder: (context, snapshot) {
              final currentItem = snapshot.data;
              if (currentItem == null) return const SizedBox.shrink();

              final tint = WebColorExtractor.cachedOrFallback(currentItem.id);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      tint.withValues(alpha: 0.22),
                      tint.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    WebImageResolver.build(
                      imageUrl: currentItem.artUri?.toString(),
                      cacheKey: currentItem.id,
                      width: 48,
                      height: 48,
                      borderRadius: 4,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AudioPlayerTranslationConstants.nowPlaying.tr,
                            style: TextStyle(
                              color: tint,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentItem.title,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentItem.artist ?? '',
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ─── Queue list (reorderable) ───
          Expanded(
            child: StreamBuilder<List<MediaItem>>(
              stream: audioHandler.queue,
              builder: (context, queueSnapshot) {
                return StreamBuilder<MediaItem?>(
                  stream: audioHandler.mediaItem,
                  builder: (context, currentSnapshot) {
                    final queue = queueSnapshot.data ?? [];
                    final currentItem = currentSnapshot.data;

                    if (queue.isEmpty) {
                      return Center(
                        child: Text(
                          AudioPlayerTranslationConstants.nothingPlaying.tr,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      );
                    }

                    // Find current index and show only upcoming
                    int currentIndex = -1;
                    if (currentItem != null) {
                      currentIndex = queue.indexWhere((item) => item.id == currentItem.id);
                    }

                    final upcoming = currentIndex >= 0 && currentIndex < queue.length - 1
                        ? queue.sublist(currentIndex + 1)
                        : queue;

                    if (upcoming.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          AudioPlayerTranslationConstants.nothingPlaying.tr,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final upcomingStartIndex = currentIndex + 1;
                    final totalRemaining = upcoming.fold<Duration>(
                      Duration.zero,
                      (acc, item) => acc + (item.duration ?? Duration.zero),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Text(
                                AudioPlayerTranslationConstants.upNext.tr.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${upcoming.length}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (totalRemaining > Duration.zero) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatRemainingDuration(totalRemaining),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      itemCount: upcoming.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex--;
                        final realOldIndex = upcomingStartIndex + oldIndex;
                        final realNewIndex = upcomingStartIndex + newIndex;
                        audioHandler.moveQueueItem(realOldIndex, realNewIndex);
                      },
                      itemBuilder: (context, index) {
                        return _QueueItem(
                          key: ValueKey(upcoming[index].id),
                          item: upcoming[index],
                          index: index,
                          onTap: () {
                            audioHandler.skipToQueueItem(
                              queue.indexOf(upcoming[index]),
                            );
                          },
                          onRemove: () {
                            final realIndex = upcomingStartIndex + index;
                            audioHandler.removeQueueItemAt(realIndex);
                          },
                        );
                      },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

/// Individual queue item row with drag handle.
class _QueueItem extends StatefulWidget {
  final MediaItem item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _QueueItem({
    Key? key,
    required this.item,
    required this.index,
    required this.onTap,
    this.onRemove,
  }) : super(key: key);

  @override
  State<_QueueItem> createState() => _QueueItemState();
}

class _QueueItemState extends State<_QueueItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) {
          WebContextMenu.show(
            context,
            details.globalPosition,
            MediaItemMapper.toAppMediaItem(item),
          );
        },
        child: Container(
          color: _isHovered ? Colors.white.withOpacity(0.06) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              // Drag handle
              if (_isHovered)
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.drag_handle_rounded, color: Colors.white38, size: 16),
                  ),
                )
              else
                const SizedBox(width: 20),
              WebImageResolver.build(
                imageUrl: item.artUri?.toString(),
                cacheKey: item.id,
                width: 40,
                height: 40,
                borderRadius: 4,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.artist ?? '',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Remove button on hover
              if (_isHovered && widget.onRemove != null)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
