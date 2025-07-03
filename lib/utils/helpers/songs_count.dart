import 'package:hive/hive.dart';
import 'package:neom_core/core/utils/enums/app_hive_box.dart';

void addSongsCount(String playlistName, int len, List images) {
  final Map playlistDetails =
      Hive.box(AppHiveBox.settings.name).get('playlistDetails', defaultValue: {}) as Map;
  if (playlistDetails.containsKey(playlistName)) {
    playlistDetails[playlistName].addAll({'count': len, 'imagesList': images});
  } else {
    playlistDetails.addEntries([
      MapEntry(playlistName, {'count': len, 'imagesList': images}),
    ]);
  }
  Hive.box(AppHiveBox.settings.name).put('playlistDetails', playlistDetails);
}
