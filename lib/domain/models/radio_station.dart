import 'package:audio_service/audio_service.dart';

import '../../utils/enums/radio_seed_type.dart';

const int _maxRadioEpochMs = 8640000000000000;
final RegExp _unsafeRadioTextChars = RegExp(
  r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060\u2066-\u2069\uFEFF]',
);
final RegExp _radioLlmArtifacts = RegExp(
  r'<\|channel>\s*thought\b[\s\S]*?(?:<channel\|>|$)|<\|/?(?:turn|channel|eot)\|?>?|<\s*/?\s*(?:think|thought|memory_recall|system_context)\b[^>]*>|\[\s*/?\s*(?:MEMORY_RECALL|BIOCHIP)\b[^\]]*\]',
  caseSensitive: false,
);

String _cleanRadioText(dynamic raw, {int maxChars = 512}) {
  if (raw == null) return '';
  final cleaned = raw
      .toString()
      .replaceAll(_radioLlmArtifacts, ' ')
      .replaceAll(_unsafeRadioTextChars, '')
      .trim();
  return cleaned.length <= maxChars ? cleaned : cleaned.substring(0, maxChars);
}

String _cleanRadioUrl(dynamic raw) {
  final candidate = _cleanRadioText(raw, maxChars: 2048);
  if (candidate.isEmpty) return '';
  final lower = candidate.toLowerCase();
  if (lower.startsWith('javascript:') ||
      lower.startsWith('vbscript:') ||
      lower.startsWith('data:text/html') ||
      lower.startsWith('file:')) {
    return '';
  }
  return candidate;
}

int _parseRadioInt(dynamic v, int fallback) {
  if (v is num) {
    if (!v.isFinite) return fallback;
    return v is int ? v : v.toInt();
  }
  if (v is String) {
    final t = v.trim();
    final asInt = int.tryParse(t);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(t);
    if (asDouble != null && asDouble.isFinite) return asDouble.toInt();
  }
  return fallback;
}

bool _parseRadioBool(dynamic v, bool fallback) {
  if (v is bool) return v;
  if (v is String) {
    final lower = v.trim().toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  if (v is num && v.isFinite) return v != 0;
  return fallback;
}

DateTime? _tryParseRadioDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is num && raw.isFinite) {
    final ms = raw.toInt();
    if (ms > 0 && ms <= _maxRadioEpochMs) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
  }
  return DateTime.tryParse(raw.toString().trim());
}

List<String> _cleanRadioIds(dynamic raw) {
  if (raw is! Iterable) return const [];
  final out = <String>[];
  for (final item in raw.take(2000)) {
    final id = _cleanRadioText(item, maxChars: 256);
    if (id.isNotEmpty) out.add(id);
  }
  return out;
}

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
    final safeIndex = currentIndex < 0 ? 0 : currentIndex;
    final remainingSongs = queue.length - safeIndex;
    return remainingSongs <= minQueueSize;
  }

  /// Get remaining songs in queue
  List<MediaItem> get upcomingSongs {
    if (queue.isEmpty || currentIndex < 0 || currentIndex >= queue.length - 1) {
      return [];
    }
    return queue.sublist(currentIndex + 1);
  }

  /// Get current song
  MediaItem? get currentSong {
    if (queue.isEmpty || currentIndex < 0 || currentIndex >= queue.length) {
      return null;
    }
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
      'playCount': playCount < 0 ? 0 : playCount,
      'skippedSongIds': skippedSongIds,
      'likedSongIds': likedSongIds,
      'autoRefresh': autoRefresh,
      'minQueueSize': minQueueSize < 0 ? 0 : minQueueSize,
    };
  }

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    final rawMood = json['mood']?.toString().trim();
    return RadioStation(
      id: _cleanRadioText(json['id'], maxChars: 256),
      name: _cleanRadioText(json['name'], maxChars: 256),
      description: _cleanRadioText(json['description'], maxChars: 2048),
      imageUrl: _cleanRadioUrl(json['imageUrl']),
      seedType: RadioSeedType.values.firstWhere(
        (e) => e.value == json['seedType']?.toString().trim(),
        orElse: () => RadioSeedType.song,
      ),
      seedValue: _cleanRadioText(json['seedValue'], maxChars: 512),
      mood: rawMood != null && rawMood.isNotEmpty
          ? RadioMood.values.firstWhere(
              (e) => e.value == rawMood,
              orElse: () => RadioMood.chill,
            )
          : null,
      currentIndex: _parseRadioInt(json['currentIndex'], 0),
      isPlaying: _parseRadioBool(json['isPlaying'], false),
      createdAt: _tryParseRadioDate(json['createdAt']) ?? DateTime.now(),
      lastPlayedAt: _tryParseRadioDate(json['lastPlayedAt']),
      playCount: _parseRadioInt(json['playCount'], 0).clamp(0, 1000000000),
      skippedSongIds: _cleanRadioIds(json['skippedSongIds']),
      likedSongIds: _cleanRadioIds(json['likedSongIds']),
      autoRefresh: _parseRadioBool(json['autoRefresh'], true),
      minQueueSize: _parseRadioInt(json['minQueueSize'], 5).clamp(0, 1000),
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
