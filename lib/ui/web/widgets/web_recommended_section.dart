import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:sint/sint.dart';

import '../../../data/implementations/playlist_generator_controller.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../home/widgets/collage.dart';

/// "Made for You" shelf displaying auto-generated recommended playlists.
class WebRecommendedSection extends StatelessWidget {
  final Function(Itemlist)? onPlaylistSelected;

  const WebRecommendedSection({Key? key, this.onPlaylistSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      final controller = Sint.find<PlaylistGeneratorController>();

      return Obx(() {
        final recommendations = controller.cachedRecommendations;
        if (recommendations.isEmpty && !controller.isGenerating) {
          return const SizedBox.shrink();
        }

        if (controller.isGenerating && recommendations.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AudioPlayerTranslationConstants.madeForYou.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: AppColor.getMain(), strokeWidth: 2),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AudioPlayerTranslationConstants.madeForYou.tr,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                if (controller.isGenerating)
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: AppColor.getMain(), strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  return _RecommendedCard(
                    itemlist: recommendations[index],
                    gradientIndex: index,
                    onPlaylistSelected: onPlaylistSelected,
                  );
                },
              ),
            ),
          ],
        );
      });
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

class _RecommendedCard extends StatefulWidget {
  final Itemlist itemlist;
  final int gradientIndex;
  final Function(Itemlist)? onPlaylistSelected;

  const _RecommendedCard({
    required this.itemlist,
    required this.gradientIndex,
    this.onPlaylistSelected,
  });

  @override
  State<_RecommendedCard> createState() => _RecommendedCardState();
}

class _RecommendedCardState extends State<_RecommendedCard> {
  bool _isHovered = false;

  static const _gradients = [
    [Color(0xFF1DB954), Color(0xFF191414)],
    [Color(0xFFE91E63), Color(0xFF191414)],
    [Color(0xFF2196F3), Color(0xFF191414)],
    [Color(0xFFFF9800), Color(0xFF191414)],
    [Color(0xFF9C27B0), Color(0xFF191414)],
    [Color(0xFF00BCD4), Color(0xFF191414)],
    [Color(0xFFFF5722), Color(0xFF191414)],
    [Color(0xFF4CAF50), Color(0xFF191414)],
  ];

  List<Color> get _gradient => _gradients[widget.gradientIndex % _gradients.length];

  @override
  Widget build(BuildContext context) {
    final itemlist = widget.itemlist;
    final imgUrls = itemlist.getImgUrls();
    final totalItems = itemlist.getTotalItems();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (widget.onPlaylistSelected != null) {
            widget.onPlaylistSelected!(itemlist);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          margin: const EdgeInsets.only(right: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovered ? AppColor.surfaceElevated : AppColor.appBlack,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 136,
                      height: 136,
                      child: imgUrls.isNotEmpty
                          ? Collage(
                              borderRadius: 6,
                              imageList: imgUrls,
                              showGrid: true,
                              placeholderImage: AppAssets.audioPlayerCover,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _gradient,
                                ),
                              ),
                              child: const Icon(Icons.auto_awesome, color: Colors.white54, size: 40),
                            ),
                    ),
                  ),
                  // Play button on hover
                  if (_isHovered)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColor.getMain(),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.play_arrow, color: Colors.white),
                          onPressed: () {
                            final items = AppMediaItemMapper.mapItemsFromItemlist(itemlist);
                            if (items.isNotEmpty) {
                              Sint.find<AudioPlayerInvokerService>().init(
                                mediaItems: items,
                                playItem: true,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                itemlist.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$totalItems ${AudioPlayerTranslationConstants.mediaItems.tr}',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
