import 'package:audio_service/audio_service.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../../utils/platform_io_helper.dart' as platform_io;

import '../../../domain/models/queue_state.dart';
import '../../../neom_audio_handler.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../widgets/like_button.dart';

class NowPlayingStream extends StatelessWidget {
  final NeomAudioHandler? audioHandler;
  final ScrollController? scrollController;
  final PanelController? panelController;
  final bool head;
  final double headHeight;
  final bool downloadAllowed;
  final bool showLikeButton;

  const NowPlayingStream({super.key,
    required this.audioHandler,
    this.scrollController,
    this.panelController,
    this.head = false,
    this.headHeight = 50,
    this.downloadAllowed = false,
    this.showLikeButton = true,
  });

  void _updateScrollController(ScrollController? controller, int itemIndex,
      int queuePosition, int queueLength,) {

    if (panelController != null && !panelController!.isPanelOpen) {
      if (queuePosition > 3) {
        controller?.animateTo(
          itemIndex * 72 + 12,
          curve: Curves.linear,
          duration: const Duration(
            milliseconds: 350,
          ),
        );
      } else if (queuePosition < 4 && queueLength > 4) {
        controller?.animateTo(
          (queueLength - 4) * 72 + 12,
          curve: Curves.linear,
          duration: const Duration(
            milliseconds: 350,
          ),
        );
      }
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueueState>(
      stream: audioHandler?.queueState,
      builder: (context, snapshot) {
        final queueState = snapshot.data ?? QueueState.empty;
        final queue = queueState.queue;
        final int queueStateIndex = queueState.queueIndex ?? 0;
        final num queuePosition = queue.length - queueStateIndex;
        WidgetsBinding.instance.addPostFrameCallback(
              (_) => _updateScrollController(
            scrollController,
            queueState.queueIndex ?? 0,
            queuePosition.toInt(),
            queue.length,
          ),
        );

        return ReorderableListView.builder(
          header: SizedBox(height: head ? headHeight : 0,),
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) newIndex--;
            audioHandler?.moveQueueItem(oldIndex, newIndex);
          },
          scrollController: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 10),
          shrinkWrap: true,
          itemCount: queue.length,
          itemBuilder: (context, index) {
            MediaItem item = queue[index];
            return Dismissible(
              key: ValueKey(item.id),
              direction: index == queueState.queueIndex
                  ? DismissDirection.none
                  : DismissDirection.horizontal,
              onDismissed: (dir) => audioHandler?.removeQueueItemAt(index),
              child: ListTileTheme(
                selectedColor: Theme.of(context).colorScheme.secondary,
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 16.0, right: 10.0),
                  selected: index == queueState.queueIndex,
                  tileColor: AppColor.surfaceElevated,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: (index == queueState.queueIndex)
                        ? [
                      IconButton(
                        icon: const Icon(Icons.bar_chart_rounded,),
                        tooltip: AppTranslationConstants.playing.tr,
                        onPressed: () {},
                      ),
                    ] : [
                      if(item.extras!['url'].toString().startsWith('http')) ...[
                        if(showLikeButton) LikeButton(
                          itemId: queue[index].id,
                          itemName: queue[index].title,
                        ),
                        ///TO IMPLEMENT WHEN ADDING neom_downloads as dependency
                        // if(downloadAllowed) DownloadButton(mediaItem: MediaItemMapper.toAppMediaItem(queue[index]),),
                      ],
                      ReorderableDragStartListener(
                        key: Key(item.id),
                        index: index,
                        enabled: index != queueState.queueIndex,
                        child: const Icon(Icons.drag_handle_rounded),
                      ),
                    ],
                  ),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (item.extras?['addedByAutoplay'] as bool? ??
                          false)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    AudioPlayerTranslationConstants.addedBy.tr,
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                      fontSize: 5.0,
                                    ),
                                  ),
                                ),
                                RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    AudioPlayerTranslationConstants.autoplay.tr,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: 8.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppTheme.heightSpace5
                          ],
                        ),
                      Card(
                        elevation: 5,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (item.artUri == null)
                            ? const SizedBox.square(
                          dimension: 50,
                          child: Image(image: AssetImage(AppAssets.audioPlayerCover),),
                        ) : SizedBox.square(
                          dimension: 50,
                          child: queue[index].artUri.toString().startsWith('file:') && platform_io.supportsLocalFiles
                              ? Image(
                              image: platform_io.createFileImage(item.artUri!.toFilePath()) ??
                                  const AssetImage(AppAssets.audioPlayerCover),
                              fit: BoxFit.cover,
                          ) : HandledCachedNetworkImage(
                            item.artUri.toString(),
                            fit: BoxFit.cover,
                            enableFullScreen: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    item.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: index == queueState.queueIndex
                          ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    item.artist!,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => audioHandler?.skipToQueueItem(index),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
