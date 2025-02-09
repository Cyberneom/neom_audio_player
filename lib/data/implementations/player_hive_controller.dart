import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_hive_constants.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/playlist_section.dart';

class PlayerHiveController extends GetxController {

  //Music Player Cache
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

  //TIMELINE
  Map<String, AppReleaseItem> releaseItems = {};
  Map<String, Itemlist> releaseItemlists = {};

  @override
  Future<void> onInit() async {
    super.onInit();
    AppUtilities.logger.t('AppHive Controller');

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

  Future<void> fetchCachedData() async {
    lastQueueList = await Hive.box(AppHiveBox.player.name).get(AppHiveConstants.lastQueue, defaultValue: [])?.toList() as List;
    lastIndex = await Hive.box(AppHiveBox.player.name).get(AppHiveConstants.lastIndex, defaultValue: 0) as int;
    lastPos = await Hive.box(AppHiveBox.player.name).get(AppHiveConstants.lastPos, defaultValue: 0) as int;
  }

  Future<int> fetchLastPos(String itemId) async {
    lastPos =  await Hive.box(AppHiveBox.player.name).get('${AppHiveConstants.lastPos}_$itemId', defaultValue: 0) as int;
    return lastPos;
  }

  Future<void> updateItemLastPos(String itemId, int position) async {
    await Hive.box(AppHiveBox.player.name).put('${AppHiveConstants.lastPos}_$itemId', position);
  }

  Future<void> fetchSettingsData() async {
    preferredMobileQuality = await Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.streamingQuality, defaultValue: '96 kbps') as String;
    preferredWifiQuality = await Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.streamingWifiQuality, defaultValue: '320 kbps') as String;
    resetOnSkip = await Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.resetOnSkip, defaultValue: true) as bool;
    cacheSong = await Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.cacheSong, defaultValue: true) as bool;
    recommend =  await Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.autoplay, defaultValue: true) as bool;
    loadStart = await Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.loadStart, defaultValue: true) as bool;
    useDownload = await Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.useDown, defaultValue: true) as bool;
    preferredCompactNotificationButtons = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.preferredCompactNotificationButtons, defaultValue: [1, 2, 3],) as List<int>;
    stopForegroundService = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.stopForegroundService, defaultValue: true) as bool;
    repeatMode = EnumToString.fromString(AudioServiceRepeatMode.values, Hive.box(AppHiveBox.settings.name)
        .get(AppHiveConstants.repeatMode, defaultValue: AudioServiceRepeatMode.none.name,).toString(),) ?? AudioServiceRepeatMode.none;
    enforceRepeat = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.enforceRepeat, defaultValue: false) as bool;
    liveSearch = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.liveSearch, defaultValue: true) as bool;
    showHistory = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.showHistory, defaultValue: true) as bool;
    searchHistory = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.searchHistory, defaultValue: []) as List;
  }

  Future<void> updateRepeatMode(AudioServiceRepeatMode mode) async {
    await Hive.box(AppHiveBox.settings.name).put(AppHiveConstants.repeatMode, mode.name);
  }

  Future<void> setSearchQueries(List searchQueries) async {
    await Hive.box(AppHiveBox.settings.name).put(AppHiveConstants.searchQueries, searchQueries);
  }

  Future<void> addQuery(String query) async {
    query = query.trim();
    List searchQueries = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.search, defaultValue: [],) as List;
    final idx = searchQueries.indexOf(query);
    if (idx != -1) searchQueries.removeAt(idx);
    searchQueries.insert(0, query);
    if (searchQueries.length > 10) searchQueries = searchQueries.sublist(0, 10);
    Hive.box(AppHiveBox.settings.name).put(AppHiveConstants.search, searchQueries);
  }

}
