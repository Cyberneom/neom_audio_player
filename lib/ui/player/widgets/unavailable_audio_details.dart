import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/images/neom_image_card.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/domain/model/playable_item.dart';
import 'package:sint/sint.dart';

/// A catalogue detail can exist without an audio source. Keep its metadata
/// independent from the current playback session in that case.
class UnavailableAudioDetails extends StatelessWidget {
  final PlayableItem item;
  final String? message;
  final bool isLoading;
  final VoidCallback? onRetry;

  const UnavailableAudioDetails({
    super.key,
    required this.item,
    this.message,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.name.trim();
    final artist = item.ownerName.trim();
    var artwork = item.imgUrl.trim();
    var localArtwork = false;
    if (artwork.startsWith('file:')) {
      try {
        artwork = Uri.parse(artwork).toFilePath();
        localArtwork = true;
      } catch (_) {
        artwork = '';
      }
    }
    final description = item.description?.trim() ?? '';

    return Scaffold(
      appBar: SintAppBar(
        showBackButton: true,
        leading: const BackButton(),
        backgroundColor: AppColor.surfaceElevated,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final coverSize = (constraints.maxWidth - 48)
                    .clamp(0.0, 320.0)
                    .toDouble();
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (artwork.isNotEmpty)
                        NeomImageCard(
                          imageUrl: artwork,
                          localImage: localArtwork,
                          boxDimension: coverSize,
                        )
                      else
                        Card(
                          child: SizedBox.square(
                            dimension: coverSize,
                            child: const Icon(Icons.music_note, size: 80),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        title.isEmpty
                            ? AppTranslationConstants.unknown.tr
                            : title,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      if (artist.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          artist,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else
                        Text(
                          message ??
                              CommonTranslationConstants
                                  .noAvailablePreviewUrl
                                  .tr,
                          textAlign: TextAlign.center,
                        ),
                      if (onRetry != null) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: Text(AppTranslationConstants.tryAgain.tr),
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(description, textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
