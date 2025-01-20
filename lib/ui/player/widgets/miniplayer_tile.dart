import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/neom_image_card.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';

import '../../../utils/audio_player_utilities.dart';
import '../../../utils/constants/audio_player_constants.dart';
import '../../../utils/helpers/media_item_mapper.dart';
import '../miniplayer_controller.dart';
import 'control_buttons.dart';

class MiniPlayerTile extends StatefulWidget {
  final MediaItem? item;
  final List<String> preferredMiniButtons;
  final bool useDense;
  final bool isLocalImage;
  final bool isTimeline;
  final MiniPlayerController miniPlayerController;

  const MiniPlayerTile({
    super.key,
    this.item,
    required this.preferredMiniButtons,
    required this.miniPlayerController,
    this.useDense = false,
    this.isLocalImage = false,
    this.isTimeline = true,
  });

  @override
  State<MiniPlayerTile> createState() => _MiniPlayerTileState();
}

class _MiniPlayerTileState extends State<MiniPlayerTile> {

  String titleText = '';
  String subtitleText = '';
  Timer? timer;

  @override
  void initState() {
    super.initState();


    titleText = widget.item?.title ?? '';
    subtitleText = widget.item?.artist ?? '';

    if(titleText.contains(' - ')) {
      titleText = AudioPlayerUtilities.getMediaName(titleText);
      if(subtitleText.isEmpty) {
        subtitleText = AudioPlayerUtilities.getArtistName(titleText);
      }
    }

    if(!widget.miniPlayerController.isInternal) {
      subtitleText = AppTranslationConstants.releasePreview.tr;
      startSubtitleToggle();
    }
  }

  @override
  void dispose() {
    if(timer != null)  timer?.cancel();
    super.dispose();
  }

  void startSubtitleToggle() {
    timer = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        // Toggle between item?.artist and "Vista Previa"
        subtitleText = subtitleText == (widget.item?.artist ?? '')
            ? AppTranslationConstants.releasePreview.tr
            : widget.item?.artist ?? '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColor.main75,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      onTap: () {
        if(widget.item != null && widget.miniPlayerController.isInternal) {
          Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [MediaItemMapper.fromMediaItem(widget.item!)]);
        }
      },
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(!widget.isTimeline)
            IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => widget.miniPlayerController.goToTimeline(context), ),
          if(widget.item != null || widget.isTimeline)
            SizedBox(
              height: widget.item == null ? 74 : 72,
              width: widget.isTimeline && widget.item == null ? (MediaQuery.of(context).size.width/6) : null,
              child: Hero(tag: 'currentArtwork',
                child: NeomImageCard(
                  elevation: 10,
                  boxDimension: widget.useDense ? 40.0 : 50.0,
                  localImage: widget.item?.artUri?.toString().startsWith('file:') ?? false,
                  imageUrl: (widget.item?.artUri?.toString().startsWith('file:') ?? false
                      ? widget.item?.artUri?.toFilePath() : widget.item?.artUri?.toString()) ?? AppFlavour.getAppLogoUrl(),
                ),
              ),
            ),
        ],
      ),
      title: SizedBox(
       child: Text(titleText.isNotEmpty ? titleText : (widget.isTimeline ? AppTranslationConstants.lookingForNewMusic.tr : AppTranslationConstants.lookingForInspiration.tr),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
         textAlign: widget.isTimeline || widget.item != null ? TextAlign.left : TextAlign.right,
         style: const TextStyle(letterSpacing: -0.5, fontWeight: FontWeight.bold),
       ),
      ),
      subtitle: SizedBox(
        child: Text(
          subtitleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: widget.isTimeline || widget.item != null ? TextAlign.left : TextAlign.right,
          style: const TextStyle(letterSpacing: -0.5),
        ),
      ),
      trailing: SizedBox(
        width: MediaQuery.of(context).size.width/(widget.item == null ?(widget.isTimeline ? 12 : 6) : 3.6),
        // width: item == null && isTimeline ? (MediaQuery.of(context).size.width/12) : (MediaQuery.of(context).size.width/(item == null ? 6 : 3)),
        child: widget.item == null
            ? (widget.isTimeline ? IconButton(onPressed: () =>
        AppFlavour.appInUse == AppInUse.e ? widget.miniPlayerController.setShowInTimeline(value: false)
            : widget.miniPlayerController.goToMusicPlayerHome(),
            icon: const Icon(Icons.arrow_forward_ios)
        ) : Hero(tag: AppConstants.currentArtwork,
          child: NeomImageCard(
            elevation: 10,
            boxDimension: widget.useDense ? 40.0 : 50.0,
            localImage: widget.item?.artUri?.toString().startsWith('file:') ?? false,
            imageUrl: (widget.item?.artUri?.toString().startsWith('file:') ?? false
                ? widget.item?.artUri?.toFilePath() : widget.item?.artUri?.toString()) ?? AppFlavour.getAppLogoUrl(),
          ),
        )
        ) : widget.miniPlayerController.audioHandler != null
            ? ControlButtons(widget.miniPlayerController.audioHandler!, miniplayer: true,
          buttons: widget.miniPlayerController.source != AppMediaSource.spotify ?
            (widget.isLocalImage ? AudioPlayerConstants.defaultControlButtons : widget.preferredMiniButtons)
              : AudioPlayerConstants.defaultSpotifyButtons,
          mediaItem: widget.item,
        ) : SizedBox.shrink(),
      ),
    );
  }
}
