import 'dart:async';

import 'package:audio_service/audio_service.dart';

abstract class PlayerHiveService {

  Future<void> init();
  Future<void> fetchCachedData();
  Future<int> fetchLastPos(String itemId);
  Future<void> updateItemLastPos(String itemId, int position);
  Future<void> fetchSettingsData();
  Future<void> updateRepeatMode(AudioServiceRepeatMode mode);
  Future<void> setSearchQueries(List searchQueries);
  Future<void> addQuery(String query);
  Future<List<String>> getPreferredMiniButtons();
  Future<void> setLastQueue(List<Map<dynamic,dynamic>> lastQueue);
  Future<void> setLastIndexAndPos(int? lastIndex, int lastPos);

}
