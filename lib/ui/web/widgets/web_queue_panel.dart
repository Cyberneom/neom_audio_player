import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import '../../../neom_audio_handler.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';

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

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColor.getMain().withOpacity(0.15),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: currentItem.artUri != null
                          ? platformNetworkImage(
                              imageUrl: currentItem.artUri.toString(),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorWidget: _artPlaceholder(48),
                            )
                          : _artPlaceholder(48),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AudioPlayerTranslationConstants.nowPlaying.tr,
                            style: TextStyle(
                              color: AppColor.getMain(),
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

                    return ReorderableListView.builder(
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

  static Widget _artPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColor.getMain().withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 20),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: item.artUri != null
                    ? platformNetworkImage(
                        imageUrl: item.artUri.toString(),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: WebQueuePanel._artPlaceholder(40),
                      )
                    : WebQueuePanel._artPlaceholder(40),
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
