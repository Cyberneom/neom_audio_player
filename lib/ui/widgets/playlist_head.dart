import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_media_player/utils/constants/player_translation_constants.dart';

import '../../neom_player_invoker.dart';

class PlaylistHead extends StatelessWidget {
  final List<AppMediaItem> songsList;
  final bool offline;
  final bool fromDownloads;

  const PlaylistHead({
    super.key,
    required this.songsList,
    this.fromDownloads = false,
    this.offline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 20.0, right: 10.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${songsList.length} ${PlayerTranslationConstants.mediaItems.tr}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              NeomPlayerInvoker.init(
                appMediaItems: songsList,
                index: 0,
                isOffline: offline,
                fromDownloads: fromDownloads,
                recommend: false,
                shuffle: true,
              );
            },
            icon: const Icon(Icons.shuffle_rounded),
            label: Text(
              PlayerTranslationConstants.shuffle.tr.tr,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () {
              NeomPlayerInvoker.init(
                appMediaItems: songsList,
                index: 0,
                isOffline: offline,
                fromDownloads: fromDownloads,
                recommend: false,
              );
            },
            tooltip: PlayerTranslationConstants.shuffle.tr,
            icon: const Icon(Icons.play_arrow_rounded),
            iconSize: 30.0,
          ),
        ],
      ),
    );
  }
}
