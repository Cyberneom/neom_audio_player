import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import '../../utils/constants/app_hive_constants.dart';
import '../../utils/helpers/media_item_mapper.dart';
import 'miniplayer_controller.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});


  ///DEPRECATED
  // static MiniPlayer _instance = MiniPlayer._internal();
  // factory MiniPlayer() => _instance;
  // MiniPlayer._internal();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MiniPlayerController>(
      id: AppPageIdConstants.miniPlayer,
      init: MiniPlayerController(),
      builder: (_) {
        List preferredButtons = Hive.box(AppHiveConstants.settings).get('preferredMiniButtons', defaultValue: ['Like', 'Play/Pause', 'Next'],)?.toList() as List<dynamic>;
        final List<String> preferredMiniButtons = preferredButtons.map((e) => e.toString()).toList();
        return Obx(() => _.isLoading.value || (_.isTimeline.value && !_.showInTimeline.value) ? Container() : Container(
          decoration: AppTheme.appBoxDecoration,
          height: _.mediaItem.value == null ? 80 : 78,
          width: AppTheme.fullWidth(context),
          child: Dismissible(
              key: const Key(AppPageIdConstants.miniPlayer),
              direction: DismissDirection.vertical,
              confirmDismiss: (DismissDirection direction) {
                if (_.mediaItem.value != null) {
                  if (direction == DismissDirection.down || direction == DismissDirection.horizontal) {
                    _.audioHandler.stop();
                  } else {
                    Get.toNamed(AppRouteConstants.musicPlayerMedia, arguments: [MediaItemMapper.fromMediaItem(_.mediaItem.value!), false]);
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => MediaPlayerPage(appMediaItem: MediaItemMapper.fromMediaItem(_.mediaItem.value!), reproduceItem: false),),);
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
