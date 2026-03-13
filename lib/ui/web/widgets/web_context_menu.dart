import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/share_utilities.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/helpers/add_mediaitem_to_queue.dart';
import '../../../utils/mappers/media_item_mapper.dart';
import '../../player/widgets/add_to_playlist.dart';

/// Reusable right-click context menu for web song cards.
class WebContextMenu {
  static void show(
    BuildContext context,
    Offset position,
    AppMediaItem item, {
    VoidCallback? onRemoveFromPlaylist,
  }) {
    final MediaItem mediaItem = MediaItemMapper.fromAppMediaItem(item: item);
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final items = <PopupMenuItem<int>>[
      _buildMenuItem(
        value: 0,
        icon: Icons.playlist_play_rounded,
        label: AudioPlayerTranslationConstants.playNext.tr,
      ),
      _buildMenuItem(
        value: 1,
        icon: Icons.queue_music_rounded,
        label: AudioPlayerTranslationConstants.addToQueue.tr,
      ),
      _buildMenuItem(
        value: 2,
        icon: Icons.playlist_add_rounded,
        label: AudioPlayerTranslationConstants.addToPlaylist.tr,
      ),
      if (onRemoveFromPlaylist != null)
        _buildMenuItem(
          value: 4,
          icon: Icons.remove_circle_outline_rounded,
          label: AppTranslationConstants.remove.tr,
        ),
      _buildMenuItem(
        value: 5,
        icon: Icons.person_rounded,
        label: AudioPlayerTranslationConstants.goToArtist.tr,
      ),
      _buildMenuItem(
        value: 3,
        icon: Icons.share_rounded,
        label: AppTranslationConstants.toShare.tr,
      ),
    ];

    showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      color: AppColor.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: items,
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 0:
          playNext(mediaItem, context);
        case 1:
          addToNowPlaying(context: context, mediaItem: mediaItem);
        case 2:
          AddToPlaylist().addToPlaylist(context, item);
        case 3:
          ShareUtilities.shareAppWithMediaItem(item);
        case 4:
          onRemoveFromPlaylist?.call();
        case 5:
          // Go to artist — could navigate to artist page
          break;
      }
    });
  }

  static PopupMenuItem<int> _buildMenuItem({
    required int value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<int>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
