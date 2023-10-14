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
        return Obx(() => _.isLoading || (_.isTimeline && !_.showInTimeline) ? Container() : Container(
          decoration: AppTheme.appBoxDecoration,
          height: _.mediaItem == null ? 80 : 78,
          width: AppTheme.fullWidth(context),
          child: Dismissible(
              key: const Key('miniplayer'),
              direction: DismissDirection.vertical,
              confirmDismiss: (DismissDirection direction) {
                if (_.mediaItem != null) {
                  if (direction == DismissDirection.down || direction == DismissDirection.horizontal) {
                    _.audioHandler.stop();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaPlayerPage(appMediaItem: MediaItemMapper.fromMediaItem(_.mediaItem!), reproduceItem: false),
                      ),
                    );
                  }
                }
                return Future.value(false);
              },
              child: Dismissible(
                key: Key(_.mediaItem?.id ?? 'nothingPlaying'),
                confirmDismiss: (DismissDirection direction) {
                  if(_.isTimeline) {
                    _.setShowInTimeline(value: false);
                  } else {
                    if (_.mediaItem != null) {
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
                    height: _.mediaItem == null ? 80 : 78,
                    width: AppTheme.fullWidth(context),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _.miniplayerTile(
                          context: context,
                          preferredMiniButtons: preferredMiniButtons,
                          item: _.mediaItem,
                          isTimeline: _.isTimeline,
                        ),
                        _.positionSlider(_.mediaItem?.duration?.inSeconds.toDouble(),),
                      ],
                  ),),
                ),
              ),
          ),
        ),
        );
      },);
  }

}
