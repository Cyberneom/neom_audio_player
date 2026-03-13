import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/images/neom_image_card.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/external_media_source.dart';

import '../../../data/implementations/player_hive_controller.dart';
import '../../../utils/constants/audio_player_constants.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/mappers/media_item_mapper.dart';
import '../miniplayer_controller.dart';
import 'control_buttons.dart';

class MiniPlayerTile extends StatefulWidget {
  final MediaItem? item;
  final List<String>? preferredMiniButtons;
  final bool useDense;
  final bool isLocalImage;
  final bool isTimeline;
  final MiniPlayerController miniPlayerController ;

  const MiniPlayerTile({
    super.key,
    this.item,
    this.preferredMiniButtons,
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
  List<String> preferredMiniButtons = [];

  @override
  void initState() {
    super.initState();


    if(widget.item != null) {
      if(widget.item!.title != 'null') {
        titleText = widget.item!.title;
      } else if(widget.item!.album != null) {
        titleText = widget.item!.album ?? '';
      }
      subtitleText = widget.item!.artist ?? '';
    }



    if(titleText.contains(' - ')) {
      titleText = TextUtilities.getMediaName(titleText);
      if(subtitleText.isEmpty) {
        subtitleText = TextUtilities.getArtistName(titleText);
      }
    }

    if(!widget.miniPlayerController.isInternal) {
      subtitleText = AudioPlayerTranslationConstants.releasePreview.tr;
      startSubtitleToggle();
    }

    if(widget.preferredMiniButtons != null) {
      preferredMiniButtons = widget.preferredMiniButtons!;
    } else {
      PlayerHiveController().getPreferredMiniButtons().then((miniButtons){
        preferredMiniButtons = miniButtons;
      });
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
        subtitleText = subtitleText == (widget.item?.artist ?? '')
            ? AudioPlayerTranslationConstants.releasePreview.tr
            : widget.item?.artist ?? '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textAlign = widget.isTimeline || widget.item != null ? TextAlign.left : TextAlign.right;

    return Container(
      color: AppColor.surfaceElevated,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: InkWell(
        onTap: () {
          if (widget.item != null && widget.miniPlayerController.isInternal) {
            Sint.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [MediaItemMapper.toAppMediaItem(widget.item!)]);
          }
        },
        child: Row(
          children: [
            // Leading: back button + artwork
            if (!widget.isTimeline)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: () => widget.miniPlayerController.goToTimeline(context),
              ),
            if (widget.item != null || widget.isTimeline)
              Hero(
                tag: 'currentArtwork',
                child: NeomImageCard(
                  elevation: 8,
                  boxDimension: widget.useDense ? 40.0 : 48.0,
                  localImage: widget.item?.artUri?.toString().startsWith('file:') ?? false,
                  imageUrl: (widget.item?.artUri?.toString().startsWith('file:') ?? false
                      ? widget.item?.artUri?.toFilePath() : widget.item?.artUri?.toString()) ?? AppProperties.getAppLogoUrl(),
                ),
              ),
            const SizedBox(width: 12),
            // Title + subtitle
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: widget.item != null || widget.isTimeline
                    ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Text(
                    titleText.isNotEmpty ? titleText
                        : (widget.isTimeline ? AudioPlayerTranslationConstants.lookingForNewMusic.tr
                        : AudioPlayerTranslationConstants.lookingForInspiration.tr),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: textAlign,
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: -0.3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitleText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: textAlign,
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: -0.3,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Trailing: controls or arrow
            if (widget.item == null)
              widget.isTimeline
                  ? IconButton(
                      onPressed: () => widget.miniPlayerController.goToMusicPlayerHome(),
                      icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    )
                  : Hero(
                      tag: AudioPlayerTranslationConstants.currentArtwork,
                      child: NeomImageCard(
                        elevation: 8,
                        boxDimension: widget.useDense ? 40.0 : 48.0,
                        localImage: widget.item?.artUri?.toString().startsWith('file:') ?? false,
                        imageUrl: (widget.item?.artUri?.toString().startsWith('file:') ?? false
                            ? widget.item?.artUri?.toFilePath() : widget.item?.artUri?.toString()) ?? AppProperties.getAppLogoUrl(),
                      ),
                    )
            else if (widget.miniPlayerController.audioHandler != null)
              ControlButtons(
                widget.miniPlayerController.audioHandler!,
                miniPlayer: true,
                buttons: (widget.miniPlayerController.externalSource == null)
                    ? (widget.isLocalImage ? AudioPlayerConstants.defaultControlButtons : preferredMiniButtons)
                    : (widget.miniPlayerController.externalSource == ExternalSource.spotify)
                        ? AudioPlayerConstants.defaultSpotifyButtons
                        : AudioPlayerConstants.defaultControlButtons,
                mediaItem: widget.item,
              ),
          ],
        ),
      ),
    );
  }
}
