
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/neom_image_card.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';

import '../../../utils/constants/music_player_constants.dart';
import '../../../utils/helpers/media_item_mapper.dart';
import '../miniplayer_controller.dart';
import 'control_buttons.dart';

class MiniPlayerTile extends StatelessWidget {

  final MediaItem? item;
  final List<String> preferredMiniButtons;
  final bool useDense;
  final bool isLocalImage;
  final bool isTimeline;
  final MiniPlayerController miniPlayerController;

  const MiniPlayerTile({super.key,
    this.item,
    required this.preferredMiniButtons,
    required this.miniPlayerController,
    this.useDense = false,
    this.isLocalImage = false,
    this.isTimeline = true,
  });

  @override
  Widget build(BuildContext context) {

    return ListTile(
      tileColor: AppColor.main75,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      onTap: () {
        if(item != null) {
          Get.toNamed(AppRouteConstants.musicPlayerMedia, arguments: [MediaItemMapper.fromMediaItem(item!)]);
        }
        ///DEPRECATED
        ///Navigator.push(context, MaterialPageRoute(builder: (context) => MediaPlayerPage(appMediaItem: MediaItemMapper.fromMediaItem(item)),),
      },
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(!isTimeline)
            IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => miniPlayerController.goToTimeline(context), ),
          if(item != null || isTimeline)
            SizedBox(
              height: item == null ? 74 : 72,
              width: isTimeline && item == null ? (MediaQuery.of(context).size.width/6) : null,
              child: Hero(tag: 'currentArtwork',
                child: NeomImageCard(
                  elevation: 10,
                  boxDimension: useDense ? 40.0 : 50.0,
                  localImage: item?.artUri?.toString().startsWith('file:') ?? false,
                  imageUrl: (item?.artUri?.toString().startsWith('file:') ?? false
                      ? item?.artUri?.toFilePath() : item?.artUri?.toString()) ?? AppFlavour.getAppLogoUrl(),
                ),
              ),
            ),
        ],
      ),
      title: SizedBox(
        ///DEPRECATED width: AppTheme.fullWidth(context)*0.6,
       child: Text(
         item?.title ?? (isTimeline ? AppTranslationConstants.lookingForNewMusic.tr : AppTranslationConstants.lookingForInspiration.tr),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
         textAlign: isTimeline || item != null ? TextAlign.left : TextAlign.right,
         style: const TextStyle(letterSpacing: -0.5, fontWeight: FontWeight.bold),
       ),
      ),
      subtitle: SizedBox(
        ///DEPRECATED width: AppTheme.fullWidth(context)*0.6,
        child: Text(
          item?.artist ?? (isTimeline ? AppTranslationConstants.tryOurPlatform.tr : AppTranslationConstants.goBackHome.tr),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: isTimeline || item != null ? TextAlign.left : TextAlign.right,
          style: const TextStyle(letterSpacing: -0.5),
        ),
      ),
      trailing: SizedBox(
        width: MediaQuery.of(context).size.width/(item == null ?(isTimeline ? 12 : 6) : 3.6),
        // width: item == null && isTimeline ? (MediaQuery.of(context).size.width/12) : (MediaQuery.of(context).size.width/(item == null ? 6 : 3)),
        child: item == null
            ? (isTimeline ? IconButton(onPressed: () => miniPlayerController.goToMusicPlayerHome(), icon: const Icon(Icons.arrow_forward_ios))
            : Hero(tag: AppConstants.currentArtwork,
          child: NeomImageCard(
            elevation: 10,
            boxDimension: useDense ? 40.0 : 50.0,
            localImage: item?.artUri?.toString().startsWith('file:') ?? false,
            imageUrl: (item?.artUri?.toString().startsWith('file:') ?? false
                ? item?.artUri?.toFilePath() : item?.artUri?.toString()) ?? AppFlavour.getAppLogoUrl(),
          ),
        )
        ) : ControlButtons(miniPlayerController.audioHandler, miniplayer: true,
          buttons: isLocalImage ? MusicPlayerConstants.defaultControlButtons : preferredMiniButtons,
          mediaItem: item,
        ),
      ),
    );
  }
}
