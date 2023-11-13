import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/playlist_section.dart';
import '../../utils/constants/app_hive_constants.dart';

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
  bool showHistory = true;
  List searchHistory = [];


  @override
  Future<void> onInit() async {
    super.onInit();
    logger.t('AppHive Controller');

    try {
      await fetchCachedData();
      await fetchSettingsData();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  Box? getBox(String boxName) {
    return Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null;
  }

  static Future<void> openHiveBox(String boxName, {bool limit = false}) async {
    final box = await Hive.openBox(boxName).onError((error, stackTrace) async {
      AppUtilities.logger.e('Failed to open $boxName Box');
      final Directory dir = await getApplicationDocumentsDirectory();
      final String dirPath = dir.path;
      final File dbFile = File('$dirPath/$boxName.hive');
      final File lockFile = File('$dirPath/$boxName.lock');

      await dbFile.delete();
      await lockFile.delete();
      await Hive.openBox(boxName);
      throw 'Failed to open $boxName Box\nError: $error';
    });

    if (limit && box.length > 500) {
      AppUtilities.logger.w("Box $boxName would be cleared as it exceeded the limit");
      box.clear();
    }
  }

  Future<void> updateCache({PlaylistSection? headList, List<PlaylistSection>? searchedList}) async {
    ///REFERENCE
    // if(headList != null) Hive.box(AppHiveConstants.cache).put('ytHomeHead', headList);
  }


  Future<void> fetchCachedData() async {
    lastQueueList = await Hive.box(AppHiveConstants.cache).get(AppHiveConstants.lastQueue, defaultValue: [])?.toList() as List;
    lastIndex = await Hive.box(AppHiveConstants.cache).get(AppHiveConstants.lastIndex, defaultValue: 0) as int;
    lastPos = await Hive.box(AppHiveConstants.cache).get(AppHiveConstants.lastPos, defaultValue: 0) as int;
  }

  Future<void> fetchSettingsData() async {
    preferredMobileQuality = await Hive.box(AppHiveConstants.settings).get(AppHiveConstants.streamingQuality, defaultValue: '96 kbps') as String;
    preferredWifiQuality = await Hive.box(AppHiveConstants.settings).get(AppHiveConstants.streamingWifiQuality, defaultValue: '320 kbps') as String;
    resetOnSkip = await Hive.box(AppHiveConstants.settings).get(AppHiveConstants.resetOnSkip, defaultValue: false) as bool;
    cacheSong = await Hive.box(AppHiveConstants.settings).get(AppHiveConstants.cacheSong, defaultValue: true) as bool;
    recommend =  await Hive.box(AppHiveConstants.settings).get(AppHiveConstants.autoplay, defaultValue: true) as bool;
    loadStart = await Hive.box(AppHiveConstants.settings).get(AppHiveConstants.loadStart, defaultValue: true) as bool;
    useDownload = await Hive.box(AppHiveConstants.settings).get(AppHiveConstants.useDown, defaultValue: true) as bool;
    preferredCompactNotificationButtons = Hive.box(AppHiveConstants.settings).get(AppHiveConstants.preferredCompactNotificationButtons, defaultValue: [1, 2, 3],) as List<int>;
    stopForegroundService = Hive.box(AppHiveConstants.settings).get(AppHiveConstants.stopForegroundService, defaultValue: true) as bool;
    repeatMode = EnumToString.fromString(AudioServiceRepeatMode.values, Hive.box(AppHiveConstants.settings)
        .get(AppHiveConstants.repeatMode, defaultValue: AudioServiceRepeatMode.none.name,).toString(),) ?? AudioServiceRepeatMode.none;
    enforceRepeat = Hive.box(AppHiveConstants.settings).get(AppHiveConstants.enforceRepeat, defaultValue: false) as bool;
    searchQueries = Hive.box(AppHiveConstants.settings).get(AppHiveConstants.searchQueries, defaultValue: []) as List;
    liveSearch = Hive.box(AppHiveConstants.settings).get(AppHiveConstants.liveSearch, defaultValue: true) as bool;
    showHistory = Hive.box(AppHiveConstants.settings).get(AppHiveConstants.showHistory, defaultValue: true) as bool;
    searchHistory = Hive.box(AppHiveConstants.settings).get(AppHiveConstants.searchHistory, defaultValue: []) as List;
  }

  Future<void> updateRepeatMode(AudioServiceRepeatMode mode) async {
    await Hive.box(AppHiveConstants.settings).put(AppHiveConstants.repeatMode, mode.name);
  }

  Future<void> setSearchQueries(List searchQueries) async {
    Hive.box(AppHiveConstants.settings).put(AppHiveConstants.searchQueries, searchQueries);
  }

}
