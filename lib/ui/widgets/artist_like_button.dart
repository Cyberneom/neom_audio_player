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

import 'package:hive/hive.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:get/get.dart';

class ArtistLikeButton extends StatefulWidget {
  final double? size;
  final Map data;
  final bool showSnack;
  const ArtistLikeButton({
    super.key,
    this.size,
    required this.data,
    this.showSnack = false,
  });

  @override
  _ArtistLikeButtonState createState() => _ArtistLikeButtonState();
}

class _ArtistLikeButtonState extends State<ArtistLikeButton>
    with SingleTickerProviderStateMixin {
  bool liked = false;
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _curve;
  Map likedArtists = Hive.box(AppHiveConstants.settings).get('likedArtists', defaultValue: {}) as Map;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _curve = CurvedAnimation(parent: _controller, curve: Curves.slowMiddle);

    _scale = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 50,
      ),
    ]).animate(_curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    liked = likedArtists.containsKey(widget.data['id'].toString());
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        icon: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: liked ? Colors.redAccent : Theme.of(context).iconTheme.color,
        ),
        iconSize: widget.size ?? 24.0,
        tooltip: liked
            ? PlayerTranslationConstants.unlike.tr.tr
            : PlayerTranslationConstants.like.tr,
        onPressed: () async {
          if (!liked) {
            _controller.forward();
            likedArtists.addEntries(
              [MapEntry(widget.data['id'].toString(), widget.data)],
            );
          } else {
            _controller.reverse();
            likedArtists.remove(widget.data['id'].toString());
          }
          Hive.box(AppHiveConstants.settings).put('likedArtists', likedArtists);
          setState(() {
            liked = !liked;
          });
          if (widget.showSnack) {
            ShowSnackBar().showSnackBar(
              context,
              liked
                  ? PlayerTranslationConstants.addedToFav.tr
                  : PlayerTranslationConstants.removedFromFav.tr,
            );
          }
        },
      ),
    );
  }
}