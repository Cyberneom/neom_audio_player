
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';

import 'package:neom_media_player/utils/constants/player_translation_constants.dart';
import 'audio_player_controller.dart';
import 'widgets/artwork_widget.dart';
import 'widgets/name_n_controls.dart';

class AudioPlayerPage extends StatelessWidget {

  const AudioPlayerPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GetBuilder<AudioPlayerController>(
      id: AppPageIdConstants.mediaPlayer,
      init: AudioPlayerController(),
      tag: AppPageIdConstants.mediaPlayer,
      builder: (_) => Obx(() => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColor.main50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColor.main50,
          centerTitle: true,
          actions: (_.appMediaItem.value.id.isNotEmpty) ? [
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
                isLoading: _.isLoadingAudio.value,
              ),
            ],
          ) : SizedBox(child: Text(AppTranslationConstants.noAvailablePreviewUrl.tr),),
        ),
      )),
    );
  }
}
