import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../data/implementations/playlist_hive_controller.dart';
import '../../domain/use_cases/neom_audio_handler.dart';
import '../../utils/constants/player_translation_constants.dart';
import '../../utils/helpers/media_item_mapper.dart';
import 'snackbar.dart';

class PlaylistPopupMenu extends StatefulWidget {
  final List data;
  final String title;
  const PlaylistPopupMenu({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  _PlaylistPopupMenuState createState() => _PlaylistPopupMenuState();
}

class _PlaylistPopupMenuState extends State<PlaylistPopupMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(
        Icons.more_vert_rounded,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15.0)),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(
                Icons.queue_music_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(PlayerTranslationConstants.addToQueue.tr),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                Icons.favorite_border_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(PlayerTranslationConstants.savePlaylist.tr),
            ],
          ),
        ),
      ],
      onSelected: (int? value) {
        if (value == 1) {
          PlaylistHiveController().addPlaylist(widget.title, widget.data).then(
            (value) => ShowSnackBar().showSnackBar(
              context,
              '"${widget.title}" ${PlayerTranslationConstants.addedToPlaylists.tr}',
            ),
          );
        }
        if (value == 0) {
          final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();
          final MediaItem? currentMediaItem = audioHandler.mediaItem.valueWrapper?.value;
          if (currentMediaItem != null &&
              currentMediaItem.extras!['url'].toString().startsWith('http')) {
            // TODO: make sure to check if song is already in queue
            final queue = audioHandler.queue.valueWrapper?.value;
            widget.data.map((e) {
              final element = MediaItemMapper.fromJSON(e as Map);
              if (!queue!.contains(element)) {
                audioHandler.addQueueItem(element);
              }
            });

            ShowSnackBar().showSnackBar(
              context,
              '"${widget.title}" ${PlayerTranslationConstants.addedToQueue.tr}',
            );
          } else {
            ShowSnackBar().showSnackBar(
              context,
              currentMediaItem == null
                  ? PlayerTranslationConstants.nothingPlaying.tr
                  : PlayerTranslationConstants.cantAddToQueue.tr,
            );
          }
        }
      },
    );
  }
}
