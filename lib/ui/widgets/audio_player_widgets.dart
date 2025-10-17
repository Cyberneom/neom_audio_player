import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/images/neom_image_card.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';

import '../../data/implementations/player_hive_controller.dart';
import '../../audio_player_invoker.dart';
import '../player/audio_player_controller.dart';
import 'like_button.dart';
import 'song_tile_trailing_menu.dart';

Widget homeDrawer({required BuildContext context, EdgeInsetsGeometry padding = EdgeInsets.zero,}) {
  return Padding(
    padding: padding,
    child: Transform.rotate(
      angle: 22 / 7 * 2,
      child: IconButton(
        icon: const Icon(
          Icons.horizontal_split_rounded,
        ),
        // color: Theme.of(context).iconTheme.color,
        onPressed: () => Scaffold.of(context).openDrawer(),
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      ),
    ),
  );
}

ListTile createCoolMediaItemTile(BuildContext context, AppMediaItem appMediaItem, {Itemlist? itemlist,
  String query = '', bool downloadAllowed = false}) {

  bool isInternal = appMediaItem.mediaSource == AppMediaSource.internal || appMediaItem.mediaSource == AppMediaSource.offline;

  return ListTile(
    contentPadding: const EdgeInsets.only(left: 15.0,),
    title: Text(appMediaItem.name,
      style: const TextStyle(fontWeight: FontWeight.w500,),
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(TextUtilities.getArtistName(appMediaItem.artist),
      overflow: TextOverflow.ellipsis,
    ),
    isThreeLine: false,
    leading: NeomImageCard(
        placeholderImage: const AssetImage(AppAssets.audioPlayerCover),
        imageUrl: appMediaItem.imgUrl
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isInternal ? LikeButton(appMediaItem: appMediaItem,)
            : const SizedBox.shrink(),
        ///TO IMPLEMENT WHEN ADDING neom_downloads as dependency
        // if(downloadAllowed) DownloadButton(mediaItem: appMediaItem,),
        isInternal ? SongTileTrailingMenu(
          appMediaItem: appMediaItem,
          itemlist: itemlist,
        ) : AppTheme.widthSpace10,
      ],
    ),
    onLongPress: () {
      // CoreUtilities.copyToClipboard(text: appMediaItem.permaUrl,);
      Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);
    },
    onTap: () async {
      PlayerHiveController().addQuery(appMediaItem.name);

      if(appMediaItem.mediaSource == AppMediaSource.internal || appMediaItem.mediaSource == AppMediaSource.offline) {
        if (Get.isRegistered<AudioPlayerController>()) {
          Get.find<AudioPlayerController>().setMediaItem(appItem: appMediaItem);
        } else {
          Get.put(AudioPlayerController()).setMediaItem(appItem: appMediaItem);
        }
        await Get.find<AudioPlayerInvoker>().updateNowPlaying([appMediaItem], 0);
      } else {
        await Get.find<AudioPlayerInvoker>().updateNowPlaying([appMediaItem], 0);
      }

      // Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);
    },
  );
}
