const int _maxStatsEpochMs = 8640000000000000;
final RegExp _unsafeStatsChars = RegExp(
  r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060\u2066-\u2069\uFEFF]',
);
final RegExp _reservedDunderStatsKey = RegExp(r'^__.*__$');

String _cleanStatsText(dynamic raw, {int maxChars = 512}) {
  if (raw == null) return '';
  final cleaned = raw.toString().replaceAll(_unsafeStatsChars, '').trim();
  return cleaned.length <= maxChars ? cleaned : cleaned.substring(0, maxChars);
}

String? _cleanNullableStatsUrl(dynamic raw) {
  if (raw == null) return null;
  final candidate = _cleanStatsText(raw, maxChars: 2048);
  if (candidate.isEmpty) return null;
  final lower = candidate.toLowerCase();
  if (lower.startsWith('javascript:') ||
      lower.startsWith('vbscript:') ||
      lower.startsWith('data:text/html') ||
      lower.startsWith('file:')) {
    return null;
  }
  return candidate;
}

int _parseStatsNonNegInt(dynamic v, [int fallback = 0]) {
  int? parsed;
  if (v is num) {
    if (v.isFinite) parsed = v is int ? v : v.toInt();
  } else if (v is String) {
    final t = v.trim();
    parsed = int.tryParse(t);
    if (parsed == null) {
      final d = double.tryParse(t);
      if (d != null && d.isFinite) parsed = d.toInt();
    }
  }
  if (parsed == null || parsed < 0) return fallback;
  return parsed;
}

double _parseStatsNonNegDouble(dynamic v, [double fallback = 0.0]) {
  double? parsed;
  if (v is num) {
    parsed = v.toDouble();
  } else if (v is String) {
    parsed = double.tryParse(v.trim());
  }
  if (parsed == null || !parsed.isFinite || parsed < 0) return fallback;
  return parsed;
}

DateTime? _tryParseStatsDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is num && raw.isFinite) {
    final ms = raw.toInt();
    if (ms > 0 && ms <= _maxStatsEpochMs) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
  }
  return DateTime.tryParse(raw.toString().trim());
}

bool _isSafeMapKey(String key) =>
    key.isNotEmpty &&
    key.length <= 128 &&
    !_unsafeStatsChars.hasMatch(key) &&
    key != '__proto__' &&
    key != 'constructor' &&
    key != 'prototype' &&
    !_reservedDunderStatsKey.hasMatch(key);

Map<int, int> _parseStatsIntMap(
  dynamic raw, {
  required int minKey,
  required int maxKey,
}) {
  if (raw is! Map) return const {};
  final out = <int, int>{};
  for (final entry in raw.entries.take(64)) {
    final rawKey = entry.key;
    int? key;
    if (rawKey is num && rawKey.isFinite) {
      key = rawKey.toInt();
    } else if (rawKey != null) {
      final str = rawKey.toString().trim();
      if (!_isSafeMapKey(str)) continue;
      key = int.tryParse(str);
    }
    if (key == null || key < minKey || key > maxKey) continue;
    out[key] = _parseStatsNonNegInt(entry.value);
  }
  return out;
}

Map<String, double> _parseMoodDistribution(dynamic raw) {
  if (raw is! Map) return const {};
  final out = <String, double>{};
  for (final entry in raw.entries.take(64)) {
    final rawKey = entry.key?.toString() ?? '';
    if (_unsafeStatsChars.hasMatch(rawKey)) continue;
    final key = rawKey.trim();
    if (!_isSafeMapKey(key)) continue;
    double? value;
    final rawVal = entry.value;
    if (rawVal is num && rawVal.isFinite) {
      value = rawVal.toDouble();
    } else if (rawVal is String) {
      final d = double.tryParse(rawVal.trim());
      if (d != null && d.isFinite) value = d;
    }
    if (value != null && value >= 0) {
      out[key] = value;
    }
  }
  return out;
}

/// Comprehensive listening statistics for a user
class ListeningStats {
  /// Total listening time in milliseconds
  final int totalListeningTimeMs;

  /// Listening time today
  final int todayListeningTimeMs;

  /// Listening time this week
  final int weekListeningTimeMs;

  /// Listening time this month
  final int monthListeningTimeMs;

  /// Total songs played
  final int totalSongsPlayed;

