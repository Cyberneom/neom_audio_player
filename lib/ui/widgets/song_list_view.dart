import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:neom_music_player/domain/entities/url_image_generator.dart';
import 'package:neom_music_player/ui/widgets/bouncy_playlist_header_scroll_view.dart';
import 'package:neom_music_player/ui/widgets/copy_clipboard.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';

class SongsListViewPage extends StatefulWidget {
  final String? imageUrl;
  final String? placeholderImageUrl;
  final String title;
  final String? subtitle;
  final String? secondarySubtitle;
  final Function(int, List)? onTap;
  final Function? onPlay;
  final Function? onShuffle;
  final String? listItemsTitle;
  final EdgeInsetsGeometry? listItemsPadding;
  final List<AppMediaItem> listItems;
  final List<Widget>? actions;
  final List<Widget>? dropDownActions;
  final Future<List> Function()? loadFunction;
  final Future<List> Function()? loadMoreFunction;

  const SongsListViewPage({
    super.key,
    this.imageUrl,
    this.placeholderImageUrl,
    required this.title,
    this.subtitle,
    this.secondarySubtitle,
    this.onTap,
    this.onPlay,
    this.onShuffle,
    this.listItemsTitle,
    this.listItemsPadding,
    this.listItems = const [],
    this.actions,
    this.dropDownActions,
    this.loadFunction,
    this.loadMoreFunction,
  });

  @override
  _SongsListViewPageState createState() => _SongsListViewPageState();
}

class _SongsListViewPageState extends State<SongsListViewPage> {
  int page = 1;
  bool loading = false;
  List<AppMediaItem> itemsList = [];
  bool fetched = false;
  bool isSharePopupShown = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitial();
    if (widget.loadMoreFunction != null) {
      _scrollController.addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
            !loading) {
          page += 1;
          _loadMore();
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Future<void> _loadInitial() async {
    loading = true;
    try {
      if (widget.loadFunction == null) {
        setState(() {
          fetched = true;
          loading = false;
        });
      } else {
        final value = await widget.loadFunction!.call();
        setState(() {
          itemsList = value as List<AppMediaItem>;
          fetched = true;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        fetched = true;
        loading = false;
      });
      AppUtilities.logger.e(
        'Error in song_list_view loadInitial: $e',
      );
    }
  }

  Future<void> _loadMore() async {
    try {
      if (widget.loadMoreFunction != null) {
        loading = true;
        final value = await widget.loadMoreFunction!.call();
        setState(() {
          itemsList = value as List<AppMediaItem>;
          fetched = true;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        fetched = true;
        loading = false;
      });
      AppUtilities.logger.e(
        'Error in song_list_view loadMore: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: AppColor.main75,
        body: !fetched
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : BouncyPlaylistHeaderScrollView(
                scrollController: _scrollController,
                actions: widget.actions,
                title: widget.title,
                subtitle: widget.subtitle,
                secondarySubtitle: widget.secondarySubtitle,
                onPlayTap: widget.onPlay,
                onShuffleTap: widget.onShuffle,
                placeholderImage: widget.placeholderImageUrl ?? AppAssets.musicPlayerCover,
                imageUrl: widget.imageUrl != null ? UrlImageGetter([widget.imageUrl]).mediumQuality : AppFlavour.getAppLogoUrl(),
                sliverList: SliverList(
                  delegate: SliverChildListDelegate([
                    if (itemsList.isNotEmpty && widget.listItemsTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20.0,
                          top: 5.0,
                          bottom: 5.0,
                        ),
                        child: Text(
                          widget.listItemsTitle!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ...itemsList.map((entry) {
                      return ListTile(
                        contentPadding: widget.listItemsPadding ?? const EdgeInsets.symmetric(horizontal: 20.0),
                        title: Text(entry.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: entry.description != null ? Text(entry.description!,
                          overflow: TextOverflow.ellipsis,) : null,
                        leading: imageCard(
                          elevation: 8,
                          imageUrl: entry.imgUrl,
                        ),
                        onLongPress: () {
                          copyToClipboard(
                            context: context,
                            text: entry.name,
                          );
                        },
                        // trailing: Row(
                        //   mainAxisSize: MainAxisSize.min,
                        //   children: [
                        //     DownloadButton(
                        //       data: entry as Map,
                        //       icon: 'download',
                        //     ),
                        //     LikeButton(
                        //       mediaItem: null,
                        //       data: entry.mapData,
                        //     ),
                        //     if (entry.mapData != null)
                        //       SongTileTrailingMenu(data: entry.mapData!),
                        //   ],
                        // ),
                        onTap: () {
                          final idx = itemsList.indexWhere(
                            (element) => element == entry,
                          );
                          widget.onTap?.call(idx, itemsList);
                        },
                      );
                    }),
                  ]),
                ),
              ),
      ),
    );
  }
}
