import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:sint/sint.dart';

import '../../home/audio_player_home_controller.dart';
import '../../home/widgets/collage.dart';
import '../../library/playlist_player_page.dart';
import '../../../utils/audio_player_utilities.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import 'web_context_menu.dart';
import 'web_featured_playlists_section.dart';
import 'web_new_releases_section.dart';
import 'web_radio_section.dart';
import 'web_recommended_section.dart';
import 'web_top_played_section.dart';
import 'web_upgrade_banner.dart';

class WebMainFeed extends StatelessWidget {
  final Function(Itemlist)? onPlaylistSelected;

  const WebMainFeed({Key? key, this.onPlaylistSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SintBuilder<AudioPlayerHomeController>(
      id: AppPageIdConstants.audioPlayerHome,
      init: AudioPlayerHomeController(),
      builder: (controller) {
        return Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator(color: AppColor.getMain()));
          }

          final bool isEmpty = controller.recentList.isEmpty
              && controller.favoriteItems.isEmpty
              && controller.releaseItemlists.isEmpty
              && controller.publicItemlists.isEmpty;

          if (isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note, size: 64, color: Colors.white.withAlpha(60)),
                  const SizedBox(height: 16),
                  Text(
                    AppFlavour.getAudioPlayerHomeTitle(),
                    style: TextStyle(fontSize: 20, color: Colors.white.withAlpha(150)),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppFlavour.getAudioPlayerHomeTitle(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),

                // ─── Listen Again (Greeting Grid) ───
                if (controller.recentList.isNotEmpty) ...[
                  Text(
                    AudioPlayerTranslationConstants.listenAgain.tr,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  _buildGreetingGrid(controller.recentList.values.toList()),
                  const SizedBox(height: 32),
                ],

                // ─── New Releases ───
                const WebNewReleasesSection(),
                const SizedBox(height: 32),

                // ─── Radio Section ───
                const WebRadioSection(),
                const SizedBox(height: 32),

                // ─── Recommended Playlists (Made for You) ───
                WebRecommendedSection(onPlaylistSelected: onPlaylistSelected),
                const SizedBox(height: 32),

                // ─── Top 20 Most Played ───
                const WebTopPlayedSection(),
                const SizedBox(height: 32),

                // ─── Featured Playlists ───
                WebFeaturedPlaylistsSection(onPlaylistSelected: onPlaylistSelected),
                const SizedBox(height: 32),

                // ─── Upgrade Banner (CASETE) ───
                WebUpgradeBanner(
                  message: 'upgradeToSupport'.tr,
                ),

                // ─── Favorite items ───
                if (controller.favoriteItems.isNotEmpty) ...[
                  _buildMediaShelf(
                    AppTranslationConstants.favorites.tr,
                    controller.favoriteItems.toList(),
                  ),
                  const SizedBox(height: 32),
                ],

                // ─── Release itemlists (categorized playlists) ───
                if (controller.releaseItemlists.isNotEmpty) ...[
                  _buildCategorizedItemlists(context, controller.releaseItemlists.values.toList()),
                  const SizedBox(height: 32),
                ],

                // ─── Public itemlists ───
                if (controller.publicItemlists.isNotEmpty)
                  ...controller.publicItemlists.values
                      .where((list) => list.id.isNotEmpty && list.getTotalItems() > 0)
                      .map((list) => Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: _buildItemlistShelf(context, list.name.capitalizeFirst, [list]),
                  )),
              ],
            ),
          );
        });
      },
    );
  }

  // ─── Greeting Grid (3x2 compact cards) ─────────────────────────────────────

  Widget _buildGreetingGrid(List<AppMediaItem> recentItems) {
    final items = recentItems.take(6).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _WebGreetingCard(mediaItem: items[index], allItems: items, index: index),
    );
  }

  // ─── Media Shelf ───────────────────────────────────────────────────────────

  Widget _buildMediaShelf(String title, List<AppMediaItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _WebSquareCard(mediaItem: item);
            },
          ),
        ),
      ],
    );
  }

  // ─── Categorized Itemlists ─────────────────────────────────────────────────

  Widget _buildCategorizedItemlists(BuildContext context, List<Itemlist> lists) {
    Map<String, List<Itemlist>> categorized = AudioPlayerUtilities.categorizePlaylistsByTags(lists);

    if (categorized.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categorized.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: _buildItemlistShelf(context, entry.key.tr.toUpperCase(), entry.value),
          );
        }).toList(),
      );
    } else {
      return _buildItemlistShelf(context, CommonTranslationConstants.recentReleases.tr, lists);
    }
  }

  // ─── Itemlist Shelf ────────────────────────────────────────────────────────

  Widget _buildItemlistShelf(BuildContext context, String title, List<Itemlist> lists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final itemlist = lists[index];
              return _WebItemlistCard(
                itemlist: itemlist,
                onPlaylistSelected: onPlaylistSelected,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Greeting Card (compact rectangular card for quick access)
// ═══════════════════════════════════════════════════════════════════════════════

class _WebGreetingCard extends StatefulWidget {
  final AppMediaItem mediaItem;
  final List<AppMediaItem> allItems;
  final int index;
  const _WebGreetingCard({required this.mediaItem, required this.allItems, required this.index});

  @override
  State<_WebGreetingCard> createState() => _WebGreetingCardState();
}

class _WebGreetingCardState extends State<_WebGreetingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Sint.find<AudioPlayerInvokerService>().init(
            mediaItems: widget.allItems,
            index: widget.index,
            playItem: true,
          );
        },
        onSecondaryTapDown: (details) {
          WebContextMenu.show(context, details.globalPosition, widget.mediaItem);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
                child: widget.mediaItem.imgUrl.isNotEmpty
                    ? platformNetworkImage(
                        imageUrl: widget.mediaItem.imgUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          width: 64, height: 64,
                          color: AppColor.getMain().withOpacity(0.3),
                          child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
                        ),
                      )
                    : Container(
                        width: 64, height: 64,
                        color: AppColor.getMain().withOpacity(0.3),
                        child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
                      ),
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Text(
                  widget.mediaItem.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Play button on hover
              if (_isHovered)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColor.getMain(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Square Card (individual songs) — with right-click context menu
// ═══════════════════════════════════════════════════════════════════════════════

class _WebSquareCard extends StatefulWidget {
  final AppMediaItem mediaItem;

  const _WebSquareCard({Key? key, required this.mediaItem}) : super(key: key);

  @override
  _WebSquareCardState createState() => _WebSquareCardState();
}

class _WebSquareCardState extends State<_WebSquareCard> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          WebContextMenu.show(context, details.globalPosition, widget.mediaItem);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          margin: const EdgeInsets.only(right: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering ? AppColor.surfaceElevated : AppColor.appBlack,
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
                              child: const Icon(Icons.music_note, color: Colors.white, size: 40),
                            ),
                          )
                        : Container(
                            width: 136, height: 136, color: AppColor.appBlack,
                            child: const Icon(Icons.music_note, color: Colors.white, size: 40),
                          ),
                  ),
                  if (isHovering)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColor.getMain(),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.play_arrow, color: Colors.white),
                          onPressed: () {
                            Sint.find<AudioPlayerInvokerService>().updateNowPlaying(items: [widget.mediaItem], index: 0);
                          },
                        ),
                      ),
                    )
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
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Itemlist Card (playlists) — with hover play button + inline navigation
// ═══════════════════════════════════════════════════════════════════════════════

class _WebItemlistCard extends StatefulWidget {
  final Itemlist itemlist;
  final Function(Itemlist)? onPlaylistSelected;

  const _WebItemlistCard({
    Key? key,
    required this.itemlist,
    this.onPlaylistSelected,
  }) : super(key: key);

  @override
  _WebItemlistCardState createState() => _WebItemlistCardState();
}

class _WebItemlistCardState extends State<_WebItemlistCard> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final itemlist = widget.itemlist;
    final imgUrls = itemlist.getImgUrls();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
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
            color: isHovering ? AppColor.surfaceElevated : AppColor.appBlack,
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
                              child: const Icon(Icons.library_music, color: Colors.white, size: 40),
                            ),
                    ),
                  ),
                  // Play button on hover
                  if (isHovering)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColor.getMain(),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 10, offset: const Offset(0, 4))
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
