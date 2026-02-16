import 'package:audio_service/audio_service.dart';

import '../../utils/enums/radio_seed_type.dart';

/// Represents an auto-generated radio station
class RadioStation {
  /// Unique identifier
  final String id;

  /// Station name
  final String name;

  /// Station description
  final String description;

  /// Cover image URL
  final String imageUrl;

  /// Type of seed used to generate this station
  final RadioSeedType seedType;

  /// Seed value (song ID, artist ID, genre name, etc.)
  final String seedValue;

  /// Optional mood filter
  final RadioMood? mood;

  /// Generated queue of songs
  final List<MediaItem> queue;

  /// Current position in queue
  final int currentIndex;

  /// Whether station is currently playing
  final bool isPlaying;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last played timestamp
  final DateTime? lastPlayedAt;

  /// Number of times this station was played
  final int playCount;

  /// Songs that have been skipped (to avoid in future)
  final List<String> skippedSongIds;

  /// Songs that were liked from this station
  final List<String> likedSongIds;

  /// Whether to auto-refresh queue when running low
  final bool autoRefresh;

  /// Minimum songs to keep in queue
  final int minQueueSize;

  const RadioStation({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.seedType,
    required this.seedValue,
    this.mood,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    required this.createdAt,
    this.lastPlayedAt,
    this.playCount = 0,
    this.skippedSongIds = const [],
    this.likedSongIds = const [],
    this.autoRefresh = true,
    this.minQueueSize = 5,
  });

  RadioStation copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    RadioSeedType? seedType,
    String? seedValue,
    RadioMood? mood,
    List<MediaItem>? queue,
    int? currentIndex,
    bool? isPlaying,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    int? playCount,
    List<String>? skippedSongIds,
    List<String>? likedSongIds,
    bool? autoRefresh,
    int? minQueueSize,
  }) {
    return RadioStation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      seedType: seedType ?? this.seedType,
      seedValue: seedValue ?? this.seedValue,
      mood: mood ?? this.mood,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      playCount: playCount ?? this.playCount,
      skippedSongIds: skippedSongIds ?? this.skippedSongIds,
      likedSongIds: likedSongIds ?? this.likedSongIds,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      minQueueSize: minQueueSize ?? this.minQueueSize,
    );
  }

  /// Check if queue needs refresh
  bool get needsRefresh {
    if (!autoRefresh) return false;
    final remainingSongs = queue.length - currentIndex;
    return remainingSongs <= minQueueSize;
  }

  /// Get remaining songs in queue
  List<MediaItem> get upcomingSongs {
    if (currentIndex >= queue.length) return [];
    return queue.sublist(currentIndex + 1);
  }

  /// Get current song
  MediaItem? get currentSong {
    if (queue.isEmpty || currentIndex >= queue.length) return null;
    return queue[currentIndex];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'seedType': seedType.value,
      'seedValue': seedValue,
      'mood': mood?.value,
      'currentIndex': currentIndex,
      'isPlaying': isPlaying,
      'createdAt': createdAt.toIso8601String(),
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'playCount': playCount,
      'skippedSongIds': skippedSongIds,
      'likedSongIds': likedSongIds,
      'autoRefresh': autoRefresh,
      'minQueueSize': minQueueSize,
    };
  }

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      seedType: RadioSeedType.values.firstWhere(
        (e) => e.value == json['seedType'],
        orElse: () => RadioSeedType.song,
      ),
      seedValue: json['seedValue'] as String,
      mood: json['mood'] != null
          ? RadioMood.values.firstWhere(
              (e) => e.value == json['mood'],
              orElse: () => RadioMood.chill,
            )
          : null,
      currentIndex: json['currentIndex'] as int? ?? 0,
      isPlaying: json['isPlaying'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.parse(json['lastPlayedAt'] as String)
          : null,
      playCount: json['playCount'] as int? ?? 0,
      skippedSongIds: List<String>.from(json['skippedSongIds'] ?? []),
      likedSongIds: List<String>.from(json['likedSongIds'] ?? []),
      autoRefresh: json['autoRefresh'] as bool? ?? true,
      minQueueSize: json['minQueueSize'] as int? ?? 5,
    );
  }
}

/// Parameters for creating a new radio station
class RadioStationParams {
  final RadioSeedType seedType;
  final String seedValue;
  final RadioMood? mood;
  final int initialQueueSize;
  final bool includeExplicit;
  final List<String>? excludeArtists;
  final List<String>? excludeGenres;
  final int? minYear;
  final int? maxYear;
  final double? minPopularity;
  final double? maxPopularity;

  const RadioStationParams({
    required this.seedType,
    required this.seedValue,
    this.mood,
    this.initialQueueSize = 25,
    this.includeExplicit = true,
    this.excludeArtists,
    this.excludeGenres,
    this.minYear,
    this.maxYear,
    this.minPopularity,
    this.maxPopularity,
  });
}
