
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';

import '../../utils/constants/player_translation_constants.dart';
import '../../utils/helpers/media_item_mapper.dart';
import '../widgets/add_to_playlist.dart';
import 'media_player_controller.dart';
import 'widgets/artwork_widget.dart';
import 'widgets/name_n_controls.dart';

class MediaPlayerPage extends StatelessWidget {

  const MediaPlayerPage({super.key});

  // final bool getLyricsOnline = Hive.box(AppHiveConstants.settings).get('getLyricsOnline', defaultValue: true) as bool;
  // final PanelController _panelController = PanelController();
  // final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();
  // GlobalKey<FlipCardState> onlineCardKey = GlobalKey<FlipCardState>();
  // final Duration _time = Duration.zero;
  // bool isSharePopupShown = false;

  // @override
  // void initState() {
  //   super.initState();
  //   if(widget.appMediaItem != null) {
  //     bool alreadyPlaying = audioHandler.currentMediaItem != null && audioHandler.currentMediaItem!.id == widget.appMediaItem!.id;
  //     if(widget.reproduceItem && !alreadyPlaying) {
  //       Future.delayed(const Duration(milliseconds: 500)).then((value) {
  //         NeomPlayerInvoker.init(
  //           appMediaItems: [widget.appMediaItem!],
  //           index: 0,
  //         );
  //         // audioHandler.play();
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MediaPlayerController>(
      id: AppPageIdConstants.mediaPlayer,
      init: MediaPlayerController(),
      builder: (_) => StreamBuilder<MediaItem?>(
        stream: _.audioHandler.mediaItem,
        builder: (context, snapshot) {
          MediaItem mediaItem;
          if(_.appMediaItem.value != null) {
            mediaItem = MediaItemMapper.appMediaItemToMediaItem(appMediaItem: _.appMediaItem.value);
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
                    icon: const Icon(Icons.expand_more_rounded),
                    tooltip: PlayerTranslationConstants.back.tr,
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: (_.appMediaItem.value != null) ? [
                    IconButton(
                        icon: const Icon(Icons.playlist_add_rounded),
                        tooltip: PlayerTranslationConstants.addToPlaylist.tr,
                        iconSize: 35,
                        onPressed: () async {
                          AddToPlaylist().addToPlaylist(context, _.appMediaItem.value);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.lyrics_rounded),
                      tooltip: PlayerTranslationConstants.lyrics.tr,
                      onPressed: () => _.onlineCardKey.currentState!.toggleCard(),
                    ),
                    if (!offline)
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        tooltip: PlayerTranslationConstants.share.tr,
                        onPressed: () async {
                          await _.sharePopUp();
                        },
                      ),
                    ///NOT NEEDED BY NOW - OPTIONS ARE NOT FUNCTIONAL AT THE MOMENT
                    // if(appMediaItem != null) createPopMenuOption(context, appMediaItem, offline: offline),
                  ] : null,
                ),
                body: Container(
                  decoration: AppTheme.appBoxDecoration,
                  padding: const EdgeInsets.only(top: 20),
                  child: _.appMediaItem.value != null ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // AppTheme.heightSpace20,
                      ArtWorkWidget(
                        mediaPlayerController: _,
                        cardKey: _.onlineCardKey,
                        width: AppTheme.fullWidth(context),
                        offline: offline, getLyricsOnline: _.getLyricsOnline,
                      ),
                      NameNControls(
                        mediaPlayerController: _,
                        width: AppTheme.fullWidth(context),
                        height: AppTheme.fullHeight(context)*0.45,
                        panelController: _.panelController,
                      ),
                    ],
                  ) : Container(),
                ),
          );
        },
    ),
    );
  }

}
