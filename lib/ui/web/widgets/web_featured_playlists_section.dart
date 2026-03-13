import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../home/audio_player_home_controller.dart';
import '../../home/widgets/collage.dart';
import '../../library/playlist_player_page.dart';

/// "Featured Playlists" horizontal shelf showing top public playlists.
class WebFeaturedPlaylistsSection extends StatelessWidget {
  final Function(Itemlist)? onPlaylistSelected;

  const WebFeaturedPlaylistsSection({Key? key, this.onPlaylistSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SintBuilder<AudioPlayerHomeController>(
      builder: (controller) {
        return Obx(() {
          final playlists = controller.featuredPlaylists;
          if (playlists.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white70, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    AudioPlayerTranslationConstants.featuredPlaylists.tr,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    return _FeaturedPlaylistCard(
                      itemlist: playlists[index],
                      onPlaylistSelected: onPlaylistSelected,
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

class _FeaturedPlaylistCard extends StatefulWidget {
  final Itemlist itemlist;
  final Function(Itemlist)? onPlaylistSelected;

  const _FeaturedPlaylistCard({
    required this.itemlist,
    this.onPlaylistSelected,
  });

  @override
  State<_FeaturedPlaylistCard> createState() => _FeaturedPlaylistCardState();
}

class _FeaturedPlaylistCardState extends State<_FeaturedPlaylistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final itemlist = widget.itemlist;
    final imgUrls = itemlist.getImgUrls();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (widget.onPlaylistSelected != null) {
            widget.onPlaylistSelected!(itemlist);
          } else {
            Navigator.push(context,
              MaterialPageRoute(builder: (context) => PlaylistPlayerPage(itemlist: itemlist)),
            );
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
                              color: AppColor.appBlack,
                              child: const Icon(Icons.library_music, color: Colors.white54, size: 40),
                            ),
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
                itemlist.name.capitalizeFirst,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${itemlist.getTotalItems()} items',
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
