import 'package:audio_service/audio_service.dart';

import '../models/listening_stats.dart';

/// Abstract service for tracking and retrieving listening statistics
abstract class ListeningStatsService {
  /// Get comprehensive listening statistics
  Future<ListeningStats> getStats();

  /// Get stats for a specific time period
  Future<ListeningStats> getStatsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get today's listening activity
  Future<DailyActivity> getTodayActivity();

  /// Get listening activity for a date range
  Future<List<DailyActivity>> getActivityHistory({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get top artists for a period
  Future<List<ArtistStat>> getTopArtists({
    int limit = 10,
    StatsPeriod period = StatsPeriod.allTime,
  });

  /// Get top songs for a period
  Future<List<SongStat>> getTopSongs({
    int limit = 10,
    StatsPeriod period = StatsPeriod.allTime,
  });

  /// Get top genres for a period
  Future<List<GenreStat>> getTopGenres({
    int limit = 10,
    StatsPeriod period = StatsPeriod.allTime,
  });

  /// Get listening time by hour of day
  Future<Map<int, int>> getListeningByHour({
    StatsPeriod period = StatsPeriod.month,
  });

  /// Get listening time by day of week
  Future<Map<int, int>> getListeningByDay({
    StatsPeriod period = StatsPeriod.month,
  });

  /// Get current listening streak
  Future<int> getCurrentStreak();

  /// Get longest listening streak
  Future<int> getLongestStreak();

  /// Get mood distribution
  Future<Map<String, double>> getMoodDistribution({
    StatsPeriod period = StatsPeriod.month,
  });

  // ============ Tracking ============

  /// Record a play event
  Future<void> recordPlay(MediaItem mediaItem);

  /// Record listening time
  Future<void> recordListeningTime(
    String mediaItemId,
    Duration duration,
  );

  /// Record a skip event
  Future<void> recordSkip(String mediaItemId);

  /// Record a complete play (listened to > 80%)
  Future<void> recordComplete(String mediaItemId);

  /// Update daily streak
  Future<void> updateStreak();

  // ============ Wrapped / Year in Review ============

  /// Get yearly wrapped summary
  Future<WrappedSummary> getWrapped(int year);

  /// Check if wrapped is available for year
  Future<bool> isWrappedAvailable(int year);

  // ============ Goals & Achievements ============

  /// Get active listening goals
  Future<List<ListeningGoal>> getActiveGoals();

  /// Set a listening goal
  Future<void> setGoal(ListeningGoal goal);

  /// Get achievements
  Future<List<Achievement>> getAchievements();

  /// Check for new achievements
  Future<List<Achievement>> checkNewAchievements();

  // ============ Export ============

  /// Export listening history
  Future<String> exportHistory({
    required DateTime startDate,
    required DateTime endDate,
    ExportFormat format = ExportFormat.json,
  });
}

/// Time period for statistics
enum StatsPeriod {
  today('today', 'Today'),
  week('week', 'This Week'),
  month('month', 'This Month'),
  threeMonths('3months', 'Last 3 Months'),
  sixMonths('6months', 'Last 6 Months'),
  year('year', 'This Year'),
  allTime('all_time', 'All Time');

  final String value;
  final String displayName;

  const StatsPeriod(this.value, this.displayName);
}

/// Export format options
enum ExportFormat {
  json('json', 'JSON'),
  csv('csv', 'CSV');

  final String value;
  final String displayName;

  const ExportFormat(this.value, this.displayName);
}

/// Yearly wrapped summary (like Spotify Wrapped)
class WrappedSummary {
  final int year;
  final int totalMinutesListened;
  final int totalSongsPlayed;
  final int totalArtists;
  final int totalGenres;
  final List<ArtistStat> topArtists;
  final List<SongStat> topSongs;
  final List<GenreStat> topGenres;
  final String topListeningTime;
  final String topListeningDay;
  final String listeningPersonality;
  final Map<String, dynamic> funFacts;
  final bool isComplete;

  const WrappedSummary({
    required this.year,
    required this.totalMinutesListened,
    required this.totalSongsPlayed,
    required this.totalArtists,
    required this.totalGenres,
    required this.topArtists,
    required this.topSongs,
    required this.topGenres,
    required this.topListeningTime,
    required this.topListeningDay,
    required this.listeningPersonality,
    this.funFacts = const {},
    this.isComplete = false,
  });

  /// Get listening time as formatted string
  String get formattedListeningTime {
    final hours = totalMinutesListened ~/ 60;
    final minutes = totalMinutesListened % 60;
    return '${hours}h ${minutes}m';
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'totalMinutesListened': totalMinutesListened,
      'totalSongsPlayed': totalSongsPlayed,
      'totalArtists': totalArtists,
      'totalGenres': totalGenres,
      'topArtists': topArtists.map((e) => e.toJson()).toList(),
      'topSongs': topSongs.map((e) => e.toJson()).toList(),
      'topGenres': topGenres.map((e) => e.toJson()).toList(),
      'topListeningTime': topListeningTime,
      'topListeningDay': topListeningDay,
      'listeningPersonality': listeningPersonality,
      'funFacts': funFacts,
      'isComplete': isComplete,
    };
  }
}

/// Listening goal
class ListeningGoal {
  final String id;
  final ListeningGoalType type;
  final int targetValue;
  final int currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;

  const ListeningGoal({
    required this.id,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
  });

  double get progress => currentValue / targetValue;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}

/// Type of listening goal
enum ListeningGoalType {
  dailyMinutes('daily_minutes', 'Listen for X minutes daily'),
  weeklyMinutes('weekly_minutes', 'Listen for X minutes this week'),
  discoverArtists('discover_artists', 'Discover X new artists'),
  discoverSongs('discover_songs', 'Discover X new songs'),
  completeAlbum('complete_album', 'Listen to a full album'),
  listeningStreak('streak', 'Maintain X day streak');

  final String value;
  final String displayName;

  const ListeningGoalType(this.value, this.displayName);
}

/// Achievement unlocked by user
class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final AchievementTier tier;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final double progress;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.tier,
    this.unlockedAt,
    this.isUnlocked = false,
    this.progress = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'tier': tier.value,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isUnlocked': isUnlocked,
      'progress': progress,
    };
  }
}

/// Achievement tier
enum AchievementTier {
  bronze('bronze', 'Bronze'),
  silver('silver', 'Silver'),
  gold('gold', 'Gold'),
  platinum('platinum', 'Platinum'),
  diamond('diamond', 'Diamond');

  final String value;
  final String displayName;

  const AchievementTier(this.value, this.displayName);
}
