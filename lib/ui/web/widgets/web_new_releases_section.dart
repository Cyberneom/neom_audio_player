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

/// "New Releases" horizontal shelf showing the latest songs on the platform.
class WebNewReleasesSection extends StatelessWidget {
  const WebNewReleasesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SintBuilder<AudioPlayerHomeController>(
      builder: (controller) {
        return Obx(() {
          final playlist = controller.newReleasesPlaylist.value;
          if (playlist == null || playlist.getTotalItems() == 0) {
            return const SizedBox.shrink();
          }

          final items = AppMediaItemMapper.mapItemsFromItemlist(playlist);
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AudioPlayerTranslationConstants.newReleases.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _NewReleaseCard(
                      mediaItem: items[index],
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

class _NewReleaseCard extends StatefulWidget {
  final AppMediaItem mediaItem;
  final List<AppMediaItem> allItems;

  const _NewReleaseCard({
    required this.mediaItem,
    required this.allItems,
  });

  @override
  State<_NewReleaseCard> createState() => _NewReleaseCardState();
}

class _NewReleaseCardState extends State<_NewReleaseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          final index = widget.allItems.indexOf(widget.mediaItem);
          Sint.find<AudioPlayerInvokerService>().init(
            mediaItems: widget.allItems,
            index: index >= 0 ? index : 0,
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
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: widget.mediaItem.imgUrl.isNotEmpty
                        ? platformNetworkImage(
                            imageUrl: widget.mediaItem.imgUrl,
                            width: 136, height: 136, fit: BoxFit.cover,
                            errorWidget: Container(
                              width: 136, height: 136, color: AppColor.appBlack,
                              child: const Icon(Icons.album, color: Colors.white54, size: 40),
                            ),
                          )
                        : Container(
                            width: 136, height: 136, color: AppColor.appBlack,
                            child: const Icon(Icons.album, color: Colors.white54, size: 40),
                          ),
                  ),
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
