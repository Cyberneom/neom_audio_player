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
import 'package:get/get.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/ui/player/miniplayer_controller.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/player/audioplayer.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';

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
        id: "miniplayer",
        init: MiniPlayerController(),
    builder: (_) {
      final List preferredMiniButtons = Hive.box(AppHiveConstants.settings).get('preferredMiniButtons', defaultValue: ['Like', 'Play/Pause', 'Next'],)?.toList() as List;
      return Obx(() => _.isLoading ? Container() : Container(
        decoration: AppTheme.appBoxDecoration,
        child: Dismissible(
            key: const Key('miniplayer'),
            direction: DismissDirection.vertical,
            confirmDismiss: (DismissDirection direction) {
              if (_.mediaItem != null) {
                if (direction == DismissDirection.down) {
                  _.audioHandler.stop();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayScreen(),
                    ),
                  );
                }
              }
              return Future.value(false);
            },
            child: Dismissible(
              key: Key(_.mediaItem?.id ?? 'nothingPlaying'),
              confirmDismiss: (DismissDirection direction) {
                if (_.mediaItem != null) {
                  if (direction == DismissDirection.startToEnd) {
                    _.audioHandler.skipToPrevious();
                  } else {
                    _.audioHandler.skipToNext();
                  }
                }
                return Future.value(false);
              },
              child: Card(
                margin: EdgeInsets.zero,
                color: AppColor.getMain(),
                elevation: 10,
                child: SizedBox(

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _.miniplayerTile(
                        context: context,
                        preferredMiniButtons: preferredMiniButtons,
                        // useDense: true,
                        title: _.mediaItem?.title ?? '',
                        subtitle: _.mediaItem?.artist ?? '',
                        imagePath: (_.mediaItem?.artUri?.toString().startsWith('file:') ?? false
                                ? _.mediaItem?.artUri?.toFilePath()
                                : _.mediaItem?.artUri?.toString()) ??
                            '',
                        isLocalImage: _.mediaItem?.artUri?.toString().startsWith('file:') ?? false,
                        isDummy: _.mediaItem == null,
                      ),
                      _.positionSlider(_.mediaItem?.duration?.inSeconds.toDouble(),),
                    ],
                  ),
                ),
              ),
            ),
      ),),
    );
  });
  }

}
