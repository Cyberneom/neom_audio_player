
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';

import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';

import '../../utils/constants/audio_player_translation_constants.dart';
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
      builder: (controller) => Obx(() => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppFlavour.getBackgroundColor(),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColor.appBar,
          centerTitle: true,
          actions: (controller.mediaItem.value?.id.isNotEmpty ?? false) ? [
            IconButton(
              icon: const Icon(Icons.lyrics_rounded),
              tooltip: AudioPlayerTranslationConstants.lyrics.tr,
              onPressed: () => controller.toggleLyricsCard(),
            ),
            if (!controller.isOffline())
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: AppTranslationConstants.toShare.tr,
                onPressed: () {
                  AuthGuard.protect(context, () {
                    controller.sharePopUp();
                  });
                },
              ),
          ] : null,
        ),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: controller.isLoading.value ? AppCircularProgressIndicator()
              : controller.isValidItem ? Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ArtWorkWidget(
                mediaPlayerController: controller,
                cardKey: controller.onlineCardKey,
                height: AppTheme.fullHeight(context)*0.4,
                width: AppTheme.fullWidth(context),
                offline: controller.isOffline(), getLyricsOnline: controller.getLyricsOnline,
              ),
              NameNControls(
                audioPlayerController: controller,
                height: AppTheme.fullHeight(context)*0.49,
                width: AppTheme.fullWidth(context),
                isLoading: controller.isLoadingAudio.value,
              ),
            ],
          ) : SizedBox(child: Text(CommonTranslationConstants.noAvailablePreviewUrl.tr),),
        ),
      )),
    );
  }
}
