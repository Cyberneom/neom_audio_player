import 'dart:async';
import 'package:audio_service/audio_service.dart';

abstract class PlaylistHiveService {

  Future<void> init();
  bool checkPlaylist(String name, String key);
  Future<void> removeLiked(String key);
  Future<void> addMapToPlaylist(String name, Map info);
  Future<void> addItemToPlaylist(String name, MediaItem mediaItem);
  Future<void> addPlaylist(String inputName, List data);
  Future<void> addQueryEntry(String inputName, List data);

}
