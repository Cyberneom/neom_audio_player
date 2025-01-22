
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';
import 'package:neom_commons/neom_commons.dart';

import '../../utils/constants/player_translation_constants.dart';
import 'media_player_controller.dart';
import 'widgets/add_to_playlist.dart';
import 'widgets/artwork_widget.dart';
import 'widgets/name_n_controls.dart';

class MediaPlayerPage extends StatelessWidget {

  const MediaPlayerPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GetBuilder<MediaPlayerController>(
      id: AppPageIdConstants.mediaPlayer,
      init: MediaPlayerController(),
      builder: (_) => Obx(() => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColor.main50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColor.main50,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.expand_more_rounded),
            tooltip: PlayerTranslationConstants.back.tr,
            onPressed: () => Navigator.pop(context),
          ),
          actions: (_.appMediaItem.value.id.isNotEmpty) ? [
            if(_.appMediaItem.value.mediaSource != AppMediaSource.internal)
              IconButton(
                icon: const Icon(Icons.playlist_add_rounded),
                tooltip: PlayerTranslationConstants.addToPlaylist.tr,
                iconSize: 35,
                onPressed: () {
                  AddToPlaylist().addToPlaylist(context, _.appMediaItem.value);
                },
              ),
            IconButton(
              icon: const Icon(Icons.lyrics_rounded),
              tooltip: PlayerTranslationConstants.lyrics.tr,
              onPressed: () => _.toggleLyricsCard(),
            ),
            if (!_.isOffline())
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: PlayerTranslationConstants.share.tr,
                onPressed: () {
                   _.sharePopUp();
                },
              ),
          ] : null,
        ),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: _.isLoading.value ? AppCircularProgressIndicator()
              : _.appMediaItem.value.id.isNotEmpty ? Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ArtWorkWidget(
                mediaPlayerController: _,
                cardKey: _.onlineCardKey,
                height: AppTheme.fullHeight(context)*0.425,
                width: AppTheme.fullWidth(context),
                offline: _.isOffline(), getLyricsOnline: _.getLyricsOnline,
              ),
              NameNControls(
                mediaPlayerController: _,
                height: AppTheme.fullHeight(context)*0.45,
                width: AppTheme.fullWidth(context),
                panelController: _.panelController,
                isLoading: _.isLoadingAudio.value,
              ),
            ],
          ) : SizedBox(child: Text(AppTranslationConstants.noAvailablePreviewUrl.tr),),
        ),
      )),
    );
  }
}
