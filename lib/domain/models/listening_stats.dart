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
    final hours = totalListeningTimeMs ~/ (1000 * 60 * 60);
    final minutes = (totalListeningTimeMs ~/ (1000 * 60)) % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Format today's listening time
  String get formattedTodayTime {
    final hours = todayListeningTimeMs ~/ (1000 * 60 * 60);
    final minutes = (todayListeningTimeMs ~/ (1000 * 60)) % 60;
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
    return ListeningStats(
      totalListeningTimeMs: json['totalListeningTimeMs'] as int? ?? 0,
      todayListeningTimeMs: json['todayListeningTimeMs'] as int? ?? 0,
      weekListeningTimeMs: json['weekListeningTimeMs'] as int? ?? 0,
      monthListeningTimeMs: json['monthListeningTimeMs'] as int? ?? 0,
      totalSongsPlayed: json['totalSongsPlayed'] as int? ?? 0,
      uniqueSongsPlayed: json['uniqueSongsPlayed'] as int? ?? 0,
      totalArtists: json['totalArtists'] as int? ?? 0,
      totalGenres: json['totalGenres'] as int? ?? 0,
      topArtists: (json['topArtists'] as List?)
              ?.map((e) => ArtistStat.fromJson(e))
              .toList() ??
          [],
      topSongs: (json['topSongs'] as List?)
              ?.map((e) => SongStat.fromJson(e))
              .toList() ??
          [],
      topGenres: (json['topGenres'] as List?)
              ?.map((e) => GenreStat.fromJson(e))
              .toList() ??
          [],
      listeningByHour: (json['listeningByHour'] as Map?)
              ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
          {},
      listeningByDay: (json['listeningByDay'] as Map?)
              ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
          {},
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
      moodDistribution:
          Map<String, double>.from(json['moodDistribution'] ?? {}),
      avgSessionLengthMs: json['avgSessionLengthMs'] as int? ?? 0,
      favoriteListeningTime: json['favoriteListeningTime'] as String? ?? '',
      estimatedYearlyWrappedSongs:
          json['estimatedYearlyWrappedSongs'] as int? ?? 0,
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
      artistId: json['artistId'] as String,
      artistName: json['artistName'] as String,
      imageUrl: json['imageUrl'] as String?,
      playCount: json['playCount'] as int? ?? 0,
      listeningTimeMs: json['listeningTimeMs'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
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
      songId: json['songId'] as String,
      songTitle: json['songTitle'] as String,
      artistName: json['artistName'] as String,
      imageUrl: json['imageUrl'] as String?,
      playCount: json['playCount'] as int? ?? 0,
      listeningTimeMs: json['listeningTimeMs'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.parse(json['lastPlayedAt'] as String)
          : null,
      rank: json['rank'] as int? ?? 0,
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
      'percentage': percentage,
      'rank': rank,
    };
  }

  factory GenreStat.fromJson(Map<String, dynamic> json) {
    return GenreStat(
      genre: json['genre'] as String,
      playCount: json['playCount'] as int? ?? 0,
      listeningTimeMs: json['listeningTimeMs'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      rank: json['rank'] as int? ?? 0,
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
    return DailyActivity(
      date: DateTime.parse(json['date'] as String),
      listeningTimeMs: json['listeningTimeMs'] as int? ?? 0,
      songsPlayed: json['songsPlayed'] as int? ?? 0,
      topArtistIds: List<String>.from(json['topArtistIds'] ?? []),
    );
  }
}
