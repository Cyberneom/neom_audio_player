import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/constants/app_hive_constants.dart';
import '../../utils/helpers/media_item_mapper.dart';
import '../../utils/helpers/songs_count.dart' as songs_count;
import 'app_hive_controller.dart';

class PlaylistHiveController extends GetxController  {

  final userController = Get.find<UserController>();
  final appHiveController = Get.find<AppHiveController>();
  Map<String, AppMediaItem> globalMediaItems = {};
  late SharedPreferences prefs;

  bool firstTime = false;
  int lastNotificationCheckDate = 0;

  @override
  Future<void> onInit() async {
    super.onInit();
    AppUtilities.logger.d('onInit PlaylistHive Controller');
    globalMediaItems = await AppMediaItemFirestore().fetchAll();

  }

  bool checkPlaylist(String name, String key) {
    if (name != AppHiveConstants.favoriteSongs) {
      Hive.openBox(name).then((value) {
        return Hive.box(name).containsKey(key);
      });
    }
    return Hive.box(name).containsKey(key);
  }

  Future<void> removeLiked(String key) async {
    final Box likedBox = Hive.box(AppHiveConstants.favoriteSongs);
    likedBox.delete(key);
    // setState(() {});
  }

  Future<void> addMapToPlaylist(String name, Map info) async {
    if (name != AppHiveConstants.favoriteSongs) await Hive.openBox(name);
    final Box playlistBox = Hive.box(name);
    final List songs = playlistBox.values.toList();
    info.addEntries([MapEntry('dateAdded', DateTime.now().toString())]);
    songs_count.addSongsCount(
      name,
      playlistBox.values.length + 1,
      songs.length >= 4 ? songs.sublist(0, 4) : songs.sublist(0, songs.length),
    );
    playlistBox.put(info['id'].toString(), info);
  }

  Future<void> addItemToPlaylist(String name, MediaItem mediaItem) async {
    if (name != AppHiveConstants.favoriteSongs) await Hive.openBox(name);
    final Box playlistBox = Hive.box(name);
    final Map info = MediaItemMapper.toJSON(mediaItem);
    info.addEntries([MapEntry('dateAdded', DateTime.now().toString())]);
    final List songs = playlistBox.values.toList();
    songs_count.addSongsCount(
      name,
      playlistBox.values.length + 1,
      songs.length >= 4 ? songs.sublist(0, 4) : songs.sublist(0, songs.length),
    );
    playlistBox.put(mediaItem.id, info);
  }

  Future<void> addPlaylist(String inputName, List data) async {
    final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    String name = inputName.replaceAll(avoid, '').replaceAll('  ', ' ');

    await Hive.openBox(name);
    final Box playlistBox = Hive.box(name);

    songs_count.addSongsCount(
      name,
      data.length,
      data.length >= 4 ? data.sublist(0, 4) : data.sublist(0, data.length),
    );
    final Map result = {for (final v in data) v['id'].toString(): v};
    playlistBox.putAll(result);

    final List playlistNames =
    Hive.box(AppHiveConstants.settings).get('playlistNames', defaultValue: []) as List;

    if (name.trim() == '') {
      name = 'Playlist ${playlistNames.length}';
    }
    while (playlistNames.contains(name)) {
      // ignore: use_string_buffers
      name += ' (1)';
    }
    playlistNames.add(name);
    Hive.box(AppHiveConstants.settings).put('playlistNames', playlistNames);
  }

  Future<void> addQueryEntry(String inputName, List data) async {
    final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    String name = inputName.replaceAll(avoid, '').replaceAll('  ', ' ');

    await Hive.openBox(name);
    final Box playlistBox = Hive.box(name);

    songs_count.addSongsCount(
      name,
      data.length,
      data.length >= 4 ? data.sublist(0, 4) : data.sublist(0, data.length),
    );
    final Map result = {for (final v in data) v['id'].toString(): v};
    playlistBox.putAll(result);

    final List playlistNames =
    Hive.box(AppHiveConstants.settings).get('playlistNames', defaultValue: []) as List;

    if (name.trim() == '') {
      name = 'Playlist ${playlistNames.length}';
    }
    while (playlistNames.contains(name)) {
      // ignore: use_string_buffers
      name += ' (1)';
    }
    playlistNames.add(name);
    Hive.box(AppHiveConstants.settings).put('playlistNames', playlistNames);
  }

}
