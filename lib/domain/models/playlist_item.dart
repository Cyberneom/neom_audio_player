import 'package:enum_to_string/enum_to_string.dart';
import 'package:neom_core/app_config.dart';
import '../../utils/enums/playlist_type.dart';

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
    AppConfig.logger.d('PlaylistItem toJSON');
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

  PlaylistItem.fromJSON(dynamic data) :
        id = data['playlistId'].toString(),
        title = data['title'].toString(),
        subtitle = data['subtitle'].toString(),
        description = data['description'].toString(),
        firstItemId = data['firstItemId'].toString(),
        imgUrl = data['imgUrl'].toString(),
        type = EnumToString.fromString(PlaylistType.values, data['type'].toString()) ?? PlaylistType.playlist,
        count = int.parse(data['count'].toString());
}
