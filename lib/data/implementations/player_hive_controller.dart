import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:neom_commons/core/data/implementations/app_hive_controller.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_hive_constants.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';


class PlayerHiveController {

  static final PlayerHiveController _instance = PlayerHiveController._internal();
  factory PlayerHiveController() {
    _instance._init();
    return _instance;
  }

  PlayerHiveController._internal();

  bool _isInitialized = false;

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
  bool useDownload = false;
  bool stopForegroundService = true;
  AudioServiceRepeatMode repeatMode = AudioServiceRepeatMode.none;
  bool enforceRepeat = false;

  bool liveSearch = true;
  bool showHistory = true;
  bool getLyricsOnline = false;
  bool enableGesture = true;

  List searchHistory = [];
  List preferredLanguage = [];

  //TIMELINE
  Map<String, AppReleaseItem> releaseItems = {};
  Map<String, Itemlist> releaseItemlists = {};

  Future<void> _init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      AppUtilities.logger.t('PlayerHive Controller');
      await fetchCachedData();
      await fetchSettingsData();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }


  Future<void> fetchCachedData() async {
    AppUtilities.logger.t('Fetch Cache Data');
    final playerBox = await AppHiveController().getBox(AppHiveBox.player.name);

    lastQueueList = playerBox.get(AppHiveConstants.lastQueue, defaultValue: [])?.toList() as List;
    lastIndex = playerBox.get(AppHiveConstants.lastIndex, defaultValue: 0) as int;
    lastPos = playerBox.get(AppHiveConstants.lastPos, defaultValue: 0) as int;
    // await playerBox.close();
  }

  Future<int> fetchLastPos(String itemId) async {
    final playerBox = await AppHiveController().getBox(AppHiveBox.player.name);
    lastPos =  await playerBox.get('${AppHiveConstants.lastPos}_$itemId', defaultValue: 0) as int;
    // await playerBox.close();

    return lastPos;
  }

  Future<void> updateItemLastPos(String itemId, int position) async {
    final playerBox = await AppHiveController().getBox(AppHiveBox.player.name);
    await playerBox.put('${AppHiveConstants.lastPos}_$itemId', position);
    // await playerBox.close();
  }

  Future<void> fetchSettingsData() async {
    AppUtilities.logger.t('Fetch Settings Data');

    final settingsBox = await AppHiveController().getBox(AppHiveBox.settings.name);

    preferredMobileQuality = settingsBox.get(AppHiveConstants.streamingQuality, defaultValue: '96 kbps') as String;
    preferredWifiQuality = settingsBox.get(AppHiveConstants.streamingWifiQuality, defaultValue: '320 kbps') as String;
    resetOnSkip = settingsBox.get(AppHiveConstants.resetOnSkip, defaultValue: true) as bool;
    cacheSong = settingsBox.get(AppHiveConstants.cacheSong, defaultValue: true) as bool;
    recommend =  settingsBox.get(AppHiveConstants.autoplay, defaultValue: true) as bool;
    loadStart = settingsBox.get(AppHiveConstants.loadStart, defaultValue: true) as bool;
    useDownload = settingsBox.get(AppHiveConstants.useDown, defaultValue: false) as bool;
    preferredCompactNotificationButtons = settingsBox.get(AppHiveConstants.preferredCompactNotificationButtons, defaultValue: [1, 2, 3],) as List<int>;
    stopForegroundService = settingsBox.get(AppHiveConstants.stopForegroundService, defaultValue: true) as bool;
    repeatMode = EnumToString.fromString(AudioServiceRepeatMode.values, settingsBox.get(AppHiveConstants.repeatMode, defaultValue: AudioServiceRepeatMode.none.name,).toString(),) ?? AudioServiceRepeatMode.none;
    enforceRepeat = settingsBox.get(AppHiveConstants.enforceRepeat, defaultValue: false) as bool;
    liveSearch = settingsBox.get(AppHiveConstants.liveSearch, defaultValue: true) as bool;
    showHistory = settingsBox.get(AppHiveConstants.showHistory, defaultValue: true) as bool;
    searchHistory = settingsBox.get(AppHiveConstants.searchHistory, defaultValue: []) as List;
    getLyricsOnline = settingsBox.get(AppHiveConstants.getLyricsOnline, defaultValue: false) as bool;
    enableGesture = settingsBox.get(AppHiveConstants.enableGesture, defaultValue: true) as bool;
    preferredLanguage = settingsBox.get(AppHiveConstants.preferredLanguage, defaultValue: ['Español']) as List;
    // await settingsBox.close();
  }

  Future<void> updateRepeatMode(AudioServiceRepeatMode mode) async {
    final settingsBox = await AppHiveController().getBox(AppHiveBox.settings.name);
    await settingsBox.put(AppHiveConstants.repeatMode, mode.name);
    // await settingsBox.close();

  }

  Future<void> setSearchQueries(List searchQueries) async {
    final settingsBox = await AppHiveController().getBox(AppHiveBox.settings.name);
    await settingsBox.put(AppHiveConstants.searchQueries, searchQueries);
    // await settingsBox.close();
  }

  Future<void> addQuery(String query) async {
    final settingsBox = await AppHiveController().getBox(AppHiveBox.settings.name);

    query = query.trim();
    List searchQueries = settingsBox.get(AppHiveConstants.search, defaultValue: [],) as List;
    final idx = searchQueries.indexOf(query);
    if (idx != -1) searchQueries.removeAt(idx);
    searchQueries.insert(0, query);
    if (searchQueries.length > 10) searchQueries = searchQueries.sublist(0, 10);
    await settingsBox.put(AppHiveConstants.search, searchQueries);
    // await settingsBox.close();

  }

  Future<List<String>> getPreferredMiniButtons() async {
    final settingsBox = await AppHiveController().getBox(AppHiveBox.settings.name);

    List preferredButtons = settingsBox.get(AppHiveConstants.preferredMiniButtons,
      defaultValue: ['Like', 'Play/Pause', 'Next'],)?.toList() as List<dynamic>;
    // await settingsBox.close();

    return preferredButtons.map((e) => e.toString()).toList();
  }

  Future<void> setLastQueue(List<Map<dynamic,dynamic>> lastQueue) async {
    final playerBox = await AppHiveController().getBox(AppHiveBox.player.name);
    await playerBox.put(AppHiveConstants.lastQueue, lastQueue);
    // await playerBox.close();
  }

  Future<void> setLastIndexAndPos(int? lastIndex, int lastPos) async {
    final playerBox = await AppHiveController().getBox(AppHiveBox.player.name);
    await playerBox.put(AppHiveConstants.lastIndex, lastIndex);
    await playerBox.put(AppHiveConstants.lastPos, lastPos);
    // await playerBox.close();
  }

}