  /// Unique songs played
  final int uniqueSongsPlayed;

  /// Total artists listened to
  final int totalArtists;

  /// Total genres explored
  final int totalGenres;

  /// Top artists with play counts
  final List<ArtistStat> topArtists;

  /// Top songs with play counts
  final List<SongStat> topSongs;

  /// Top genres with listening time
  final List<GenreStat> topGenres;

  /// Listening by hour of day (0-23)
  final Map<int, int> listeningByHour;

  /// Listening by day of week (1-7, Monday = 1)
  final Map<int, int> listeningByDay;

  /// Listening streak (consecutive days)
  final int currentStreak;

  /// Longest streak
  final int longestStreak;

  /// Last updated timestamp
  final DateTime lastUpdated;

  /// Mood distribution
  final Map<String, double> moodDistribution;

  /// Average session length in milliseconds
  final int avgSessionLengthMs;

  /// Favorite time to listen
  final String favoriteListeningTime;

  /// Estimated songs for wrapped
  final int estimatedYearlyWrappedSongs;

  const ListeningStats({
    this.totalListeningTimeMs = 0,
    this.todayListeningTimeMs = 0,
    this.weekListeningTimeMs = 0,
    this.monthListeningTimeMs = 0,
    this.totalSongsPlayed = 0,
    this.uniqueSongsPlayed = 0,
    this.totalArtists = 0,
    this.totalGenres = 0,
    this.topArtists = const [],
    this.topSongs = const [],
    this.topGenres = const [],
    this.listeningByHour = const {},
    this.listeningByDay = const {},
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastUpdated,
    this.moodDistribution = const {},
    this.avgSessionLengthMs = 0,
    this.favoriteListeningTime = '',
    this.estimatedYearlyWrappedSongs = 0,
  });

