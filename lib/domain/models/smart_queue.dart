import 'package:audio_service/audio_service.dart';

/// Smart queue with recommendations and features
class SmartQueue {
  /// Queue items
  final List<SmartQueueItem> items;

  /// Original (non-shuffled) order
  final List<int> originalOrder;

  /// Current shuffle indices
  final List<int> shuffleIndices;

  /// Current index
  final int currentIndex;

  /// Whether shuffle is enabled
  final bool isShuffled;

  /// Auto-add recommendations when queue is low
  final bool autoAddRecommendations;

  /// Minimum items before adding recommendations
  final int minItemsForAutoAdd;

  /// History of played songs (for smart recommendations)
  final List<String> playHistory;

  /// Songs to avoid (skipped or disliked)
  final List<String> avoidSongs;

  /// Last recommendation source
  final RecommendationSource? lastRecommendationSource;

  const SmartQueue({
    this.items = const [],
    this.originalOrder = const [],
    this.shuffleIndices = const [],
    this.currentIndex = 0,
    this.isShuffled = false,
    this.autoAddRecommendations = true,
    this.minItemsForAutoAdd = 3,
    this.playHistory = const [],
    this.avoidSongs = const [],
    this.lastRecommendationSource,
  });

  /// Get current item
  SmartQueueItem? get currentItem {
    if (items.isEmpty) return null;
    final idx = isShuffled ? shuffleIndices[currentIndex] : currentIndex;
    if (idx >= items.length) return null;
    return items[idx];
  }

  /// Get upcoming items
  List<SmartQueueItem> get upcomingItems {
    if (currentIndex >= items.length - 1) return [];
    final indices = isShuffled
        ? shuffleIndices.sublist(currentIndex + 1)
        : List.generate(items.length - currentIndex - 1, (i) => currentIndex + 1 + i);
    return indices.map((i) => items[i]).toList();
  }

  /// Check if recommendations should be added
  bool get shouldAddRecommendations {
    if (!autoAddRecommendations) return false;
    return upcomingItems.length <= minItemsForAutoAdd;
  }

  /// Get items as MediaItem list
  List<MediaItem> get mediaItems => items.map((i) => i.mediaItem).toList();

  SmartQueue copyWith({
    List<SmartQueueItem>? items,
    List<int>? originalOrder,
    List<int>? shuffleIndices,
    int? currentIndex,
    bool? isShuffled,
    bool? autoAddRecommendations,
    int? minItemsForAutoAdd,
    List<String>? playHistory,
    List<String>? avoidSongs,
    RecommendationSource? lastRecommendationSource,
  }) {
    return SmartQueue(
      items: items ?? this.items,
      originalOrder: originalOrder ?? this.originalOrder,
      shuffleIndices: shuffleIndices ?? this.shuffleIndices,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffled: isShuffled ?? this.isShuffled,
      autoAddRecommendations: autoAddRecommendations ?? this.autoAddRecommendations,
      minItemsForAutoAdd: minItemsForAutoAdd ?? this.minItemsForAutoAdd,
      playHistory: playHistory ?? this.playHistory,
      avoidSongs: avoidSongs ?? this.avoidSongs,
      lastRecommendationSource: lastRecommendationSource ?? this.lastRecommendationSource,
    );
  }
}

/// Item in smart queue with metadata
class SmartQueueItem {
  /// The media item
  final MediaItem mediaItem;

  /// Source of this item
  final QueueItemSource source;

  /// When item was added
  final DateTime addedAt;

  /// Who added (user ID or 'system' for recommendations)
  final String addedBy;

  /// Whether this was auto-recommended
  final bool isRecommendation;

  /// Recommendation confidence score (0-1)
  final double? recommendationScore;

  /// Reason for recommendation
  final String? recommendationReason;

  const SmartQueueItem({
    required this.mediaItem,
    required this.source,
    required this.addedAt,
    required this.addedBy,
    this.isRecommendation = false,
    this.recommendationScore,
    this.recommendationReason,
  });

