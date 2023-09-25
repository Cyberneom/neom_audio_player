/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:get/get.dart';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_music_player/neom_player_invoker.dart';
import 'package:neom_music_player/ui/player/widgets/artwork_widget.dart';
import 'package:neom_music_player/ui/player/widgets/name_n_controls.dart';
import 'package:neom_music_player/utils/helpers/media_item_mapper.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/music_player_theme.dart';
import 'package:neom_music_player/utils/helpers/dominant_color.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:neom_music_player/utils/music_player_utilities.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class MediaPlayerPage extends StatefulWidget {

  AppMediaItem? appMediaItem;
  bool reproduceItem;
  MediaPlayerPage({super.key, this.appMediaItem, this.reproduceItem = true});
  @override
  _MediaPlayerPageState createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {

  final bool getLyricsOnline = Hive.box(AppHiveConstants.settings).get('getLyricsOnline', defaultValue: true) as bool;

  final MusicPlayerTheme currentTheme = MusicPlayerTheme();
  final ValueNotifier<List<Color?>?> gradientColor = ValueNotifier<List<Color?>?>(MusicPlayerTheme().playGradientColor);
  final PanelController _panelController = PanelController();
  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  GlobalKey<FlipCardState> onlineCardKey = GlobalKey<FlipCardState>();

  Duration _time = Duration.zero;

  bool isSharePopupShown = false;

  void updateBackgroundColors(List<Color?> value) {
    gradientColor.value = value;
    return;
  }

  void initState() {
    if(widget.appMediaItem != null) {
      bool alreadyPlaying = audioHandler.currentMediaItem != null && audioHandler.currentMediaItem!.id == widget.appMediaItem!.id;
      if(widget.reproduceItem && !alreadyPlaying) {
        Future.delayed(Duration(milliseconds: 500)).then((value) {
          NeomPlayerInvoker.init(
            appMediaItems: [widget.appMediaItem!],
            index: 0,
          );
          // audioHandler.play();
        });
      }
    }




  }

  @override
  Widget build(BuildContext context) {
    BuildContext? scaffoldContext;
    AppMediaItem? appMediaItem = widget.appMediaItem;

    return Dismissible(
      direction: appMediaItem == null ? DismissDirection.down : DismissDirection.endToStart,
      background: Container(
        height: MediaQuery.of(context).size.width/2,
        width: MediaQuery.of(context).size.width/2,
        color: AppColor.main75,
        child: Image.asset(AppFlavour.getIconPath(),
          fit: BoxFit.fitWidth,),
      ),
      key: const Key('playScreen'),
      onDismissed: (direction) {
        Navigator.pop(context);
      },
      child: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          MediaItem mediaItem;
          if(appMediaItem != null) {
            mediaItem = MediaItemMapper.appMediaItemToMediaItem(appMediaItem: appMediaItem);
          } else if(snapshot.data != null) {
            mediaItem = snapshot.data!;
          } else {
            return const SizedBox();
          }

          final offline = !mediaItem.extras!['url'].toString().startsWith('http');
          if(mediaItem.artUri.toString().isNotEmpty) {
            mediaItem.artUri.toString().startsWith('file')
                ? getColors(imageProvider: FileImage(File(mediaItem.artUri!.toFilePath(),),),).then((value) => updateBackgroundColors(value))
                : getColors(imageProvider: CachedNetworkImageProvider(mediaItem.artUri.toString(),),).then((value) => updateBackgroundColors(value));
          }
          return ValueListenableBuilder(
            valueListenable: gradientColor,
            child: Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: AppColor.main75,
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: AppColor.main75,
                  centerTitle: true,
                  leading: IconButton(
                    icon: Icon(appMediaItem == null ? Icons.expand_more_rounded : Icons.chevron_left),
                    tooltip: PlayerTranslationConstants.back.tr,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.lyrics_rounded),
                      tooltip: PlayerTranslationConstants.lyrics.tr,
                      onPressed: () => onlineCardKey.currentState!.toggleCard(),
                    ),
                    if (!offline)
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        tooltip: PlayerTranslationConstants.share.tr,
                        onPressed: () async {
                          if (!isSharePopupShown) {
                            isSharePopupShown = true;
                            final AppMediaItem item = MediaItemMapper.fromMediaItem(mediaItem);
                            await CoreUtilities().shareAppWithMediaItem(item).whenComplete(() {
                              Timer(const Duration(milliseconds: 600), () {
                                isSharePopupShown = false;
                              });
                            });
                          }
                        },
                      ),
                    if(appMediaItem != null) createPopMenuOption(context, appMediaItem, offline: offline)
                  ],
                ),
                body: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints,) {
                    return appMediaItem != null ? Column(
                      children: [
                        // Artwork
                        ArtWorkWidget(
                          cardKey: onlineCardKey, appMediaItem: appMediaItem,
                          width: constraints.maxWidth, audioHandler: audioHandler,
                          offline: offline, getLyricsOnline: getLyricsOnline,
                        ),
                        // title and controls
                        NameNControls(
                          appMediaItem: appMediaItem, offline: offline,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight - (constraints.maxWidth * 0.85),
                          panelController: _panelController, audioHandler: audioHandler,
                        ),
                      ],
                    ) : Container();
                  },
                ),
            ),
            builder: (BuildContext context, List<Color?>? value, Widget? child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [value?[1] ?? Colors.grey[900]!, Colors.black],
                  ),
                ),
                child: child,
              );
            },
          );
          // );CachedNetworkImageProvider
        },
      ),
    );
  }

  Widget createPopMenuOption(BuildContext context, AppMediaItem appMediaItem, {bool offline = false}) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert_rounded,color: AppColor.white),
      color: AppColor.getMain(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(15.0),
        ),
      ),
      onSelected: (int? value) {
        if(value != null) {
          MusicPlayerUtilities.onSelectedPopUpMenu(context, value, appMediaItem, _time);
        }
      },
      itemBuilder: (context) => offline ? [
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(CupertinoIcons.timer,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(PlayerTranslationConstants.sleepTimer.tr,),
            ],
          ),
        ),
        PopupMenuItem(
          value: 10,
          child: Row(
            children: [
              Icon(Icons.info_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(PlayerTranslationConstants.songInfo.tr,),
            ],
          ),
        ),
      ] : [
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.playlist_add_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(PlayerTranslationConstants.addToPlaylist.tr,),],),
        ),
        PopupMenuItem(
          value: 10,
          child: Row(
            children: [
              Icon(Icons.info_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(PlayerTranslationConstants.songInfo.tr,),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.timer,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(
                PlayerTranslationConstants.sleepTimer.tr,
              ),
            ],
          ),
        ),
        ///FUTURE IMPLEMENTATION
        // PopupMenuItem(
        //   value: 3,
        //   child: Row(
        //     children: [
        //       Icon(MdiIcons.youtube,
        //         color: Theme.of(context).iconTheme.color,
        //       ),
        //       const SizedBox(width: 10.0),
        //       Text(appMediaItem.genre == 'YouTube'
        //           ? PlayerTranslationConstants.watchVideo.tr
        //           : PlayerTranslationConstants.searchVideo.tr,
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

}


