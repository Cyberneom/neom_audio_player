
import 'dart:convert';

import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_music_player/domain/entities/playlist_item.dart';
import 'package:neom_music_player/domain/entities/playlist_section.dart';
import 'package:neom_music_player/utils/enums/playlist_type.dart';
import 'package:enum_to_string/enum_to_string.dart';

class YoutubeMusicHome {

  PlaylistSection? head;
  List<PlaylistSection>? body;

  YoutubeMusicHome({
    this.head,
    this.body,
  });

}
