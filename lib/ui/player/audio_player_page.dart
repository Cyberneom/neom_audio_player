
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_sound/neom_sound.dart';

import '../../utils/constants/audio_player_translation_constants.dart';
import 'audio_player_controller.dart';
import 'widgets/artwork_widget.dart';
import 'widgets/name_n_controls.dart';
import 'widgets/player_options_menu.dart';

class AudioPlayerPage extends StatelessWidget {

  const AudioPlayerPage({super.key});

  void _showEqualizerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Equalizer widget from neom_sound
                const Expanded(
                  child: EqualizerWidget(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SintBuilder<AudioPlayerController>(
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
            // Equalizer quick access
            IconButton(
              icon: const Icon(Icons.equalizer),
              tooltip: AudioPlayerTranslationConstants.equalizer.tr,
              onPressed: () => _showEqualizerSheet(context),
            ),
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
            // 3-dot menu with more options
            PlayerOptionsMenu(controller: controller),
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
