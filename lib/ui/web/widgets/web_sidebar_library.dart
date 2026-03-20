import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sint/sint.dart';
import 'package:neom_audio_player/ui/home/audio_player_home_controller.dart';

import '../../../utils/constants/audio_player_translation_constants.dart';
import 'web_create_playlist_dialog.dart';
import 'web_jam_join_dialog.dart';

class WebSidebarLibrary extends StatefulWidget {
  final VoidCallback? onLibraryTap;
  final Function(Itemlist)? onPlaylistSelected;
  final bool collapsed;

  const WebSidebarLibrary({
    Key? key,
    this.onLibraryTap,
    this.onPlaylistSelected,
    this.collapsed = false,
  }) : super(key: key);

  @override
  State<WebSidebarLibrary> createState() => _WebSidebarLibraryState();
}

enum _LibraryFilter { all, playlists, albums, artists }

class _WebSidebarLibraryState extends State<WebSidebarLibrary> {
  _LibraryFilter _filter = _LibraryFilter.all;

  @override
  Widget build(BuildContext context) {
    return SintBuilder<AudioPlayerHomeController>(
      id: 'web_sidebar_library',
      builder: (controller) {
        return Column(
          children: [
            // ─── Header ───
            Padding(
              padding: EdgeInsets.all(widget.collapsed ? 8.0 : 16.0),
              child: widget.collapsed
                  ? Column(
                      children: [
                        Tooltip(
                          message: AppTranslationConstants.playlists.tr,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: widget.onLibraryTap,
                              child: Icon(Icons.library_music_outlined, color: Colors.grey[400], size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Tooltip(
                          message: AudioPlayerTranslationConstants.createNewPlaylist.tr,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => WebCreatePlaylistDialog.show(context),
                              child: const Icon(Icons.add, color: Colors.white70, size: 20),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: widget.onLibraryTap,
                              child: Row(
                                children: [
                                  Icon(Icons.library_music_outlined, color: Colors.grey[400]),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      AppTranslationConstants.playlists.tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: AudioPlayerTranslationConstants.joinJam.tr,
                              waitDuration: const Duration(milliseconds: 400),
                              child: IconButton(
                                icon: const Icon(Icons.podcasts, color: Colors.white70, size: 20),
                                onPressed: () => WebJamJoinDialog.show(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ),
                            Tooltip(
                              message: AudioPlayerTranslationConstants.createNewPlaylist.tr,
                              waitDuration: const Duration(milliseconds: 400),
                              child: IconButton(
                                icon: const Icon(Icons.add, color: Colors.white70, size: 20),
                                onPressed: () => WebCreatePlaylistDialog.show(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // ─── Filter chips (only in expanded mode) ───
            if (!widget.collapsed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _LibraryFilter.values.map((f) {
                      final selected = _filter == f;
                      final label = switch (f) {
                        _LibraryFilter.all => AppTranslationConstants.all.tr,
                        _LibraryFilter.playlists => AppTranslationConstants.playlists.tr,
                        _LibraryFilter.albums => AudioPlayerTranslationConstants.album.tr,
                        _LibraryFilter.artists => AudioPlayerTranslationConstants.artist.tr,
                      };
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: selected ? Colors.black : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],

            // ─── Liked Songs entry ───
            if (!Hive.isBoxOpen(AppHiveBox.favoriteItems.name))
              const SizedBox.shrink()
            else
            ValueListenableBuilder(
              valueListenable: Hive.box(AppHiveBox.favoriteItems.name).listenable(),
              builder: (context, Box favBox, _) {
                final favCount = favBox.length;
                if (favCount == 0) return const SizedBox.shrink();

                return widget.collapsed
                    ? Tooltip(
                        message: AppTranslationConstants.favorites.tr,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _openLikedSongs(controller),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.purple, AppColor.getMain()],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                      )
                    : _LibraryListItem(
                        imgWidget: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.purple, AppColor.getMain()],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                        ),
                        title: AppTranslationConstants.favorites.tr,
                        subtitle: '$favCount ${AudioPlayerTranslationConstants.mediaItems.tr}',
                        onTap: () => _openLikedSongs(controller),
                      );
              },
            ),

            // ─── Playlists list ───
            Expanded(
              child: controller.isLoading.value
                  ? Center(child: CircularProgressIndicator(color: AppColor.getMain()))
                  : Builder(builder: (_) {
                      final lists = _filterLists(controller.myItemLists);
                      if (lists.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              AudioPlayerTranslationConstants.nothingTo.tr,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: lists.length,
                        itemBuilder: (context, index) {
                          final list = lists[index];
                          if (widget.collapsed) {
                            return Tooltip(
                              message: list.name,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => _selectPlaylist(list),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: _buildThumbnail(list.imgUrl, 40),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return _LibraryListItem(
                            imgUrl: list.imgUrl,
                            title: list.name,
                            subtitle: "Playlist \u2022 ${list.ownerName}",
                            onTap: () => _selectPlaylist(list),
                          );
                        },
                      );
                    }),
            ),
          ],
        );
      },
    );
  }

  List<Itemlist> _filterLists(Map<String, Itemlist> allLists) {
    final lists = allLists.values.toList();
    switch (_filter) {
      case _LibraryFilter.all:
        return lists;
      case _LibraryFilter.playlists:
        return lists.where((l) =>
          l.type == ItemlistType.playlist ||
          l.type == ItemlistType.giglist
        ).toList();
      case _LibraryFilter.albums:
        return lists.where((l) =>
          l.type == ItemlistType.album ||
          l.type == ItemlistType.ep ||
          l.type == ItemlistType.single
        ).toList();
      case _LibraryFilter.artists:
        return lists.where((l) =>
          l.type == ItemlistType.podcast ||
          l.type == ItemlistType.radioStation
        ).toList();
    }
  }

  void _selectPlaylist(Itemlist list) {
    if (widget.onPlaylistSelected != null) {
      widget.onPlaylistSelected!(list);
    } else {
      widget.onLibraryTap?.call();
    }
  }

  void _openLikedSongs(AudioPlayerHomeController controller) {
    final favItems = controller.favoriteItems.toList();
    final likedItemlist = Itemlist(
      name: AppTranslationConstants.favorites.tr,
      description: '',
      ownerId: '',
      ownerName: '',
      appMediaItems: favItems,
    );
    widget.onPlaylistSelected?.call(likedItemlist);
  }

  Widget _buildThumbnail(String imgUrl, double size) {
    if (imgUrl.isNotEmpty) {
      return platformNetworkImage(
        imageUrl: imgUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: Container(
          width: size,
          height: size,
          color: AppColor.getMain().withValues(alpha: 0.3),
          child: const Icon(Icons.music_note, color: Colors.white),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      color: AppColor.getMain().withValues(alpha: 0.3),
      child: const Icon(Icons.music_note, color: Colors.white),
    );
  }
}

class _LibraryListItem extends StatefulWidget {
  final String? imgUrl;
  final Widget? imgWidget;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _LibraryListItem({
    this.imgUrl,
    this.imgWidget,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  __LibraryListItemState createState() => __LibraryListItemState();
}

class __LibraryListItemState extends State<_LibraryListItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              widget.imgWidget ?? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: (widget.imgUrl ?? '').isNotEmpty
                    ? platformNetworkImage(
                        imageUrl: widget.imgUrl!,
                        width: 48, height: 48, fit: BoxFit.cover,
                        errorWidget: Container(
                          width: 48, height: 48, color: AppColor.getMain().withValues(alpha: 0.3),
                          child: const Icon(Icons.music_note, color: Colors.white),
                        ),
                      )
                    : Container(
                        width: 48, height: 48, color: AppColor.getMain().withValues(alpha: 0.3),
                        child: const Icon(Icons.music_note, color: Colors.white),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(color: isHovered ? Colors.white : Colors.grey[300], fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
