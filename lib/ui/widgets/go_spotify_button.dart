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

import 'package:flutter/material.dart';

import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
            Icon(MdiIcons.spotify, color: true ? Colors.green : Theme.of(context).iconTheme.color,),
          ],
        ),
        iconSize: size ?? 24.0,
        tooltip: "Escuchar en Spotify",
        onPressed: () async {
          await launchUrl(
            Uri.parse(appMediaItem!.permaUrl),
            mode: LaunchMode.externalApplication,
          );
        },
    );
  }
}