  /// Format total listening time as human readable string
  String get formattedTotalTime {
    final safeMs = totalListeningTimeMs < 0 ? 0 : totalListeningTimeMs;
    final hours = safeMs ~/ (1000 * 60 * 60);
    final minutes = (safeMs ~/ (1000 * 60)) % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Format today's listening time
  String get formattedTodayTime {
    final safeMs = todayListeningTimeMs < 0 ? 0 : todayListeningTimeMs;
    final hours = safeMs ~/ (1000 * 60 * 60);
    final minutes = (safeMs ~/ (1000 * 60)) % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  ListeningStats copyWith({
    int? totalListeningTimeMs,
    int? todayListeningTimeMs,
    int? weekListeningTimeMs,
    int? monthListeningTimeMs,
    int? totalSongsPlayed,
    int? uniqueSongsPlayed,
    int? totalArtists,
    int? totalGenres,
    List<ArtistStat>? topArtists,
    List<SongStat>? topSongs,
    List<GenreStat>? topGenres,
    Map<int, int>? listeningByHour,
    Map<int, int>? listeningByDay,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastUpdated,
    Map<String, double>? moodDistribution,
    int? avgSessionLengthMs,
    String? favoriteListeningTime,
    int? estimatedYearlyWrappedSongs,
  }) {
    return ListeningStats(
      totalListeningTimeMs: totalListeningTimeMs ?? this.totalListeningTimeMs,
      todayListeningTimeMs: todayListeningTimeMs ?? this.todayListeningTimeMs,
      weekListeningTimeMs: weekListeningTimeMs ?? this.weekListeningTimeMs,
      monthListeningTimeMs: monthListeningTimeMs ?? this.monthListeningTimeMs,
      totalSongsPlayed: totalSongsPlayed ?? this.totalSongsPlayed,
      uniqueSongsPlayed: uniqueSongsPlayed ?? this.uniqueSongsPlayed,
      totalArtists: totalArtists ?? this.totalArtists,
      totalGenres: totalGenres ?? this.totalGenres,
      topArtists: topArtists ?? this.topArtists,
      topSongs: topSongs ?? this.topSongs,
      topGenres: topGenres ?? this.topGenres,
      listeningByHour: listeningByHour ?? this.listeningByHour,
      listeningByDay: listeningByDay ?? this.listeningByDay,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      moodDistribution: moodDistribution ?? this.moodDistribution,
      avgSessionLengthMs: avgSessionLengthMs ?? this.avgSessionLengthMs,
      favoriteListeningTime:
          favoriteListeningTime ?? this.favoriteListeningTime,
      estimatedYearlyWrappedSongs:
          estimatedYearlyWrappedSongs ?? this.estimatedYearlyWrappedSongs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalListeningTimeMs': totalListeningTimeMs,
      'todayListeningTimeMs': todayListeningTimeMs,
      'weekListeningTimeMs': weekListeningTimeMs,
      'monthListeningTimeMs': monthListeningTimeMs,
      'totalSongsPlayed': totalSongsPlayed,
      'uniqueSongsPlayed': uniqueSongsPlayed,
      'totalArtists': totalArtists,
      'totalGenres': totalGenres,
      'topArtists': topArtists.map((e) => e.toJson()).toList(),
      'topSongs': topSongs.map((e) => e.toJson()).toList(),
      'topGenres': topGenres.map((e) => e.toJson()).toList(),
      'listeningByHour':
          listeningByHour.map((k, v) => MapEntry(k.toString(), v)),
      'listeningByDay': listeningByDay.map((k, v) => MapEntry(k.toString(), v)),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastUpdated': lastUpdated.toIso8601String(),
      'moodDistribution': moodDistribution,
      'avgSessionLengthMs': avgSessionLengthMs,
      'favoriteListeningTime': favoriteListeningTime,
      'estimatedYearlyWrappedSongs': estimatedYearlyWrappedSongs,
    };
  }

  factory ListeningStats.fromJson(Map<String, dynamic> json) {
    final topArtists = <ArtistStat>[];
    if (json['topArtists'] is Iterable) {
      for (final e in (json['topArtists'] as Iterable).take(500)) {
        if (e is Map) {
          topArtists.add(ArtistStat.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    final topSongs = <SongStat>[];
    if (json['topSongs'] is Iterable) {
      for (final e in (json['topSongs'] as Iterable).take(500)) {
        if (e is Map) {
          topSongs.add(SongStat.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    final topGenres = <GenreStat>[];
    if (json['topGenres'] is Iterable) {
      for (final e in (json['topGenres'] as Iterable).take(500)) {
        if (e is Map) {
          topGenres.add(GenreStat.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return ListeningStats(
      totalListeningTimeMs: _parseStatsNonNegInt(json['totalListeningTimeMs']),
      todayListeningTimeMs: _parseStatsNonNegInt(json['todayListeningTimeMs']),
      weekListeningTimeMs: _parseStatsNonNegInt(json['weekListeningTimeMs']),
      monthListeningTimeMs: _parseStatsNonNegInt(json['monthListeningTimeMs']),
      totalSongsPlayed: _parseStatsNonNegInt(json['totalSongsPlayed']),
      uniqueSongsPlayed: _parseStatsNonNegInt(json['uniqueSongsPlayed']),
      totalArtists: _parseStatsNonNegInt(json['totalArtists']),
      totalGenres: _parseStatsNonNegInt(json['totalGenres']),
      topArtists: topArtists,
      topSongs: topSongs,
      topGenres: topGenres,
      listeningByHour: _parseStatsIntMap(
        json['listeningByHour'],
        minKey: 0,
        maxKey: 23,
      ),
      listeningByDay: _parseStatsIntMap(
        json['listeningByDay'],
        minKey: 0,
        maxKey: 7,
      ),
      currentStreak: _parseStatsNonNegInt(json['currentStreak']),
      longestStreak: _parseStatsNonNegInt(json['longestStreak']),
      lastUpdated: _tryParseStatsDate(json['lastUpdated']) ?? DateTime.now(),
      moodDistribution: _parseMoodDistribution(json['moodDistribution']),
      avgSessionLengthMs: _parseStatsNonNegInt(json['avgSessionLengthMs']),
      favoriteListeningTime: _cleanStatsText(
        json['favoriteListeningTime'],
        maxChars: 128,
      ),
      estimatedYearlyWrappedSongs:
          _parseStatsNonNegInt(json['estimatedYearlyWrappedSongs']),
    );
  }

  factory ListeningStats.empty() {
    return ListeningStats(lastUpdated: DateTime.now());
  }
}

/// Artist listening statistics
class ArtistStat {
  final String artistId;
  final String artistName;
  final String? imageUrl;
  final int playCount;
  final int listeningTimeMs;
  final int rank;

  const ArtistStat({
    required this.artistId,
    required this.artistName,
    this.imageUrl,
    required this.playCount,
    required this.listeningTimeMs,
    this.rank = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'artistId': artistId,
      'artistName': artistName,
      'imageUrl': imageUrl,
      'playCount': playCount,
      'listeningTimeMs': listeningTimeMs,
      'rank': rank,
    };
  }

  factory ArtistStat.fromJson(Map<String, dynamic> json) {
    return ArtistStat(
      artistId: _cleanStatsText(json['artistId'], maxChars: 256),
      artistName: _cleanStatsText(json['artistName'], maxChars: 256),
      imageUrl: _cleanNullableStatsUrl(json['imageUrl']),
      playCount: _parseStatsNonNegInt(json['playCount']),
      listeningTimeMs: _parseStatsNonNegInt(json['listeningTimeMs']),
      rank: _parseStatsNonNegInt(json['rank']),
    );
  }
}

/// Song listening statistics
class SongStat {
  final String songId;
  final String songTitle;
  final String artistName;
  final String? imageUrl;
  final int playCount;
  final int listeningTimeMs;
  final DateTime? lastPlayedAt;
  final int rank;

  const SongStat({
    required this.songId,
    required this.songTitle,
    required this.artistName,
    this.imageUrl,
    required this.playCount,
    required this.listeningTimeMs,
    this.lastPlayedAt,
    this.rank = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'songTitle': songTitle,
      'artistName': artistName,
      'imageUrl': imageUrl,
      'playCount': playCount,
      'listeningTimeMs': listeningTimeMs,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'rank': rank,
    };
  }

  factory SongStat.fromJson(Map<String, dynamic> json) {
    return SongStat(
      songId: _cleanStatsText(json['songId'], maxChars: 256),
      songTitle: _cleanStatsText(json['songTitle'], maxChars: 256),
      artistName: _cleanStatsText(json['artistName'], maxChars: 256),
      imageUrl: _cleanNullableStatsUrl(json['imageUrl']),
      playCount: _parseStatsNonNegInt(json['playCount']),
      listeningTimeMs: _parseStatsNonNegInt(json['listeningTimeMs']),
      lastPlayedAt: _tryParseStatsDate(json['lastPlayedAt']),
      rank: _parseStatsNonNegInt(json['rank']),
    );
  }
}

/// Genre listening statistics
class GenreStat {
  final String genre;
  final int playCount;
  final int listeningTimeMs;
  final double percentage;
  final int rank;

  const GenreStat({
    required this.genre,
    required this.playCount,
    required this.listeningTimeMs,
    this.percentage = 0,
    this.rank = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'genre': genre,
      'playCount': playCount,
      'listeningTimeMs': listeningTimeMs,
      'percentage': percentage.isFinite ? percentage : 0.0,
      'rank': rank,
    };
  }

  factory GenreStat.fromJson(Map<String, dynamic> json) {
    return GenreStat(
      genre: _cleanStatsText(json['genre'], maxChars: 128),
      playCount: _parseStatsNonNegInt(json['playCount']),
      listeningTimeMs: _parseStatsNonNegInt(json['listeningTimeMs']),
      percentage: _parseStatsNonNegDouble(json['percentage']),
      rank: _parseStatsNonNegInt(json['rank']),
    );
  }
}

/// Daily listening activity
class DailyActivity {
  final DateTime date;
  final int listeningTimeMs;
  final int songsPlayed;
  final List<String> topArtistIds;

  const DailyActivity({
    required this.date,
    this.listeningTimeMs = 0,
    this.songsPlayed = 0,
    this.topArtistIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'listeningTimeMs': listeningTimeMs,
      'songsPlayed': songsPlayed,
      'topArtistIds': topArtistIds,
    };
  }

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    final ids = <String>[];
    if (json['topArtistIds'] is Iterable) {
      for (final raw in (json['topArtistIds'] as Iterable).take(200)) {
        final id = _cleanStatsText(raw, maxChars: 256);
        if (id.isNotEmpty) ids.add(id);
      }
    }
    return DailyActivity(
      date: _tryParseStatsDate(json['date']) ?? DateTime.now(),
      listeningTimeMs: _parseStatsNonNegInt(json['listeningTimeMs']),
      songsPlayed: _parseStatsNonNegInt(json['songsPlayed']),
      topArtistIds: ids,
    );
  }
}
