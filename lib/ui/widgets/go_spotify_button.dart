import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

class GoSpotifyButton extends StatelessWidget {
  final AppMediaItem? appMediaItem;
  final double? size;
  final bool showSnack;  

  const GoSpotifyButton({
    super.key,
    required this.appMediaItem,
    this.size,
    this.showSnack = false,
  });

  @override
  Widget build(BuildContext context) {
    try {

    } catch (e) {
      AppUtilities.logger.e('Error in likeButton: $e');
    }
    return IconButton(
        icon: Row(
          children: [
            Icon(MdiIcons.spotify, color: Colors.green),
          ],
        ),
        iconSize: size ?? 24.0,
        tooltip: AppTranslationConstants.listenOnSpotify.tr,
        onPressed: () async {
          await launchUrl(
            Uri.parse(appMediaItem!.permaUrl),
            mode: LaunchMode.externalApplication,
          );
        },
    );
  }
}