  SmartQueueItem copyWith({
    MediaItem? mediaItem,
    QueueItemSource? source,
    DateTime? addedAt,
    String? addedBy,
    bool? isRecommendation,
    double? recommendationScore,
    String? recommendationReason,
  }) {
    return SmartQueueItem(
      mediaItem: mediaItem ?? this.mediaItem,
      source: source ?? this.source,
      addedAt: addedAt ?? this.addedAt,
      addedBy: addedBy ?? this.addedBy,
      isRecommendation: isRecommendation ?? this.isRecommendation,
      recommendationScore: recommendationScore ?? this.recommendationScore,
      recommendationReason: recommendationReason ?? this.recommendationReason,
    );
  }
}

/// Source of a queue item
enum QueueItemSource {
  /// User manually added
  userAdded('user_added', 'Added by you'),

  /// From a playlist
  playlist('playlist', 'From playlist'),

  /// From an album
  album('album', 'From album'),

  /// From artist page
  artist('artist', 'From artist'),

  /// From radio station
  radio('radio', 'From radio'),

  /// System recommendation
  recommendation('recommendation', 'Recommended for you'),

  /// From search
  search('search', 'From search'),

  /// From Jam session
  jamSession('jam_session', 'From Jam'),

  /// From external share
  shared('shared', 'Shared with you'),

  /// From autoplay
  autoplay('autoplay', 'Autoplay');

  final String value;
  final String displayName;

  const QueueItemSource(this.value, this.displayName);
}

/// Source of recommendations
enum RecommendationSource {
  /// Based on current song
  currentSong('current_song', 'Based on current song'),

  /// Based on listening history
  history('history', 'Based on your history'),

  /// Based on liked songs
  liked('liked', 'Based on your likes'),

  /// Based on similar users
  collaborative('collaborative', 'Users like you enjoy'),

  /// Based on mood/time
  contextual('contextual', 'For your current mood'),

  /// New releases
  newReleases('new_releases', 'New release'),

  /// Trending
  trending('trending', 'Trending now');

  final String value;
  final String displayName;

  const RecommendationSource(this.value, this.displayName);
}

/// Recommendation request parameters
class RecommendationParams {
  /// Number of recommendations to get
  final int count;

  /// Seed song IDs
  final List<String>? seedSongIds;

  /// Seed artist IDs
  final List<String>? seedArtistIds;

  /// Seed genres
  final List<String>? seedGenres;

  /// Target energy level (0-1)
  final double? targetEnergy;

  /// Target danceability (0-1)
  final double? targetDanceability;

  /// Target valence/happiness (0-1)
  final double? targetValence;

  /// Songs to exclude
  final List<String>? excludeSongIds;

  /// Artists to exclude
  final List<String>? excludeArtistIds;

  /// Minimum popularity (0-100)
  final int? minPopularity;

  /// Maximum popularity (0-100)
  final int? maxPopularity;

  /// Release year range
  final int? minYear;
  final int? maxYear;

  const RecommendationParams({
    this.count = 10,
    this.seedSongIds,
    this.seedArtistIds,
    this.seedGenres,
    this.targetEnergy,
    this.targetDanceability,
    this.targetValence,
    this.excludeSongIds,
    this.excludeArtistIds,
    this.minPopularity,
    this.maxPopularity,
    this.minYear,
    this.maxYear,
  });

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      if (seedSongIds != null) 'seedSongIds': seedSongIds,
      if (seedArtistIds != null) 'seedArtistIds': seedArtistIds,
      if (seedGenres != null) 'seedGenres': seedGenres,
      if (targetEnergy != null) 'targetEnergy': targetEnergy,
      if (targetDanceability != null) 'targetDanceability': targetDanceability,
      if (targetValence != null) 'targetValence': targetValence,
      if (excludeSongIds != null) 'excludeSongIds': excludeSongIds,
      if (excludeArtistIds != null) 'excludeArtistIds': excludeArtistIds,
      if (minPopularity != null) 'minPopularity': minPopularity,
      if (maxPopularity != null) 'maxPopularity': maxPopularity,
      if (minYear != null) 'minYear': minYear,
      if (maxYear != null) 'maxYear': maxYear,
    };
  }
}
