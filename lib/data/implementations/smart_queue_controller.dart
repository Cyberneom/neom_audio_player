import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:sint/sint.dart';

import '../../domain/models/smart_queue.dart';
import '../../domain/use_cases/smart_queue_service.dart';
import '../../neom_audio_handler.dart';
import '../../utils/mappers/media_item_mapper.dart';
import 'audio_recommendation_engine.dart';

/// Implementation of SmartQueueService with recommendations and persistence
class SmartQueueController extends SintController implements SmartQueueService {
  static const String _boxName = 'smart_queue';
  static const String _queueStateKey = 'queue_state';
  static const int _historyMaxSize = 50;
  static const int _autoAddThreshold = 3;

  Box? _box;
  final _queue = Rx<SmartQueue>(const SmartQueue());
  final _queueStreamController = StreamController<SmartQueue>.broadcast();
  final _historyList = <SmartQueueItem>[].obs;
  final _autoRecommendations = false.obs;
  final _notInterestedIds = <String>{};
  final _random = Random();
  final _recommendationEngine = AudioRecommendationEngine();

  NeomAudioHandler? _audioHandler;

  @override
  void onInit() {
    super.onInit();
    _initHive();
    try {
      _audioHandler = Sint.find<NeomAudioHandler>();
    } catch (e) {
      AppConfig.logger.w('NeomAudioHandler not available for SmartQueueController');
    }
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox(_boxName);
    await restoreQueue();
  }

  // ============ Getters ============

  @override
  SmartQueue get queue => _queue.value;

  @override
  Stream<SmartQueue> get queueStream => _queueStreamController.stream;

  @override
  bool get autoRecommendationsEnabled => _autoRecommendations.value;

  @override
  List<SmartQueueItem> get history => _historyList.toList();

  @override
  Duration get totalDuration {
    int totalMs = 0;
    for (final item in _queue.value.items) {
      totalMs += item.mediaItem.duration?.inMilliseconds ?? 0;
    }
    return Duration(milliseconds: totalMs);
  }

  @override
  Duration get remainingDuration {
    int totalMs = 0;
    final upcoming = _queue.value.upcomingItems;
    for (final item in upcoming) {
      totalMs += item.mediaItem.duration?.inMilliseconds ?? 0;
    }
    return Duration(milliseconds: totalMs);
  }

  @override
  int get songCount => _queue.value.items.length;

  @override
  int get upcomingCount => _queue.value.upcomingItems.length;

  @override
  bool get isEmpty => _queue.value.items.isEmpty;

  @override
  bool get hasRecommendations =>
      _queue.value.items.any((item) => item.isRecommendation);

  @override
  List<MediaItem> get mediaItems => _queue.value.mediaItems;

  // ============ Queue Operations ============

  @override
  Future<void> initializeQueue(
    List<MediaItem> items, {
    QueueItemSource source = QueueItemSource.userAdded,
    int startIndex = 0,
  }) async {
    final queueItems = items.map((item) => SmartQueueItem(
      mediaItem: item,
      source: source,
      addedAt: DateTime.now(),
      addedBy: 'user',
    )).toList();

    _queue.value = SmartQueue(
      items: queueItems,
      originalOrder: List.generate(queueItems.length, (i) => i),
      currentIndex: startIndex,
    );

    _notifyUpdate();
    await _syncWithAudioHandler();
  }

  @override
  Future<void> addToQueue(
    MediaItem item, {
    QueueItemSource source = QueueItemSource.userAdded,
  }) async {
    final newItem = SmartQueueItem(
      mediaItem: item,
      source: source,
      addedAt: DateTime.now(),
      addedBy: 'user',
    );

    final items = List<SmartQueueItem>.from(_queue.value.items)..add(newItem);
    final order = List<int>.from(_queue.value.originalOrder)..add(items.length - 1);

    _queue.value = _queue.value.copyWith(items: items, originalOrder: order);
    _notifyUpdate();
    await _audioHandler?.addQueueItem(item);
  }

  @override
  Future<void> playNext(
    MediaItem item, {
    QueueItemSource source = QueueItemSource.userAdded,
  }) async {
    final newItem = SmartQueueItem(
      mediaItem: item,
      source: source,
      addedAt: DateTime.now(),
      addedBy: 'user',
    );

    final items = List<SmartQueueItem>.from(_queue.value.items);
    final insertIndex = _queue.value.currentIndex + 1;
    items.insert(insertIndex.clamp(0, items.length), newItem);

    final order = List.generate(items.length, (i) => i);
    _queue.value = _queue.value.copyWith(items: items, originalOrder: order);
    _notifyUpdate();
    await _audioHandler?.insertQueueItem(insertIndex, item);
  }

