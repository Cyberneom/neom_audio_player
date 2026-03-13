import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../home/audio_player_home_controller.dart';

/// "Top 20 Most Played" section with numbered ranking cards.
/// Based on real CaseteSession listening data.
class WebTopPlayedSection extends StatelessWidget {
  const WebTopPlayedSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SintBuilder<AudioPlayerHomeController>(
      builder: (controller) {
        return Obx(() {
          final playlist = controller.topPlayedPlaylist.value;
          if (playlist == null || playlist.getTotalItems() == 0) {
            return const SizedBox.shrink();
          }

          final items = AppMediaItemMapper.mapItemsFromItemlist(playlist);
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded, color: Colors.white70, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    AudioPlayerTranslationConstants.topMostPlayed.tr,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _TopPlayedCard(
                      mediaItem: items[index],
                      rank: index + 1,
                      allItems: items,
                    );
                  },
                ),
              ),
            ],
          );
        });
      },
    );
  }
}

class _TopPlayedCard extends StatefulWidget {
  final AppMediaItem mediaItem;
  final int rank;
  final List<AppMediaItem> allItems;

  const _TopPlayedCard({
    required this.mediaItem,
    required this.rank,
    required this.allItems,
  });

  @override
  State<_TopPlayedCard> createState() => _TopPlayedCardState();
}

class _TopPlayedCardState extends State<_TopPlayedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          final index = widget.rank - 1;
          Sint.find<AudioPlayerInvokerService>().init(
            mediaItems: widget.allItems,
            index: index,
            playItem: true,
          );
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
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: widget.mediaItem.imgUrl.isNotEmpty
                        ? platformNetworkImage(
                            imageUrl: widget.mediaItem.imgUrl,
                            width: 136, height: 136, fit: BoxFit.cover,
                            errorWidget: Container(
                              width: 136, height: 136, color: AppColor.appBlack,
                              child: const Icon(Icons.music_note, color: Colors.white54, size: 40),
                            ),
                          )
                        : Container(
                            width: 136, height: 136, color: AppColor.appBlack,
                            child: const Icon(Icons.music_note, color: Colors.white54, size: 40),
                          ),
                  ),
                  // Rank badge
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.rank <= 3
                            ? AppColor.getMain()
                            : Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${widget.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  // Play button on hover
                  if (_isHovered)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColor.getMain(),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.play_arrow, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.mediaItem.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.mediaItem.ownerName,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
