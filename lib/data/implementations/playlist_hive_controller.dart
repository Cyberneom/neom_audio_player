import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/use_cases/app_hive_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/use_cases/playlist_hive_service.dart';
import '../../utils/helpers/songs_count.dart' as songs_count;
import '../../utils/mappers/media_item_mapper.dart';
import 'player_hive_controller.dart';

class PlaylistHiveController implements PlaylistHiveService {

  static final PlaylistHiveController _instance = PlaylistHiveController._internal();
  factory PlaylistHiveController() {
    _instance.init();
    return _instance;
  }

  PlaylistHiveController._internal();

  bool _isInitialized = false;

  final userServiceImpl = Get.find<UserService>();
  final playerHiveController = PlayerHiveController();
  final appHiveServiceImpl = Get.find<AppHiveService>();
  Map<String, AppMediaItem> globalMediaItems = {};
  late SharedPreferences prefs;

  bool firstTime = false;
  int lastNotificationCheckDate = 0;

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    AppConfig.logger.d('onInit PlaylistHive Controller');
    globalMediaItems = await AppMediaItemFirestore().fetchAll();

  }

  @override
  bool checkPlaylist(String name, String key) {
    appHiveServiceImpl.getBox(name).then((value) {
      return Hive.box(name).containsKey(key);
    });

    return false;
  }

  @override
  Future<void> removeLiked(String key) async {
    final Box likedBox = await appHiveServiceImpl.getBox(AppHiveBox.favoriteItems.name);
    likedBox.delete(key);
    // setState(() {});
  }

  @override
  Future<void> addMapToPlaylist(String name, Map info) async {
    final Box playlistBox = await appHiveServiceImpl.getBox(name);
    final List songs = playlistBox.values.toList();
    info.addEntries([MapEntry('dateAdded', DateTime.now().toString())]);
    songs_count.addSongsCount(
      name,
      playlistBox.values.length + 1,
      songs.length >= 4 ? songs.sublist(0, 4) : songs.sublist(0, songs.length),
    );
    playlistBox.put(info['id'].toString(), info);
  }

  @override
  Future<void> addItemToPlaylist(String name, MediaItem mediaItem) async {
    if (name != AppHiveBox.favoriteItems.name) await Hive.openBox(name);
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

  @override
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

    final settingsBox = await appHiveServiceImpl.getBox(AppHiveBox.settings.name);
    final List playlistNames = settingsBox.get('playlistNames', defaultValue: []) as List;

    if (name.trim() == '') {
      name = 'Playlist ${playlistNames.length}';
    }
    while (playlistNames.contains(name)) {
      // ignore: use_string_buffers
      name += ' (1)';
    }
    playlistNames.add(name);
    settingsBox.put('playlistNames', playlistNames);
  }

  @override
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

    final settingsBox = await appHiveServiceImpl.getBox(AppHiveBox.settings.name);
    final List playlistNames = settingsBox.get('playlistNames', defaultValue: []) as List;

    if (name.trim() == '') {
      name = 'Playlist ${playlistNames.length}';
    }
    while (playlistNames.contains(name)) {
      // ignore: use_string_buffers
      name += ' (1)';
    }
    playlistNames.add(name);
    settingsBox.put('playlistNames', playlistNames);
  }

}
