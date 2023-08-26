import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_music_player/ui/widgets/add_playlist.dart';
import 'package:neom_music_player/ui/widgets/custom_physics.dart';
import 'package:neom_music_player/ui/drawer/downloads/data_search.dart';
import 'package:neom_music_player/ui/widgets/empty_screen.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/playlist_head.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/helpers/audio_query.dart';
import 'package:neom_music_player/neom_player_invoke.dart';
import 'package:neom_music_player/ui/drawer/local_music/localplaylists.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';


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
                    '${widget.songs[index].artist?.replaceAll('<unknown>', 'Unknown') ?? PlayerTranslationConstants.unknown.tr} - ${widget.songs[index].album?.replaceAll('<unknown>', 'Unknown') ?? PlayerTranslationConstants.unknown.tr}',
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
                      // if (value == 0) {
                      // showDialog(
                      // context: context,
                      // builder: (BuildContext context) {
                      // final String fileName = _cachedSongs[index].uri!;
                      // final List temp = fileName.split('.');
                      // temp.removeLast();
                      //           final String songName = temp.join('.');
                      //           final controller =
                      //               TextEditingController(text: songName);
                      //           return AlertDialog(
                      //             content: Column(
                      //               mainAxisSize: MainAxisSize.min,
                      //               children: [
                      //                 Row(
                      //                   children: [
                      //                     Text(
                      //                       'Name',
                      //                       style: TextStyle(
                      //                           color: Theme.of(context).accentColor),
                      //                     ),
                      //                   ],
                      //                 ),
                      //                 const SizedBox(
                      //                   height: 10,
                      //                 ),
                      //                 TextField(
                      //                     autofocus: true,
                      //                     controller: controller,
                      //                     onSubmitted: (value) async {
                      //                       try {
                      //                         Navigator.pop(context);
                      //                         String newName = _cachedSongs[index]
                      //                                 ['id']
                      //                             .toString()
                      //                             .replaceFirst(songName, value);

                      //                         while (await File(newName).exists()) {
                      //                           newName = newName.replaceFirst(
                      //                               value, '$value (1)');
                      //                         }

                      //                         File(_cachedSongs[index]['id']
                      //                                 .toString())
                      //                             .rename(newName);
                      //                         _cachedSongs[index]['id'] = newName;
                      //                         ShowSnackBar().showSnackBar(
                      //                           context,
                      //                           'Renamed to ${_cachedSongs[index]['id'].split('/').last}',
                      //                         );
                      //                       } catch (e) {
                      //                         ShowSnackBar().showSnackBar(
                      //                           context,
                      //                           'Failed to Rename ${_cachedSongs[index]['id'].split('/').last}',
                      //                         );
                      //                       }
                      //                       setState(() {});
                      //                     }),
                      //               ],
                      //             ),
                      //             actions: [
                      //               TextButton(
                      //                 style: TextButton.styleFrom(
                      //                   primary: Theme.of(context).brightness ==
                      //                           Brightness.dark
                      //                       ? Colors.white
                      //                       : Colors.grey[700],
                      //                   //       backgroundColor: Theme.of(context).accentColor,
                      //                 ),
                      //                 onPressed: () {
                      //                   Navigator.pop(context);
                      //                 },
                      //                 child: const Text(
                      //                   'Cancel',
                      //                 ),
                      //               ),
                      //               TextButton(
                      //                 style: TextButton.styleFrom(
                      //                   primary: Colors.white,
                      //                   backgroundColor:
                      //                       Theme.of(context).accentColor,
                      //                 ),
                      //                 onPressed: () async {
                      //                   try {
                      //                     Navigator.pop(context);
                      //                     String newName = _cachedSongs[index]['id']
                      //                         .toString()
                      //                         .replaceFirst(
                      //                             songName, controller.text);

                      //                     while (await File(newName).exists()) {
                      //                       newName = newName.replaceFirst(
                      //                           controller.text,
                      //                           '${controller.text} (1)');
                      //                     }

                      //                     File(_cachedSongs[index]['id'].toString())
                      //                         .rename(newName);
                      //                     _cachedSongs[index]['id'] = newName;
                      //                     ShowSnackBar().showSnackBar(
                      //                       context,
                      //                       'Renamed to ${_cachedSongs[index]['id'].split('/').last}',
                      //                     );
                      //                   } catch (e) {
                      //                     ShowSnackBar().showSnackBar(
                      //                       context,
                      //                       'Failed to Rename ${_cachedSongs[index]['id'].split('/').last}',
                      //                     );
                      //                   }
                      //                   setState(() {});
                      //                 },
                      //                 child: const Text(
                      //                   'Ok',
                      //                   style: TextStyle(color: Colors.white),
                      //                 ),
                      //               ),
                      //               const SizedBox(
                      //                 width: 5,
                      //               ),
                      //             ],
                      //           );
                      //         },
                      //       );
                      //     }
                      //     if (value == 1) {
                      //       showDialog(
                      //         context: context,
                      //         builder: (BuildContext context) {
                      //           Uint8List? _imageByte =
                      //               _cachedSongs[index]['image'] as Uint8List?;
                      //           String _imagePath = '';
                      //           final _titlecontroller = TextEditingController(
                      //               text: _cachedSongs[index]['title'].toString());
                      //           final _albumcontroller = TextEditingController(
                      //               text: _cachedSongs[index]['album'].toString());
                      //           final _artistcontroller = TextEditingController(
                      //               text: _cachedSongs[index]['artist'].toString());
                      //           final _albumArtistController = TextEditingController(
                      //               text: _cachedSongs[index]['albumArtist']
                      //                   .toString());
                      //           final _genrecontroller = TextEditingController(
                      //               text: _cachedSongs[index]['genre'].toString());
                      //           final _yearcontroller = TextEditingController(
                      //               text: _cachedSongs[index]['year'].toString());
                      //           final tagger = Audiotagger();
                      //           return AlertDialog(
                      //             content: SizedBox(
                      //               height: 400,
                      //               width: 300,
                      //               child: SingleChildScrollView(
                      //                 physics: const BouncingScrollPhysics(),
                      //                 child: Column(
                      //                   mainAxisSize: MainAxisSize.min,
                      //                   children: [
                      //                     GestureDetector(
                      //                       onTap: () async {
                      //                         final String filePath = await Picker()
                      //                             .selectFile(
                      //                                 context,
                      //                                 ['png', 'jpg', 'jpeg'],
                      //                                 'Pick Image');
                      //                         if (filePath != '') {
                      //                           _imagePath = filePath;
                      //                           final Uri myUri = Uri.parse(filePath);
                      //                           final Uint8List imageBytes =
                      //                               await File.fromUri(myUri)
                      //                                   .readAsBytes();
                      //                           _imageByte = imageBytes;
                      //                           final Tag tag = Tag(
                      //                             artwork: _imagePath,
                      //                           );
                      //                           try {
                      //                             await [
                      //                               Permission.manageExternalStorage,
                      //                             ].request();
                      //                             await tagger.writeTags(
                      //                               path: _cachedSongs[index]['id']
                      //                                   .toString(),
                      //                               tag: tag,
                      //                             );
                      //                           } catch (e) {
                      //                             await tagger.writeTags(
                      //                               path: _cachedSongs[index]['id']
                      //                                   .toString(),
                      //                               tag: tag,
                      //                             );
                      //                           }
                      //                         }
                      //                       },
                      //                       child: Card(
                      //                         elevation: 5,
                      //                         shape: RoundedRectangleBorder(
                      //                           borderRadius:
                      //                               BorderRadius.circular(7.0),
                      //                         ),
                      //                         clipBehavior: Clip.antiAlias,
                      //                         child: SizedBox(
                      //                           height: MediaQuery.of(context)
                      //                                   .size
                      //                                   .width /
                      //                               2,
                      //                           width: MediaQuery.of(context)
                      //                                   .size
                      //                                   .width /
                      //                               2,
                      //                           child: _imageByte == null
                      //                               ? const Image(
                      //                                   fit: BoxFit.cover,
                      //                                   image: AssetImage(
                      //                                       AppAssets.musicPlayerCover),
                      //                                 )
                      //                               : Image(
                      //                                   fit: BoxFit.cover,
                      //                                   image:
                      //                                       MemoryImage(_imageByte!)),
                      //                         ),
                      //                       ),
                      //                     ),
                      //                     const SizedBox(height: 20.0),
                      //                     Row(
                      //                       children: [
                      //                         Text(
                      //                           'Title',
                      //                           style: TextStyle(
                      //                               color: Theme.of(context)
                      //                                   .accentColor),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                     TextField(
                      //                         autofocus: true,
                      //                         controller: _titlecontroller,
                      //                         onSubmitted: (value) {}),
                      //                     const SizedBox(
                      //                       height: 30,
                      //                     ),
                      //                     Row(
                      //                       children: [
                      //                         Text(
                      //                           'Artist',
                      //                           style: TextStyle(
                      //                               color: Theme.of(context)
                      //                                   .accentColor),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                     TextField(
                      //                         autofocus: true,
                      //                         controller: _artistcontroller,
                      //                         onSubmitted: (value) {}),
                      //                     const SizedBox(
                      //                       height: 30,
                      //                     ),
                      //                     Row(
                      //                       children: [
                      //                         Text(
                      //                           'Album Artist',
                      //                           style: TextStyle(
                      //                               color: Theme.of(context)
                      //                                   .accentColor),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                     TextField(
                      //                         autofocus: true,
                      //                         controller: _albumArtistController,
                      //                         onSubmitted: (value) {}),
                      //                     const SizedBox(
                      //                       height: 30,
                      //                     ),
                      //                     Row(
                      //                       children: [
                      //                         Text(
                      //                           'Album',
                      //                           style: TextStyle(
                      //                               color: Theme.of(context)
                      //                                   .accentColor),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                     TextField(
                      //                         autofocus: true,
                      //                         controller: _albumcontroller,
                      //                         onSubmitted: (value) {}),
                      //                     const SizedBox(
                      //                       height: 30,
                      //                     ),
                      //                     Row(
                      //                       children: [
                      //                         Text(
                      //                           'Genre',
                      //                           style: TextStyle(
                      //                               color: Theme.of(context)
                      //                                   .accentColor),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                     TextField(
                      //                         autofocus: true,
                      //                         controller: _genrecontroller,
                      //                         onSubmitted: (value) {}),
                      //                     const SizedBox(
                      //                       height: 30,
                      //                     ),
                      //                     Row(
                      //                       children: [
                      //                         Text(
                      //                           'Year',
                      //                           style: TextStyle(
                      //                               color: Theme.of(context)
                      //                                   .accentColor),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                     TextField(
                      //                         autofocus: true,
                      //                         controller: _yearcontroller,
                      //                         onSubmitted: (value) {}),
                      //                   ],
                      //                 ),
                      //               ),
                      //             ),
                      //             actions: [
                      //               TextButton(
                      //                 style: TextButton.styleFrom(
                      //                   primary: Theme.of(context).brightness ==
                      //                           Brightness.dark
                      //                       ? Colors.white
                      //                       : Colors.grey[700],
                      //                 ),
                      //                 onPressed: () {
                      //                   Navigator.pop(context);
                      //                 },
                      //                 child: const Text('Cancel'),
                      //               ),
                      //               TextButton(
                      //                 style: TextButton.styleFrom(
                      //                   primary: Colors.white,
                      //                   backgroundColor:
                      //                       Theme.of(context).accentColor,
                      //                 ),
                      //                 onPressed: () async {
                      //                   Navigator.pop(context);
                      //                   _cachedSongs[index]['title'] =
                      //                       _titlecontroller.text;
                      //                   _cachedSongs[index]['album'] =
                      //                       _albumcontroller.text;
                      //                   _cachedSongs[index]['artist'] =
                      //                       _artistcontroller.text;
                      //                   _cachedSongs[index]['albumArtist'] =
                      //                       _albumArtistController.text;
                      //                   _cachedSongs[index]['genre'] =
                      //                       _genrecontroller.text;
                      //                   _cachedSongs[index]['year'] =
                      //                       _yearcontroller.text;
                      //                   final tag = Tag(
                      //                     title: _titlecontroller.text,
                      //                     artist: _artistcontroller.text,
                      //                     album: _albumcontroller.text,
                      //                     genre: _genrecontroller.text,
                      //                     year: _yearcontroller.text,
                      //                     albumArtist: _albumArtistController.text,
                      //                   );
                      //                   try {
                      //                     try {
                      //                       await [
                      //                         Permission.manageExternalStorage,
                      //                       ].request();
                      //                       tagger.writeTags(
                      //                         path: _cachedSongs[index]['id']
                      //                             .toString(),
                      //                         tag: tag,
                      //                       );
                      //                     } catch (e) {
                      //                       await tagger.writeTags(
                      //                         path: _cachedSongs[index]['id']
                      //                             .toString(),
                      //                         tag: tag,
                      //                       );
                      //                       ShowSnackBar().showSnackBar(
                      //                         context,
                      //                         'Successfully edited tags',
                      //                       );
                      //                     }
                      //                   } catch (e) {
                      //                     ShowSnackBar().showSnackBar(
                      //                       context,
                      //                       'Failed to edit tags',
                      //                     );
                      //                   }
                      //                 },
                      //                 child: const Text(
                      //                   'Ok',
                      //                   style: TextStyle(color: Colors.white),
                      //                 ),
                      //               ),
                      //               const SizedBox(
                      //                 width: 5,
                      //               ),
                      //             ],
                      //           );
                      //         },
                      //       );
                      //     }
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
                      // PopupMenuItem(
                      //       value: 0,
                      //       child: Row(
                      //         children: const [
                      //           Icon(Icons.edit_rounded),
                      //           const SizedBox(width: 10.0),
                      //           Text('Rename'),
                      //         ],
                      //       ),
                      //     ),
                      //     PopupMenuItem(
                      //       value: 1,
                      //       child: Row(
                      //         children: const [
                      //           Icon(
                      //               // CupertinoIcons.tag
                      //               Icons.local_offer_rounded),
                      //           const SizedBox(width: 10.0),
                      //           Text('Edit Tags'),
                      //         ],
                      //       ),
                      //     ),
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
                    AppUtilities.logger.i("NeomPlayerInvoke for downloaded songs");
                    NeomPlayerInvoke.init(
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

