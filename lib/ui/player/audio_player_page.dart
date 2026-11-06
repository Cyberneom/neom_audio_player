import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:neom_core/domain/model/audio_ad_break_spec.dart';
import 'package:neom_core/domain/model/playable_item.dart';
import 'package:neom_core/utils/enums/ad_placement.dart';
import 'package:neom_core/utils/neom_ad_registry.dart';
import 'package:neom_sound/neom_sound.dart';

import '../../neom_audio_handler.dart';
import '../../utils/audio_item_source_availability.dart';
import '../../utils/constants/audio_player_translation_constants.dart';
import '../web/widgets/web_now_playing_full.dart';
import '../web/web_audio_item_page.dart';
import 'audio_player_controller.dart';
import 'widgets/artwork_widget.dart';
import 'widgets/name_n_controls.dart';
import 'widgets/player_options_menu.dart';
import 'widgets/unavailable_audio_details.dart';

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                const Expanded(child: EqualizerWidget()),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context) == null
        ? Sint.arguments
        : context.arguments;
    final requestedItem = arguments is List && arguments.isNotEmpty
        ? arguments.first
        : null;
    if (requestedItem is PlayableItem && hasNoAudioSource(requestedItem)) {
      return UnavailableAudioDetails(item: requestedItem);
    }

    // On web, show the Spotify-style full-screen player instead of mobile layout
    if (kIsWeb) {
      if (requestedItem is PlayableItem) {
        return WebAudioItemPage(
          key: ValueKey(
            '${requestedItem.id}:${audioItemSource(requestedItem)}',
          ),
          item: requestedItem,
          playItem:
              arguments is! List ||
              arguments.length < 2 ||
              arguments[1] != false,
        );
      }
      return WebNowPlayingFull(onClose: () => Navigator.of(context).maybePop());
    }

    return SintBuilder<AudioPlayerController>(
      id: AppPageIdConstants.mediaPlayer,
      init: AudioPlayerController(),
      tag: AppPageIdConstants.mediaPlayer,
      builder: (controller) => Obx(
        () => Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppFlavour.getBackgroundColor(),
          appBar: SintAppBar(
            elevation: 0,
            backgroundColor: AppColor.surfaceElevated,
            centerTitle: true,
            actions: (controller.mediaItem.value?.id.isNotEmpty ?? false)
                ? [
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
                  ]
                : null,
          ),
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: controller.isLoading.value
                ? AppCircularProgressIndicator()
                : NeomAudioHandler.isAdMediaItem(controller.mediaItem.value) &&
                      NeomAdRegistry.buildAudioCompanionCardFn != null
                ? _buildAdCompanionBody(context, controller)
                : controller.isValidItem
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: ArtWorkWidget(
                          mediaPlayerController: controller,
                          cardKey: controller.onlineCardKey,
                          height: AppTheme.fullHeight(context) *
                              (NeomAdRegistry.shouldShowExternalAds &&
                                      NeomAdRegistry.buildAdSlotFn != null
                                  ? 0.35
                                  : 0.4),
                          width: AppTheme.fullWidth(context),
                          offline: controller.isOffline(),
                          getLyricsOnline: controller.getLyricsOnline,
                        ),
                      ),
                      Flexible(
                        child: NameNControls(
                          audioPlayerController: controller,
                          height: AppTheme.fullHeight(context) *
                              (NeomAdRegistry.shouldShowExternalAds &&
                                      NeomAdRegistry.buildAdSlotFn != null
                                  ? 0.44
                                  : 0.49),
                          width: AppTheme.fullWidth(context),
                          isLoading: controller.isLoadingAudio.value,
                        ),
                      ),
                      if (NeomAdRegistry.shouldShowExternalAds &&
                          NeomAdRegistry.buildAdSlotFn != null)
                        SafeArea(
                          top: false,
                          child: NeomAdRegistry.buildAdSlotFn!(
                            placement: AdPlacement.playerBanner,
                            contextKeywords: <String>[
                              if (controller.mediaItemTitle.value.isNotEmpty)
                                controller.mediaItemTitle.value,
                              if (controller.mediaItemArtist.value.isNotEmpty)
                                controller.mediaItemArtist.value,
                            ],
                          ),
                        ),
                    ],
                  )
                : SizedBox(
                    child: Text(
                      CommonTranslationConstants.noAvailablePreviewUrl.tr,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdCompanionBody(
    BuildContext context,
    AudioPlayerController controller,
  ) {
    final spec = AudioAdBreakSpec.fromMediaItemExtras(
      controller.mediaItem.value?.extras,
    );
    if (spec == null || NeomAdRegistry.buildAudioCompanionCardFn == null) {
      return const SizedBox.shrink();
    }
    final Stream<Duration>? posStream =
        controller.audioHandler?.player?.positionStream is Stream<Duration>
        ? controller.audioHandler.player.positionStream as Stream<Duration>
        : null;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: StreamBuilder<Duration>(
            stream: posStream,
            builder: (context, snap) {
              final position = snap.data ?? Duration.zero;
              final duration =
                  controller.mediaItem.value?.duration ??
                  Duration(seconds: spec.durationSeconds);
              return NeomAdRegistry.buildAudioCompanionCardFn!(
                spec: spec,
                position: position,
                duration: duration,
                onSkip: () => controller.audioHandler?.skipToNext(),
              );
            },
          ),
        ),
      ),
    );
  }
}
