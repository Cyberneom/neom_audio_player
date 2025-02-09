import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/utils/constants/app_hive_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';

import '../../utils/helpers/media_item_mapper.dart';
import 'miniplayer_controller.dart';
import 'widgets/miniplayer_tile.dart';


class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MiniPlayerController>(
      id: AppPageIdConstants.miniPlayer,
      init: MiniPlayerController(),
      builder: (_) {
        if(_.isLoading || (_.isTimeline && !_.showInTimeline)) return const SizedBox.shrink();

        List preferredButtons = Hive.box(AppHiveBox.settings.name)
            .get(AppHiveConstants.preferredMiniButtons,
          defaultValue: ['Like', 'Play/Pause', 'Next'],)?.toList() as List<dynamic>;

        final List<String> preferredMiniButtons = preferredButtons.map((e) => e.toString()).toList();

        return SizedBox(
          ///DEPRECATED
          // height: _.mediaItem == null ? 76 : 74,
          child: Dismissible(
              key: const Key(AppPageIdConstants.miniPlayer),
              direction: DismissDirection.vertical,
              confirmDismiss: (DismissDirection direction) {
                if (_.mediaItem != null) {
                  if (direction == DismissDirection.down || direction == DismissDirection.horizontal) {
                    _.audioHandler?.stop();
                  } else {
                    Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [MediaItemMapper.fromMediaItem(_.mediaItem!), false]);
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => MediaPlayerPage(appMediaItem: MediaItemMapper.fromMediaItem(_.mediaItem!), reproduceItem: false),),);
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
                        _.audioHandler?.skipToPrevious();
                      } else {
                        _.audioHandler?.skipToNext();
                      }
                    }
                  }

                  return Future.value(false);
                },
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 1,
                  child: SizedBox(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MiniPlayerTile(
                          miniPlayerController: _,
                          preferredMiniButtons: preferredMiniButtons,
                          item: _.mediaItem,
                          isTimeline: _.isTimeline,
                        ),
                        if(_.audioHandlerRegistered) _.positionSlider(isPreview: !_.isInternal),
                      ],
                    ),
                  ),
                ),
              ),
          ),
        );
      },
    );
  }

}