  @override
  Future<void> addMultiple(
    List<MediaItem> items, {
    QueueItemSource source = QueueItemSource.userAdded,
  }) async {
    final newItems = items.map((item) => SmartQueueItem(
      mediaItem: item,
      source: source,
      addedAt: DateTime.now(),
      addedBy: 'user',
    )).toList();

    final allItems = List<SmartQueueItem>.from(_queue.value.items)..addAll(newItems);
    final order = List.generate(allItems.length, (i) => i);

    _queue.value = _queue.value.copyWith(items: allItems, originalOrder: order);
    _notifyUpdate();
    await _syncWithAudioHandler();
  }

  @override
  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _queue.value.items.length) return;

    final items = List<SmartQueueItem>.from(_queue.value.items)..removeAt(index);
    final currentIdx = _queue.value.currentIndex;
    final newIndex = index < currentIdx ? currentIdx - 1 : currentIdx;

    _queue.value = _queue.value.copyWith(
      items: items,
      currentIndex: newIndex.clamp(0, items.length - 1),
      originalOrder: List.generate(items.length, (i) => i),
    );
    _notifyUpdate();
    await _syncWithAudioHandler();
  }

  @override
  Future<void> removeById(String mediaItemId) async {
    final index = _queue.value.items.indexWhere((i) => i.mediaItem.id == mediaItemId);
    if (index >= 0) await removeAt(index);
  }

  @override
  Future<void> clearQueue() async {
    _queue.value = const SmartQueue();
    _notifyUpdate();
    await _syncWithAudioHandler();
  }

  @override
  Future<void> clearUpcoming() async {
    final currentIdx = _queue.value.currentIndex;
    final items = _queue.value.items.sublist(0, currentIdx + 1);

    _queue.value = _queue.value.copyWith(
      items: items,
      originalOrder: List.generate(items.length, (i) => i),
    );
    _notifyUpdate();
    await _syncWithAudioHandler();
  }

  @override
  Future<void> move(int from, int to) async {
    if (from < 0 || from >= _queue.value.items.length) return;
    if (to < 0 || to >= _queue.value.items.length) return;

    final items = List<SmartQueueItem>.from(_queue.value.items);
    final item = items.removeAt(from);
    items.insert(to, item);

    var currentIdx = _queue.value.currentIndex;
    if (from == currentIdx) {
      currentIdx = to;
    } else if (from < currentIdx && to >= currentIdx) {
      currentIdx--;
    } else if (from > currentIdx && to <= currentIdx) {
      currentIdx++;
    }

    _queue.value = _queue.value.copyWith(
      items: items,
      currentIndex: currentIdx,
      originalOrder: List.generate(items.length, (i) => i),
    );
    _notifyUpdate();
    await _syncWithAudioHandler();
  }

  @override
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queue.value.items.length) return;

    // Add current to history
    final current = _queue.value.currentItem;
    if (current != null) {
      await addToHistory(current.mediaItem);
    }

    _queue.value = _queue.value.copyWith(currentIndex: index);
    _notifyUpdate();
    await _audioHandler?.skipToQueueItem(index);
    _checkAutoRecommendations();
  }

  // ============ Shuffle ============

  @override
  Future<void> enableShuffle() async {
    final indices = List.generate(_queue.value.items.length, (i) => i);
    final currentIdx = _queue.value.currentIndex;

    // Remove current from shuffle pool, shuffle rest, put current first
    indices.removeAt(currentIdx);
    indices.shuffle(_random);
    indices.insert(0, currentIdx);

    _queue.value = _queue.value.copyWith(
      isShuffled: true,
      shuffleIndices: indices,
      currentIndex: 0,
    );
    _notifyUpdate();
    await _audioHandler?.setShuffleMode(AudioServiceShuffleMode.all);
  }

  @override
  Future<void> disableShuffle() async {
    // Find actual index in original order
    final actualIndex = _queue.value.isShuffled
        ? _queue.value.shuffleIndices[_queue.value.currentIndex]
        : _queue.value.currentIndex;

    _queue.value = _queue.value.copyWith(
      isShuffled: false,
      shuffleIndices: [],
      currentIndex: actualIndex,
    );
    _notifyUpdate();
    await _audioHandler?.setShuffleMode(AudioServiceShuffleMode.none);
  }

  @override
  Future<void> toggleShuffle() async {
    if (_queue.value.isShuffled) {
      await disableShuffle();
    } else {
      await enableShuffle();
    }
  }

  @override
  Future<void> reshuffle() async {
    await disableShuffle();
    await enableShuffle();
  }

  // ============ Recommendations ============

  @override
  Future<void> enableAutoRecommendations() async {
    _autoRecommendations.value = true;
    _checkAutoRecommendations();
  }

  @override
  Future<void> disableAutoRecommendations() async {
    _autoRecommendations.value = false;
  }

  @override
  Future<List<MediaItem>> getRecommendations({
    int count = 10,
    RecommendationSource? source,
  }) async {
    try {
      final currentItem = _queue.value.currentItem;
      if (currentItem == null) {
        final recommendations = await _recommendationEngine.personalMix(count: count);
        return recommendations.map((r) => MediaItemMapper.fromAppReleaseItem(item: r)).toList();
      }

      final songId = currentItem.mediaItem.id;
      final ownerEmail = currentItem.mediaItem.extras?['ownerEmail'] as String?;

      switch (source ?? RecommendationSource.currentSong) {
        case RecommendationSource.currentSong:
          final recs = await _recommendationEngine.recommendFromSong(songId, count: count);
          return recs.map((r) => MediaItemMapper.fromAppReleaseItem(item: r)).toList();
        case RecommendationSource.liked:
          final recs = await _recommendationEngine.fromLikedSongs(count: count);
          return recs.map((r) => MediaItemMapper.fromAppReleaseItem(item: r)).toList();
        case RecommendationSource.history:
          final recs = await _recommendationEngine.personalMix(count: count);
          return recs.map((r) => MediaItemMapper.fromAppReleaseItem(item: r)).toList();
        case RecommendationSource.newReleases:
        case RecommendationSource.trending:
          final recs = await _recommendationEngine.discoveryQueue(count: count);
          return recs.map((r) => MediaItemMapper.fromAppReleaseItem(item: r)).toList();
        default:
          final recs = await _recommendationEngine.recommendFromSong(songId, count: count);
          return recs.map((r) => MediaItemMapper.fromAppReleaseItem(item: r)).toList();
      }
    } catch (e) {
      AppConfig.logger.e('Error getting recommendations: $e');
      return [];
    }
  }

  @override
  Future<void> addRecommendations({
    int count = 5,
    RecommendationSource? source,
  }) async {
    final recommendations = await getRecommendations(count: count, source: source);
    if (recommendations.isEmpty) return;

    // Filter out not-interested and already in queue
    final existingIds = _queue.value.items.map((i) => i.mediaItem.id).toSet();
    final filtered = recommendations.where((item) =>
        !_notInterestedIds.contains(item.id) && !existingIds.contains(item.id),
    ).toList();

    final newItems = filtered.map((item) => SmartQueueItem(
      mediaItem: item,
      source: QueueItemSource.recommendation,
      addedAt: DateTime.now(),
      addedBy: 'system',
      isRecommendation: true,
      recommendationReason: source?.displayName ?? 'Recommended for you',
    )).toList();

    final allItems = List<SmartQueueItem>.from(_queue.value.items)..addAll(newItems);

    _queue.value = _queue.value.copyWith(
      items: allItems,
      originalOrder: List.generate(allItems.length, (i) => i),
      lastRecommendationSource: source ?? RecommendationSource.currentSong,
    );
    _notifyUpdate();
    await _syncWithAudioHandler();
  }

  @override
  Future<void> refreshRecommendations() async {
    // Remove existing recommendations
    final items = _queue.value.items.where((i) => !i.isRecommendation).toList();
    _queue.value = _queue.value.copyWith(
      items: items,
      originalOrder: List.generate(items.length, (i) => i),
    );

    // Add fresh ones
    await addRecommendations(count: 5);
  }

  @override
  Future<void> markNotInterested(String mediaItemId) async {
    _notInterestedIds.add(mediaItemId);
    await removeById(mediaItemId);

    // Persist
    final avoidSongs = List<String>.from(_queue.value.avoidSongs)..add(mediaItemId);
    _queue.value = _queue.value.copyWith(avoidSongs: avoidSongs);
    _notifyUpdate();
  }

  @override
  Future<void> undoNotInterested(String mediaItemId) async {
    _notInterestedIds.remove(mediaItemId);
    final avoidSongs = List<String>.from(_queue.value.avoidSongs)..remove(mediaItemId);
    _queue.value = _queue.value.copyWith(avoidSongs: avoidSongs);
    _notifyUpdate();
  }

  // ============ History ============

  @override
  Future<void> addToHistory(MediaItem item) async {
    final histItem = SmartQueueItem(
      mediaItem: item,
      source: QueueItemSource.userAdded,
      addedAt: DateTime.now(),
      addedBy: 'user',
    );

    _historyList.insert(0, histItem);
    if (_historyList.length > _historyMaxSize) {
      _historyList.removeRange(_historyMaxSize, _historyList.length);
    }

    // Also update playHistory in queue model
    final playHistory = List<String>.from(_queue.value.playHistory)..insert(0, item.id);
    if (playHistory.length > _historyMaxSize) {
      playHistory.removeRange(_historyMaxSize, playHistory.length);
    }
    _queue.value = _queue.value.copyWith(playHistory: playHistory);
  }

  @override
  SmartQueueItem? getHistoryItem(int stepsBack) {
    if (stepsBack < 0 || stepsBack >= _historyList.length) return null;
    return _historyList[stepsBack];
  }

  @override
  Future<void> clearHistory() async {
    _historyList.clear();
    _queue.value = _queue.value.copyWith(playHistory: []);
  }

  // ============ Save/Restore ============

  @override
  Future<void> saveAsPlaylist(String name, {String? description}) async {
    try {
      final items = _queue.value.items;
      if (items.isEmpty) return;

      final appMediaItems = items
          .map((i) => MediaItemMapper.toAppMediaItem(i.mediaItem))
          .toList();

      final itemlist = Itemlist(
        name: name,
        description: description ?? '',
        type: ItemlistType.playlist,
      );
      itemlist.appMediaItems = appMediaItems;

      await ItemlistFirestore().insert(itemlist);
      AppConfig.logger.i('Queue saved as playlist: $name');
    } catch (e) {
      AppConfig.logger.e('Error saving queue as playlist: $e');
    }
  }

  @override
  Future<void> saveQueueState() async {
    try {
      final data = {
        'items': _queue.value.items.map((i) => {
          'mediaItem': MediaItemMapper.toJSON(i.mediaItem),
          'source': i.source.value,
          'addedBy': i.addedBy,
          'isRecommendation': i.isRecommendation,
        }).toList(),
        'currentIndex': _queue.value.currentIndex,
        'isShuffled': _queue.value.isShuffled,
        'autoRecommendations': _autoRecommendations.value,
      };
      await _box?.put(_queueStateKey, jsonEncode(data));
    } catch (e) {
      AppConfig.logger.e('Error saving queue state: $e');
    }
  }

  @override
  Future<void> restoreQueue() async {
    try {
      final raw = _box?.get(_queueStateKey) as String?;
      if (raw == null) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final itemsData = data['items'] as List? ?? [];

      final items = itemsData.map<SmartQueueItem>((e) {
        final map = e as Map<String, dynamic>;
        return SmartQueueItem(
          mediaItem: MediaItemMapper.fromJSON(Map<String, dynamic>.from(map['mediaItem'])),
          source: QueueItemSource.values.firstWhere(
            (s) => s.value == map['source'],
            orElse: () => QueueItemSource.userAdded,
          ),
          addedAt: DateTime.now(),
          addedBy: map['addedBy'] ?? 'user',
          isRecommendation: map['isRecommendation'] ?? false,
        );
      }).toList();

      if (items.isNotEmpty) {
        _queue.value = SmartQueue(
          items: items,
          originalOrder: List.generate(items.length, (i) => i),
          currentIndex: (data['currentIndex'] as int?) ?? 0,
          isShuffled: (data['isShuffled'] as bool?) ?? false,
        );
        _autoRecommendations.value = (data['autoRecommendations'] as bool?) ?? false;
        _notifyUpdate();
      }
    } catch (e) {
      AppConfig.logger.e('Error restoring queue state: $e');
    }
  }

  // ============ Private Helpers ============

  void _notifyUpdate() {
    _queueStreamController.add(_queue.value);
    update();
  }

  Future<void> _syncWithAudioHandler() async {
    if (_audioHandler == null) return;
    final mediaItems = _queue.value.mediaItems;
    if (mediaItems.isNotEmpty) {
      await _audioHandler!.updateQueue(mediaItems);
    }
  }

  void _checkAutoRecommendations() {
    if (!_autoRecommendations.value) return;
    if (_queue.value.shouldAddRecommendations) {
      addRecommendations(count: 5);
    }
  }

  @override
  void onClose() {
    saveQueueState();
    _queueStreamController.close();
    super.onClose();
  }
}
