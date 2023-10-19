import 'dart:async';
import 'dart:ffi';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/ui/player/media_player_page.dart';
import 'package:neom_music_player/ui/player/miniplayer_controller.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/helpers/media_item_mapper.dart';

class MiniPlayer extends StatefulWidget {

  static MiniPlayer _instance = MiniPlayer._internal();
  final StreamController<MediaItem?> mediaItemController = StreamController<MediaItem?>();
  factory MiniPlayer() {
    return _instance;
  }

  MiniPlayer._internal();

  @override
  _MiniPlayerState createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {

  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MiniPlayerController>(
      id: 'miniplayer',
      init: MiniPlayerController(),
      builder: (_) {
        List preferredButtons = Hive.box(AppHiveConstants.settings).get('preferredMiniButtons', defaultValue: ['Like', 'Play/Pause', 'Next'],)?.toList() as List<dynamic>;
        final List<String> preferredMiniButtons = preferredButtons.map((e) => e.toString()).toList();
        return Obx(() => _.isLoading.value || (_.isTimeline.value && !_.showInTimeline.value) ? Container() : Container(
          decoration: AppTheme.appBoxDecoration,
          height: _.mediaItem.value == null ? 80 : 78,
          width: AppTheme.fullWidth(context),
          child: Dismissible(
              key: const Key('miniplayer'),
              direction: DismissDirection.vertical,
              confirmDismiss: (DismissDirection direction) {
                if (_.mediaItem.value != null) {
                  if (direction == DismissDirection.down || direction == DismissDirection.horizontal) {
                    _.audioHandler.stop();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaPlayerPage(appMediaItem: MediaItemMapper.fromMediaItem(_.mediaItem.value!), reproduceItem: false),
                      ),
                    );
                  }
                }
                return Future.value(false);
              },
              child: Dismissible(
                key: Key(_.mediaItem.value?.id ?? 'nothingPlaying'),
                confirmDismiss: (DismissDirection direction) {
                  if(_.isTimeline.value) {
                    _.setShowInTimeline(value: false);
                  } else {
                    if (_.mediaItem.value != null) {
                      if (direction == DismissDirection.startToEnd) {
                        _.audioHandler.skipToPrevious();
                      } else {
                        _.audioHandler.skipToNext();
                      }
                    }
                  }

                  return Future.value(false);

                },
                child: Card(
                  margin: EdgeInsets.zero,
                  color: AppColor.getMain(),
                  elevation: 1,
                  child: SizedBox(
                    height: _.mediaItem.value == null ? 80 : 78,
                    width: AppTheme.fullWidth(context),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _.miniplayerTile(
                          context: context,
                          preferredMiniButtons: preferredMiniButtons,
                          item: _.mediaItem.value,
                          isTimeline: _.isTimeline.value,
                        ),
                        _.positionSlider(_.mediaItem.value?.duration?.inSeconds.toDouble(),),
                      ],
                  ),),
                ),
              ),
          ),
        ),
        );
      },
    );
  }

}
