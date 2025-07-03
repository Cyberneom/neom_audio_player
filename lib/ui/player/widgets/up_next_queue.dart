import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_media_player/utils/constants/player_translation_constants.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../audio_player_controller.dart';
import 'now_playing_stream.dart';

class UpNextQueue extends StatelessWidget {

  final AudioPlayerController mediaPlayerController;
  final PanelController panelController;
  final double minHeight;

  const UpNextQueue({super.key,
    required this.mediaPlayerController,
    required this.panelController,
    required this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    AudioPlayerController _ = mediaPlayerController;
    return SizedBox(
      child: SlidingUpPanel(
        minHeight: minHeight,
        maxHeight: AppTheme.fullHeight(context)/2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
        ),
        padding: const EdgeInsets.only(right: 10),
        color: AppColor.main75,
        controller: panelController,
        header: GestureDetector(
          onTap: () {
            if (panelController.isPanelOpen) {
              panelController.close();
            } else {
              if (panelController.panelPosition > 0.9) {
                panelController.close();
              } else {
                panelController.open();
              }
            }
            },
          onVerticalDragUpdate: (DragUpdateDetails details) {
            if (details.delta.dy > 0.0) {
              panelController.animatePanelToPosition(0.0);
            }
            },
          child: Container(
            height: minHeight,
            width: AppTheme.fullWidth(context),
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppTheme.heightSpace5,
                Container(width: 30, height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                Expanded(
                  child: Center(child: Text(
                    PlayerTranslationConstants.upNextQueue.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),),
                ),
                AppTheme.heightSpace5,
              ],
            ),
          ),
        ),
        panelBuilder: (ScrollController scrollController) {
          return ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0,),
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    end: Alignment.topCenter,
                    begin: Alignment.center,
                    colors: [Colors.black, Colors.black, Colors.black,
                      Colors.transparent, Colors.transparent,],)
                      .createShader(Rect.fromLTRB(0, 0, rect.width, rect.height,),
                  );
                  },
                blendMode: BlendMode.dstIn,
                child: NowPlayingStream(
                  head: true,
                  headHeight: minHeight,
                  audioHandler: _.audioHandler,
                  scrollController: scrollController,
                  panelController: panelController,
                  showLikeButton: false,
                ),
              ),
            ),
          );
          },
      ),
    );
  }
}
