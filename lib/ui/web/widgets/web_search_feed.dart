import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:sint/sint.dart';

import '../../../utils/audio_player_utilities.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../home/audio_player_home_controller.dart';
import 'web_context_menu.dart';

class WebSearchFeed extends StatefulWidget {
  final Function(Itemlist)? onPlaylistSelected;

  const WebSearchFeed({super.key, this.onPlaylistSelected});

  @override
  State<WebSearchFeed> createState() => _WebSearchFeedState();
}

class _WebSearchFeedState extends State<WebSearchFeed> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  Map<String, AppReleaseItem> _allItems = {};
  List<AppMediaItem> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isEmpty) {
        setState(() {
          _results = [];
          _hasSearched = false;
        });
        return;
      }
      _fetchResults(query.trim());
    });
  }

  Future<void> _fetchResults(String query) async {
    setState(() => _isSearching = true);

    if (_allItems.isEmpty) {
      _allItems = await AppReleaseItemFirestore().retrieveAll();
    }

    final lowerQuery = query.toLowerCase();
    final matches = <AppMediaItem>[];
    for (final item in _allItems.values) {
      if (item.name.toLowerCase().contains(lowerQuery) ||
          item.ownerName.toLowerCase().contains(lowerQuery)) {
        matches.add(AppMediaItemMapper.fromAppReleaseItem(item));
      }
    }

    if (mounted) {
      setState(() {
        _results = matches;
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Search bar ───
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: AppTranslationConstants.search.tr,
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // ─── Content ───
        Expanded(
          child: _isSearching
              ? Center(child: CircularProgressIndicator(color: AppColor.getMain()))
              : _hasSearched
                  ? _buildSearchResults()
                  : _buildBrowseCategories(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              AudioPlayerTranslationConstants.resultsNotFound.tr,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_results.length} ${AudioPlayerTranslationConstants.mediaItems.tr}',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.75,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              return _WebSearchCard(
                mediaItem: _results[index],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBrowseCategories() {
    return SintBuilder<AudioPlayerHomeController>(
      id: 'web_search_browse',
      builder: (controller) {
        final lists = controller.releaseItemlists.values.toList();
        final categorized = AudioPlayerUtilities.categorizePlaylistsByTags(lists);

        if (categorized.isEmpty && lists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_rounded, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  AudioPlayerTranslationConstants.startSearch.tr,
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              ],
            ),
          );
        }

        final categoryEntries = categorized.entries.toList();
        final colors = [
          Colors.red, Colors.blue, Colors.green, Colors.purple,
          Colors.orange, Colors.teal, Colors.indigo, Colors.pink,
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AudioPlayerTranslationConstants.topCharts.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categoryEntries.length,
                itemBuilder: (context, index) {
                  final entry = categoryEntries[index];
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (entry.value.isNotEmpty && widget.onPlaylistSelected != null) {
                          widget.onPlaylistSelected!(entry.value.first);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          entry.key.tr.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Square card for search results.
class _WebSearchCard extends StatefulWidget {
  final AppMediaItem mediaItem;
  const _WebSearchCard({required this.mediaItem});

  @override
  State<_WebSearchCard> createState() => _WebSearchCardState();
}

class _WebSearchCardState extends State<_WebSearchCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Sint.find<AudioPlayerInvokerService>().updateNowPlaying(
            items: [widget.mediaItem],
            index: 0,
          );
        },
        onSecondaryTapDown: (details) {
          WebContextMenu.show(context, details.globalPosition, widget.mediaItem);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovered ? AppColor.surfaceElevated : AppColor.appBlack,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: widget.mediaItem.imgUrl.isNotEmpty
                            ? platformNetworkImage(
                                imageUrl: widget.mediaItem.imgUrl,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: AppColor.appBlack,
                                  child: const Icon(Icons.music_note, color: Colors.white, size: 40),
                                ),
                              )
                            : Container(
                                color: AppColor.appBlack,
                                child: const Icon(Icons.music_note, color: Colors.white, size: 40),
                              ),
                      ),
                    ),
                    if (_isHovered)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColor.getMain(),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(100),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.mediaItem.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.mediaItem.ownerName,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
