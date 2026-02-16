import 'package:audio_service/audio_service.dart';

import '../models/smart_queue.dart';

/// Abstract service for smart queue management with recommendations
abstract class SmartQueueService {
  /// Current smart queue
  SmartQueue get queue;

  /// Stream of queue updates
  Stream<SmartQueue> get queueStream;

  /// Whether auto-recommendations are enabled
  bool get autoRecommendationsEnabled;

  // ============ Queue Operations ============

  /// Initialize queue with media items
  Future<void> initializeQueue(
    List<MediaItem> items, {
    QueueItemSource source = QueueItemSource.userAdded,
    int startIndex = 0,
  });

  /// Add item to end of queue
  Future<void> addToQueue(
    MediaItem item, {
    QueueItemSource source = QueueItemSource.userAdded,
  });

  /// Add item to play next
  Future<void> playNext(
    MediaItem item, {
    QueueItemSource source = QueueItemSource.userAdded,
  });

  /// Add multiple items to queue
  Future<void> addMultiple(
    List<MediaItem> items, {
    QueueItemSource source = QueueItemSource.userAdded,
  });

  /// Remove item from queue by index
  Future<void> removeAt(int index);

  /// Remove item from queue by ID
  Future<void> removeById(String mediaItemId);

  /// Clear entire queue
  Future<void> clearQueue();

  /// Clear upcoming (keep current and played)
  Future<void> clearUpcoming();

  /// Move item from one position to another
  Future<void> move(int from, int to);

  /// Jump to specific index
  Future<void> jumpTo(int index);

  // ============ Shuffle ============

  /// Enable shuffle
  Future<void> enableShuffle();

  /// Disable shuffle
  Future<void> disableShuffle();

  /// Toggle shuffle
  Future<void> toggleShuffle();

  /// Reshuffle (new random order)
  Future<void> reshuffle();

  // ============ Recommendations ============

  /// Enable auto-recommendations
  Future<void> enableAutoRecommendations();

  /// Disable auto-recommendations
  Future<void> disableAutoRecommendations();

  /// Get recommendations based on current queue
  Future<List<MediaItem>> getRecommendations({
    int count = 10,
    RecommendationSource? source,
  });

  /// Add recommendations to queue
  Future<void> addRecommendations({
    int count = 5,
    RecommendationSource? source,
  });

  /// Refresh recommendations (replace existing recommendations)
  Future<void> refreshRecommendations();

  /// Mark song as not interested (affects future recommendations)
  Future<void> markNotInterested(String mediaItemId);

  /// Undo not interested
  Future<void> undoNotInterested(String mediaItemId);

  // ============ History ============

  /// Get queue history (previously played)
  List<SmartQueueItem> get history;

  /// Add song to history
  Future<void> addToHistory(MediaItem item);

  /// Get song at history index (for going back)
  SmartQueueItem? getHistoryItem(int stepsBack);

  /// Clear history
  Future<void> clearHistory();

  // ============ Save/Restore ============

  /// Save current queue as playlist
  Future<void> saveAsPlaylist(String name, {String? description});

  /// Restore queue from saved state
  Future<void> restoreQueue();

  /// Save queue state for restoration
  Future<void> saveQueueState();

  // ============ Queue Info ============

  /// Get total duration of queue
  Duration get totalDuration;

  /// Get remaining duration from current position
  Duration get remainingDuration;

  /// Get count of songs in queue
  int get songCount;

  /// Get count of upcoming songs
  int get upcomingCount;

  /// Check if queue is empty
  bool get isEmpty;

  /// Check if queue has recommendations
  bool get hasRecommendations;

  /// Get queue items as MediaItem list
  List<MediaItem> get mediaItems;
}

/// Smart queue configuration
class SmartQueueConfig {
  /// Whether to auto-add recommendations
  final bool autoAddRecommendations;

  /// Minimum songs before adding recommendations
  final int minItemsForAutoAdd;

  /// Number of recommendations to add at once
  final int recommendationsToAdd;

  /// Maximum history size
  final int maxHistorySize;

  /// Preferred recommendation source
  final RecommendationSource preferredSource;

  /// Whether to avoid recently played songs
  final bool avoidRecentlyPlayed;

  /// Hours to consider as "recently played"
  final int recentlyPlayedHours;

  /// Whether to consider skip history
  final bool considerSkipHistory;

  const SmartQueueConfig({
    this.autoAddRecommendations = true,
    this.minItemsForAutoAdd = 3,
    this.recommendationsToAdd = 5,
    this.maxHistorySize = 100,
    this.preferredSource = RecommendationSource.currentSong,
    this.avoidRecentlyPlayed = true,
    this.recentlyPlayedHours = 24,
    this.considerSkipHistory = true,
  });

  SmartQueueConfig copyWith({
    bool? autoAddRecommendations,
    int? minItemsForAutoAdd,
    int? recommendationsToAdd,
    int? maxHistorySize,
    RecommendationSource? preferredSource,
    bool? avoidRecentlyPlayed,
    int? recentlyPlayedHours,
    bool? considerSkipHistory,
  }) {
    return SmartQueueConfig(
      autoAddRecommendations: autoAddRecommendations ?? this.autoAddRecommendations,
      minItemsForAutoAdd: minItemsForAutoAdd ?? this.minItemsForAutoAdd,
      recommendationsToAdd: recommendationsToAdd ?? this.recommendationsToAdd,
      maxHistorySize: maxHistorySize ?? this.maxHistorySize,
      preferredSource: preferredSource ?? this.preferredSource,
      avoidRecentlyPlayed: avoidRecentlyPlayed ?? this.avoidRecentlyPlayed,
      recentlyPlayedHours: recentlyPlayedHours ?? this.recentlyPlayedHours,
      considerSkipHistory: considerSkipHistory ?? this.considerSkipHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoAddRecommendations': autoAddRecommendations,
      'minItemsForAutoAdd': minItemsForAutoAdd,
      'recommendationsToAdd': recommendationsToAdd,
      'maxHistorySize': maxHistorySize,
      'preferredSource': preferredSource.value,
      'avoidRecentlyPlayed': avoidRecentlyPlayed,
      'recentlyPlayedHours': recentlyPlayedHours,
      'considerSkipHistory': considerSkipHistory,
    };
  }

  factory SmartQueueConfig.fromJson(Map<String, dynamic> json) {
    return SmartQueueConfig(
      autoAddRecommendations: json['autoAddRecommendations'] as bool? ?? true,
      minItemsForAutoAdd: json['minItemsForAutoAdd'] as int? ?? 3,
      recommendationsToAdd: json['recommendationsToAdd'] as int? ?? 5,
      maxHistorySize: json['maxHistorySize'] as int? ?? 100,
      preferredSource: RecommendationSource.values.firstWhere(
        (e) => e.value == json['preferredSource'],
        orElse: () => RecommendationSource.currentSong,
      ),
      avoidRecentlyPlayed: json['avoidRecentlyPlayed'] as bool? ?? true,
      recentlyPlayedHours: json['recentlyPlayedHours'] as int? ?? 24,
      considerSkipHistory: json['considerSkipHistory'] as bool? ?? true,
    );
  }
}
