import 'package:hive/hive.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';

void addSongsCount(String playlistName, int len, List images) {
  final Map playlistDetails =
      Hive.box(AppHiveConstants.settings).get('playlistDetails', defaultValue: {}) as Map;
  if (playlistDetails.containsKey(playlistName)) {
    playlistDetails[playlistName].addAll({'count': len, 'imagesList': images});
  } else {
    playlistDetails.addEntries([
      MapEntry(playlistName, {'count': len, 'imagesList': images}),
    ]);
  }
  Hive.box(AppHiveConstants.settings).put('playlistDetails', playlistDetails);
}
