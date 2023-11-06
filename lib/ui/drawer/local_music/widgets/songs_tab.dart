import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../../neom_player_invoker.dart';
import '../../../../utils/constants/player_translation_constants.dart';
import '../../../../utils/helpers/audio_query.dart';
import '../../../widgets/add_to_off_playlist.dart';
import '../../../widgets/empty_screen.dart';
import '../../../widgets/playlist_head.dart';
import '../../../widgets/snackbar.dart';

class SongsTab extends StatefulWidget {
  final List<AppMediaItem> songs;
  final int? playlistId;
  final String? playlistName;
  final String tempPath;
  final Function(SongModel) deleteSong;
  const SongsTab({
    super.key,
    required this.songs,
    required this.tempPath,
    required this.deleteSong,
    this.playlistId,
    this.playlistName,
  });

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.songs.isEmpty ? emptyScreen(
      context, 3,
      PlayerTranslationConstants.nothingTo.tr, 15.0,
      PlayerTranslationConstants.showHere.tr, 45,
      PlayerTranslationConstants.downloadSomething.tr, 23.0,
    ) : Column(
      children: [
        PlaylistHead(
          songsList: widget.songs,
          offline: true,
          fromDownloads: false,
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thickness: 8,
            thumbVisibility: true,
            radius: const Radius.circular(10),
            interactive: true,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 10),
              controller: _scrollController,
              shrinkWrap: true,
              itemExtent: 70.0,
              itemCount: widget.songs.length,
              itemBuilder: (context, index) {
                AppMediaItem item = widget.songs.elementAt(index);
                return ListTile(
                  leading: OfflineAudioQuery.offlineArtworkWidget(
                    id: int.parse(widget.songs[index].id),
                    type: ArtworkType.AUDIO,
                    tempPath: widget.tempPath,
                    fileName: widget.songs[index].name,
                  ),
                  title: Text(
                    widget.songs[index].name.isNotEmpty
                        ? widget.songs[index].name
                        : widget.songs[index].album,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${widget.songs[index].artist.replaceAll('<unknown>', 'Unknown')} - ${widget.songs[index].album.replaceAll('<unknown>', 'Unknown')}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.all(Radius.circular(15.0)),
                    ),
                    onSelected: (int? value) async {
                      if (value == 0) {
                        AddToOffPlaylist().addToOffPlaylist(
                          context,
                          widget.songs[index].id as int,
                        );
                      }
                      if (value == 1) {
                        await OfflineAudioQuery().removeFromPlaylist(
                          playlistId: widget.playlistId!,
                          audioId: widget.songs[index].id as int,
                        );
                        ShowSnackBar().showSnackBar(
                          context,
                          '${PlayerTranslationConstants.removedFrom.tr} ${widget.playlistName}',
                        );
                      }
                      if (value == -1) {
                        //TODO VERIFY MAP TO SONG MODEL
                        // await widget.deleteSong(widget.songs[index]);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 0,
                        child: Row(
                          children: [
                            const Icon(Icons.playlist_add_rounded),
                            const SizedBox(width: 10.0),
                            Text(
                              PlayerTranslationConstants.addToPlaylist.tr,
                            ),
                          ],
                        ),
                      ),
                      if (widget.playlistId != null)
                        PopupMenuItem(
                          value: 1,
                          child: Row(
                            children: [
                              const Icon(Icons.delete_rounded),
                              const SizedBox(width: 10.0),
                              Text(PlayerTranslationConstants.remove.tr),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: -1,
                        child: Row(
                          children: [
                            const Icon(Icons.delete_rounded),
                            const SizedBox(width: 10.0),
                            Text(PlayerTranslationConstants.delete.tr),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    AppUtilities.logger.i('NeomPlayerInvoke for downloaded songs');
                    NeomPlayerInvoker.init(
                      appMediaItems: widget.songs,
                      index: index,
                      isOffline: true,
                      recommend: false,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
