
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_shared_preference_constants.dart';
import 'package:neom_music_player/domain/entities/playlist_section.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enum_to_string/enum_to_string.dart';

import 'dart:async';
import 'dart:io';


import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';



class AppHiveController extends GetxController {

  final logger = AppUtilities.logger;

  //Music Player Cache
  List searchedList = [];
  List searchQueries = [];
  List headList = [];
  List lastQueueList = [];
  int lastIndex = 0;
  int lastPos = 0;

  //Music Player Settings
  String preferredQuality = '';
  String preferredWifiQuality = '';
  String preferredMobileQuality = '';
  List<int> preferredCompactNotificationButtons = [1, 2, 3];
  bool resetOnSkip = true;
  bool cacheSong = true;
  bool recommend = true;
  bool loadStart = true;
  bool useDownload = true;
  bool stopForegroundService = true;
  AudioServiceRepeatMode repeatMode = AudioServiceRepeatMode.none;
  bool enforceRepeat = false;

  bool liveSearch = true;
  bool searchYtMusic = true;
  bool showHistory = true;
  List searchHistory = [];


  @override
  void onInit() async {
    super.onInit();
    logger.d('');

    try {
      await fetchCachedData();
      await fetchSettingsData();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }
  static Future<void> openHiveBox(String boxName, {bool limit = false}) async {
    final box = await Hive.openBox(boxName).onError((error, stackTrace) async {
      AppUtilities.logger.e('Failed to open $boxName Box', error, stackTrace);
      final Directory dir = await getApplicationDocumentsDirectory();
      final String dirPath = dir.path;
      File dbFile = File('$dirPath/$boxName.hive');
      File lockFile = File('$dirPath/$boxName.lock');

      await dbFile.delete();
      await lockFile.delete();
      await Hive.openBox(boxName);
      throw 'Failed to open $boxName Box\nError: $error';
    });
    // clear box if it grows large
    if (limit && box.length > 500) {
      box.clear();
    }
  }

  Future<void> updateCache({PlaylistSection? headList, List<PlaylistSection>? searchedList}) async {

    if(headList != null) {
      Hive.box(AppHiveConstants.cache).put('ytHomeHead', headList);
    }

    if(searchedList != null) {
      Hive.box(AppHiveConstants.cache).put('ytHome', searchedList);
    }


  }

  Future<void> fetchCachedData() async {
    searchedList = await Hive.box(AppHiveConstants.cache).get('ytHome', defaultValue: []) as List;
    headList = await Hive.box(AppHiveConstants.cache).get('ytHomeHead', defaultValue: []) as List;
    lastQueueList = await Hive.box(AppHiveConstants.cache).get('lastQueue', defaultValue: [])?.toList() as List;
    lastIndex = await Hive.box(AppHiveConstants.cache).get('lastIndex', defaultValue: 0) as int;
    lastPos = await Hive.box(AppHiveConstants.cache).get('lastPos', defaultValue: 0) as int;
  }

  Future<void> fetchSettingsData() async {
    preferredMobileQuality = await Hive.box(AppHiveConstants.settings).get('streamingQuality', defaultValue: '96 kbps') as String;
    preferredWifiQuality = await Hive.box(AppHiveConstants.settings).get('streamingWifiQuality', defaultValue: '320 kbps') as String;
    resetOnSkip = await Hive.box(AppHiveConstants.settings).get('resetOnSkip', defaultValue: false) as bool;
    cacheSong = await Hive.box(AppHiveConstants.settings).get('cacheSong', defaultValue: true) as bool;
    recommend =  await Hive.box(AppHiveConstants.settings).get('autoplay', defaultValue: true) as bool;
    loadStart = await Hive.box(AppHiveConstants.settings).get('loadStart', defaultValue: true) as bool;
    useDownload = await Hive.box(AppHiveConstants.settings).get('useDown', defaultValue: true) as bool;
    preferredCompactNotificationButtons = Hive.box(AppHiveConstants.settings).get('preferredCompactNotificationButtons', defaultValue: [1, 2, 3],) as List<int>;
    stopForegroundService = Hive.box(AppHiveConstants.settings).get('stopForegroundService', defaultValue: true) as bool;
    repeatMode = EnumToString.fromString(AudioServiceRepeatMode.values,
        Hive.box(AppHiveConstants.settings).get('repeatMode',
            defaultValue: AudioServiceRepeatMode.none.name).toString()) ?? AudioServiceRepeatMode.none;
    enforceRepeat = Hive.box(AppHiveConstants.settings).get('enforceRepeat', defaultValue: false) as bool;
    searchQueries = Hive.box(AppHiveConstants.settings).get('searchQueries', defaultValue: []) as List;
    liveSearch = Hive.box(AppHiveConstants.settings).get('liveSearch', defaultValue: true) as bool;
    searchYtMusic = Hive.box(AppHiveConstants.settings).get('searchYtMusic', defaultValue: true) as bool;
    showHistory = Hive.box(AppHiveConstants.settings).get('showHistory', defaultValue: true) as bool;
    searchHistory = Hive.box(AppHiveConstants.settings).get('searchHistory', defaultValue: []) as List;
  }

  Future<List> getCachedSearchList() async {
    return await Hive.box(AppHiveConstants.cache).get('ytHome', defaultValue: []) as List;
  }

  Future<List> getCachedHeadList() async {
    return await Hive.box(AppHiveConstants.cache).get('ytHomeHead', defaultValue: []) as List;
  }

  Future<Map> getYouTubeCache(String mediItemId) async {
    return await Hive.box(AppHiveConstants.ytLinkCache).get(mediItemId) as Map;
  }

  Box? getBox(String boxName) {
    return Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null;
  }

  Future<void> updateRepeatMode(AudioServiceRepeatMode mode) async {
    await Hive.box(AppHiveConstants.settings).put('repeatMode', mode.name);
  }

  Future<void> setSearchQueries(List searchQueries) async {
    Hive.box(AppHiveConstants.settings).put('searchQueries', searchQueries);
  }


}
