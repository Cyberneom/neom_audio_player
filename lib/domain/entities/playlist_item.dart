

import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_music_player/utils/enums/playlist_type.dart';
import 'package:enum_to_string/enum_to_string.dart';

class PlaylistItem {

  String id;
  String title;
  String subtitle;
  String description;
  String imgUrl;
  String firstItemId;
  PlaylistType type;
  int count;

  PlaylistItem({
    this.id = '',
    this.title = '',
    this.subtitle = '',
    this.description = '',
    this.imgUrl = '',
    this.firstItemId = '',
    this.type = PlaylistType.playlist,
    this.count = 0,
  });

  Map<String, dynamic> toJSON() {
    AppUtilities.logger.d('PlaylistItem toJSON');
    return <String, dynamic> {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imgUrl': imgUrl,
      'firstItemId': firstItemId,
      'type': type.name,
      'count': count,
    };
  }

  PlaylistItem.fromJSON(data) :
        id = data['playlistId'].toString() ?? '',
        title = data['title'].toString(),
        subtitle = data['subtitle'].toString(),
        description = data['description'].toString() ?? '',
        firstItemId = data['firstItemId'].toString() ?? '',
        imgUrl = data['imgUrl'].toString() ?? '',
        type = EnumToString.fromString(PlaylistType.values, data['type'].toString() ?? PlaylistType.playlist.name) ?? PlaylistType.playlist,
        count = int.parse(data['count'].toString());
}
