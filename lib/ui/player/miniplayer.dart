import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import '../../utils/mappers/media_item_mapper.dart';
import 'miniplayer_controller.dart';
import 'widgets/miniplayer_tile.dart';


class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MiniPlayerController>(
      id: AppPageIdConstants.miniPlayer,
      builder: (controller) {
        if(controller.isLoading || (controller.isTimeline && !controller.showInTimeline)) return const SizedBox.shrink();

        return SizedBox(
          child: Dismissible(
              key: const Key(AppPageIdConstants.miniPlayer),
              direction: DismissDirection.vertical,
              confirmDismiss: (DismissDirection direction) {
                if (controller.mediaItem.value != null) {
                  if (direction == DismissDirection.down || direction == DismissDirection.horizontal) {
                    controller.audioHandler?.stop();
                  } else {
                    Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [MediaItemMapper.toAppMediaItem(controller.mediaItem.value!), false]);
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => MediaPlayerPage(appMediaItem: MediaItemMapper.toAppMediaItem(controller.mediaItem!), reproduceItem: false),),);
                  }
                }
                return Future.value(false);
              },
              child: Dismissible(
                key: Key(controller.mediaItem.value?.id ?? 'nothingPlaying'),
                confirmDismiss: (DismissDirection direction) {
                  if(controller.isTimeline) {
                    controller.setShowInTimeline(value: false);
                  } else {
                    if (controller.mediaItem.value != null) {
                      if (direction == DismissDirection.startToEnd) {
                        controller.audioHandler?.skipToPrevious();
                      } else {
                        controller.audioHandler?.skipToNext();
                      }
                    }
                  }

                  return Future.value(false);
                },
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 1,
                  child: SizedBox(
                    child: Obx(()=> Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MiniPlayerTile(
                          miniPlayerController: controller,
                          item: controller.mediaItem.value,
                          isTimeline: controller.isTimeline,
                        ),
                        if(controller.audioHandlerRegistered) controller.positionSlider(isPreview: !controller.isInternal),
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
