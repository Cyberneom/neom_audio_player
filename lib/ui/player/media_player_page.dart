import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../domain/use_cases/neom_audio_handler.dart';
import '../../neom_player_invoker.dart';
import '../../utils/constants/app_hive_constants.dart';
import '../../utils/constants/player_translation_constants.dart';
import '../../utils/helpers/dominant_color.dart';
import '../../utils/helpers/media_item_mapper.dart';
import '../../utils/music_player_utilities.dart';
import '../../utils/theme/music_player_theme.dart';
import '../widgets/add_to_playlist.dart';
import 'media_player_controller.dart';
import 'widgets/artwork_widget.dart';
import 'widgets/name_n_controls.dart';

class MediaPlayerPage extends StatefulWidget {

  AppMediaItem? appMediaItem;
  bool reproduceItem;
  MediaPlayerPage({super.key, this.appMediaItem, this.reproduceItem = true});
  @override
  _MediaPlayerPageState createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {

  final bool getLyricsOnline = Hive.box(AppHiveConstants.settings).get('getLyricsOnline', defaultValue: true) as bool;
  final PanelController _panelController = PanelController();
  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();
  GlobalKey<FlipCardState> onlineCardKey = GlobalKey<FlipCardState>();
  final Duration _time = Duration.zero;
  bool isSharePopupShown = false;

  @override
  void initState() {
    super.initState();
    if(widget.appMediaItem != null) {
      bool alreadyPlaying = audioHandler.currentMediaItem != null && audioHandler.currentMediaItem!.id == widget.appMediaItem!.id;
      if(widget.reproduceItem && !alreadyPlaying) {
        Future.delayed(const Duration(milliseconds: 500)).then((value) {
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
    final AppMediaItem? appMediaItem = widget.appMediaItem;

    return GetBuilder<MediaPlayerController>(
      id: AppPageIdConstants.mediaPlayer,
      init: MediaPlayerController(),
      builder: (_) => StreamBuilder<MediaItem?>(
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
          return Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: AppColor.main50,
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: AppColor.main50,
                  centerTitle: true,
                  leading: IconButton(
                    icon: Icon(appMediaItem == null ? Icons.expand_more_rounded : Icons.chevron_left),
                    tooltip: PlayerTranslationConstants.back.tr,
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: (appMediaItem != null) ? [
                    IconButton(
                        icon: const Icon(Icons.playlist_add_rounded),
                        tooltip: PlayerTranslationConstants.addToPlaylist.tr,
                        iconSize: 35,
                        onPressed: () async {
                          AddToPlaylist().addToPlaylist(context, appMediaItem);
                        },
                      ),
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
                    ///NOT NEEDED BY NOW - OPTIONS ARE NOT FUNCTIONAL AT THE MOMENT
                    // if(appMediaItem != null) createPopMenuOption(context, appMediaItem, offline: offline),
                  ] : null,
                ),
                body: Container(
                  decoration: AppTheme.appBoxDecoration,
                  padding: EdgeInsets.only(top: 20),
                  child: appMediaItem != null ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // AppTheme.heightSpace20,
                      ArtWorkWidget(
                        cardKey: onlineCardKey, appMediaItem: appMediaItem,
                        width: AppTheme.fullWidth(context), audioHandler: audioHandler,
                        offline: offline, getLyricsOnline: getLyricsOnline,
                      ),
                      NameNControls(
                        appMediaItem: appMediaItem!, offline: offline,
                        width: AppTheme.fullWidth(context),
                        height: AppTheme.fullHeight(context)*0.45,
                        panelController: _panelController, audioHandler: audioHandler,
                      ),
                    ],
                  ) : Container(),
                ),
          );
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
              AppTheme.widthSpace10,
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
              AppTheme.widthSpace10,
              Text(PlayerTranslationConstants.addToPlaylist.tr,),],),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.timer,
                color: Theme.of(context).iconTheme.color,
              ),
              AppTheme.widthSpace10,
              Text(
                PlayerTranslationConstants.sleepTimer.tr,
              ),
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
      ],
    );
  }

}
