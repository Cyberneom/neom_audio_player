

import 'package:neom_music_player/domain/entities/playlist_item.dart';

class PlaylistSection {

  String title;
  List<PlaylistItem>? playlistItems;

  PlaylistSection({
    this.title = '',
    this.playlistItems,
  });

}
