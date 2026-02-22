import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:sint/sint.dart';

import '../../domain/models/listening_stats.dart';
import '../../domain/use_cases/listening_stats_service.dart';

/// Controller implementation for listening statistics
class ListeningStatsController extends SintController
    implements ListeningStatsService {
  static const String _boxName = 'listening_stats';
  static const String _statsKey = 'stats';
  static const String _historyKey = 'history';
  static const String _goalsKey = 'goals';
  static const String _achievementsKey = 'achievements';
  static const String _dailyKey = 'daily_activity';
  static const String _lastListenDateKey = 'last_listen_date';

  Box? _box;

  final _stats = Rxn<ListeningStats>();
  final _todayActivity = Rxn<DailyActivity>();
  final _currentStreak = 0.obs;
  final _goals = <ListeningGoal>[].obs;
  final _achievements = <Achievement>[].obs;
  final _isLoading = false.obs;

  /// Current stats
  ListeningStats? get stats => _stats.value;

  /// Today's activity
  DailyActivity? get todayActivity => _todayActivity.value;

  /// Current streak
  int get streak => _currentStreak.value;

  /// Active goals
  List<ListeningGoal> get goals => _goals;

  /// Achievements
  List<Achievement> get achievements => _achievements;

  /// Loading state
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _initHive();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox(_boxName);
    await _loadStats();
    await _loadGoals();
    await _loadAchievements();
    await _initTodayActivity();
  }

  Future<void> _loadStats() async {
    final data = _box?.get(_statsKey) as Map?;
    if (data != null) {
      _stats.value = ListeningStats.fromJson(Map<String, dynamic>.from(data));
    } else {
      _stats.value = ListeningStats.empty();
    }
    _currentStreak.value = _stats.value?.currentStreak ?? 0;
  }

  Future<void> _loadGoals() async {
    final data = _box?.get(_goalsKey) as List?;
    if (data != null) {
      _goals.value = data
          .map((e) => ListeningGoal(
                id: e['id'],
                type: ListeningGoalType.values.firstWhere(
                  (t) => t.value == e['type'],
                  orElse: () => ListeningGoalType.dailyMinutes,
                ),
                targetValue: e['targetValue'],
                currentValue: e['currentValue'] ?? 0,
                startDate: DateTime.parse(e['startDate']),
                endDate: DateTime.parse(e['endDate']),
                isCompleted: e['isCompleted'] ?? false,
              ))
          .toList();
    }
  }

  Future<void> _loadAchievements() async {
    final data = _box?.get(_achievementsKey) as List?;
    if (data != null) {
      _achievements.value = data
          .map((e) => Achievement(
                id: e['id'],
                name: e['name'],
                description: e['description'],
                iconUrl: e['iconUrl'],
                tier: AchievementTier.values.firstWhere(
                  (t) => t.value == e['tier'],
                  orElse: () => AchievementTier.bronze,
                ),
                unlockedAt: e['unlockedAt'] != null
                    ? DateTime.parse(e['unlockedAt'])
                    : null,
                isUnlocked: e['isUnlocked'] ?? false,
                progress: (e['progress'] as num?)?.toDouble() ?? 0,
              ))
          .toList();
    } else {
      _achievements.value = _getDefaultAchievements();
    }
  }

  Future<void> _initTodayActivity() async {
    final today = DateTime.now();
    final todayKey = '${_dailyKey}_${today.year}_${today.month}_${today.day}';

    final data = _box?.get(todayKey) as Map?;
    if (data != null) {
      _todayActivity.value = DailyActivity.fromJson(Map<String, dynamic>.from(data));
    } else {
      _todayActivity.value = DailyActivity(date: today);
    }
  }

  Future<void> _saveStats() async {
    if (_stats.value != null) {
      await _box?.put(_statsKey, _stats.value!.toJson());
    }
  }

  Future<void> _saveTodayActivity() async {
    if (_todayActivity.value != null) {
      final today = _todayActivity.value!.date;
      final todayKey = '${_dailyKey}_${today.year}_${today.month}_${today.day}';
      await _box?.put(todayKey, _todayActivity.value!.toJson());
    }
  }

  Future<void> _saveGoals() async {
    await _box?.put(_goalsKey, _goals.map((g) => g.toJson()).toList());
  }

  Future<void> _saveAchievements() async {
    await _box?.put(_achievementsKey, _achievements.map((a) => a.toJson()).toList());
  }

  // ============ Stats Retrieval ============

  @override
  Future<ListeningStats> getStats() async {
    return _stats.value ?? ListeningStats.empty();
  }

  @override
  Future<ListeningStats> getStatsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // In production, aggregate from daily activity records
    return _stats.value ?? ListeningStats.empty();
  }

  @override
  Future<DailyActivity> getTodayActivity() async {
    return _todayActivity.value ?? DailyActivity(date: DateTime.now());
  }

  @override
  Future<List<DailyActivity>> getActivityHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final activities = <DailyActivity>[];
    var current = startDate;

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      final key = '${_dailyKey}_${current.year}_${current.month}_${current.day}';
      final data = _box?.get(key) as Map?;

      if (data != null) {
        activities.add(DailyActivity.fromJson(Map<String, dynamic>.from(data)));
      } else {
        activities.add(DailyActivity(date: current));
      }

      current = current.add(const Duration(days: 1));
    }

    return activities;
  }

  @override
  Future<List<ArtistStat>> getTopArtists({
    int limit = 10,
    StatsPeriod period = StatsPeriod.allTime,
  }) async {
    return _stats.value?.topArtists.take(limit).toList() ?? [];
  }

  @override
  Future<List<SongStat>> getTopSongs({
    int limit = 10,
    StatsPeriod period = StatsPeriod.allTime,
  }) async {
    return _stats.value?.topSongs.take(limit).toList() ?? [];
  }

  @override
  Future<List<GenreStat>> getTopGenres({
    int limit = 10,
    StatsPeriod period = StatsPeriod.allTime,
  }) async {
    return _stats.value?.topGenres.take(limit).toList() ?? [];
  }

  @override
  Future<Map<int, int>> getListeningByHour({
    StatsPeriod period = StatsPeriod.month,
  }) async {
    return _stats.value?.listeningByHour ?? {};
  }

  @override
  Future<Map<int, int>> getListeningByDay({
    StatsPeriod period = StatsPeriod.month,
  }) async {
    return _stats.value?.listeningByDay ?? {};
  }

  @override
  Future<int> getCurrentStreak() async {
    return _currentStreak.value;
  }

  @override
  Future<int> getLongestStreak() async {
    return _stats.value?.longestStreak ?? 0;
  }

  @override
  Future<Map<String, double>> getMoodDistribution({
    StatsPeriod period = StatsPeriod.month,
  }) async {
    return _stats.value?.moodDistribution ?? {};
  }

  // ============ Tracking ============

  @override
  Future<void> recordPlay(MediaItem mediaItem) async {
    final currentStats = _stats.value ?? ListeningStats.empty();
    final today = _todayActivity.value ?? DailyActivity(date: DateTime.now());

    // Update song stats
    final songStats = List<SongStat>.from(currentStats.topSongs);
    final existingIndex = songStats.indexWhere((s) => s.songId == mediaItem.id);

    if (existingIndex != -1) {
      final existing = songStats[existingIndex];
      songStats[existingIndex] = SongStat(
        songId: existing.songId,
        songTitle: existing.songTitle,
        artistName: existing.artistName,
        imageUrl: existing.imageUrl,
        playCount: existing.playCount + 1,
        listeningTimeMs: existing.listeningTimeMs,
        lastPlayedAt: DateTime.now(),
        rank: existing.rank,
      );
    } else {
      songStats.add(SongStat(
        songId: mediaItem.id,
        songTitle: mediaItem.title,
        artistName: mediaItem.artist ?? '',
        imageUrl: mediaItem.artUri?.toString(),
        playCount: 1,
        listeningTimeMs: 0,
        lastPlayedAt: DateTime.now(),
      ));
    }

    // Sort by play count and assign ranks
    songStats.sort((a, b) => b.playCount.compareTo(a.playCount));
    for (var i = 0; i < songStats.length; i++) {
      songStats[i] = SongStat(
        songId: songStats[i].songId,
        songTitle: songStats[i].songTitle,
        artistName: songStats[i].artistName,
        imageUrl: songStats[i].imageUrl,
        playCount: songStats[i].playCount,
        listeningTimeMs: songStats[i].listeningTimeMs,
        lastPlayedAt: songStats[i].lastPlayedAt,
        rank: i + 1,
      );
    }

    // Update stats
    _stats.value = currentStats.copyWith(
      totalSongsPlayed: currentStats.totalSongsPlayed + 1,
      topSongs: songStats.take(50).toList(),
      lastUpdated: DateTime.now(),
    );

    // Update today's activity
    _todayActivity.value = DailyActivity(
      date: today.date,
      listeningTimeMs: today.listeningTimeMs,
      songsPlayed: today.songsPlayed + 1,
      topArtistIds: today.topArtistIds,
    );

    await _saveStats();
    await _saveTodayActivity();
    await updateStreak();
    await checkNewAchievements();
  }

  @override
  Future<void> recordListeningTime(
    String mediaItemId,
    Duration duration,
  ) async {
    final currentStats = _stats.value ?? ListeningStats.empty();
    final today = _todayActivity.value ?? DailyActivity(date: DateTime.now());
    final durationMs = duration.inMilliseconds;

    // Update listening by hour
    final hour = DateTime.now().hour;
    final byHour = Map<int, int>.from(currentStats.listeningByHour);
    byHour[hour] = (byHour[hour] ?? 0) + durationMs;

    // Update listening by day
    final dayOfWeek = DateTime.now().weekday;
    final byDay = Map<int, int>.from(currentStats.listeningByDay);
    byDay[dayOfWeek] = (byDay[dayOfWeek] ?? 0) + durationMs;

    // Update stats
    _stats.value = currentStats.copyWith(
      totalListeningTimeMs: currentStats.totalListeningTimeMs + durationMs,
      todayListeningTimeMs: currentStats.todayListeningTimeMs + durationMs,
      listeningByHour: byHour,
      listeningByDay: byDay,
      lastUpdated: DateTime.now(),
    );

    // Update today's activity
    _todayActivity.value = DailyActivity(
      date: today.date,
      listeningTimeMs: today.listeningTimeMs + durationMs,
      songsPlayed: today.songsPlayed,
      topArtistIds: today.topArtistIds,
    );

    await _saveStats();
    await _saveTodayActivity();

    // Update goals
    await _updateGoalProgress(durationMs);
  }

  @override
  Future<void> recordSkip(String mediaItemId) async {
    if (mediaItemId.isEmpty) return;
    final skips = Map<String, int>.from(
      _box?.get('song_skips') as Map? ?? {},
    );
    skips[mediaItemId] = (skips[mediaItemId] ?? 0) + 1;
    await _box?.put('song_skips', skips);
  }

  @override
  Future<void> recordComplete(String mediaItemId) async {
    if (mediaItemId.isEmpty) return;
    final completes = Map<String, int>.from(
      _box?.get('song_completes') as Map? ?? {},
    );
    completes[mediaItemId] = (completes[mediaItemId] ?? 0) + 1;
    await _box?.put('song_completes', completes);
  }

  @override
  Future<void> updateStreak() async {
    final lastListenDate = _box?.get(_lastListenDateKey) as String?;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastListenDate == null) {
      _currentStreak.value = 1;
    } else {
      final lastDate = DateTime.parse(lastListenDate);
      final difference = today.difference(lastDate).inDays;

      if (difference == 0) {
        // Same day, no change
      } else if (difference == 1) {
        // Consecutive day
        _currentStreak.value = _currentStreak.value + 1;
      } else {
        // Streak broken
        _currentStreak.value = 1;
      }
    }

    // Update longest streak
    final currentStats = _stats.value ?? ListeningStats.empty();
    if (_currentStreak.value > currentStats.longestStreak) {
      _stats.value = currentStats.copyWith(
        longestStreak: _currentStreak.value,
        currentStreak: _currentStreak.value,
      );
      await _saveStats();
    }

    await _box?.put(_lastListenDateKey, todayStr);
  }

  Future<void> _updateGoalProgress(int listeningTimeMs) async {
    final updatedGoals = _goals.map((goal) {
      if (goal.isCompleted) return goal;

      int newValue = goal.currentValue;

      switch (goal.type) {
        case ListeningGoalType.dailyMinutes:
        case ListeningGoalType.weeklyMinutes:
          newValue += listeningTimeMs ~/ 60000; // Convert to minutes
          break;
        default:
          break;
      }

      final isCompleted = newValue >= goal.targetValue;

      return ListeningGoal(
        id: goal.id,
        type: goal.type,
        targetValue: goal.targetValue,
        currentValue: newValue,
        startDate: goal.startDate,
        endDate: goal.endDate,
        isCompleted: isCompleted,
      );
    }).toList();

    _goals.value = updatedGoals;
    await _saveGoals();
  }

  // ============ Wrapped / Year in Review ============

  @override
  Future<WrappedSummary> getWrapped(int year) async {
    final stats = _stats.value ?? ListeningStats.empty();

    return WrappedSummary(
      year: year,
      totalMinutesListened: stats.totalListeningTimeMs ~/ 60000,
      totalSongsPlayed: stats.totalSongsPlayed,
      totalArtists: stats.totalArtists,
      totalGenres: stats.totalGenres,
      topArtists: stats.topArtists.take(5).toList(),
      topSongs: stats.topSongs.take(5).toList(),
      topGenres: stats.topGenres.take(5).toList(),
      topListeningTime: _getTopListeningTime(stats.listeningByHour),
      topListeningDay: _getTopListeningDay(stats.listeningByDay),
      listeningPersonality: _calculatePersonality(stats),
      isComplete: year < DateTime.now().year,
    );
  }

  @override
  Future<bool> isWrappedAvailable(int year) async {
    return year <= DateTime.now().year;
  }

  String _getTopListeningTime(Map<int, int> byHour) {
    if (byHour.isEmpty) return 'Evening';

    final topHour = byHour.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    if (topHour >= 5 && topHour < 12) return 'Morning';
    if (topHour >= 12 && topHour < 17) return 'Afternoon';
    if (topHour >= 17 && topHour < 21) return 'Evening';
    return 'Night Owl';
  }

  String _getTopListeningDay(Map<int, int> byDay) {
    if (byDay.isEmpty) return 'Weekend';

    final topDay = byDay.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[topDay];
  }

  String _calculatePersonality(ListeningStats stats) {
    if (stats.topGenres.isEmpty) return 'Explorer';

    final topGenre = stats.topGenres.first.genre.toLowerCase();

    if (topGenre.contains('rock') || topGenre.contains('metal')) {
      return 'Rockstar';
    } else if (topGenre.contains('pop')) {
      return 'Trend Setter';
    } else if (topGenre.contains('hip') || topGenre.contains('rap')) {
      return 'Beat Maker';
    } else if (topGenre.contains('electronic') || topGenre.contains('edm')) {
      return 'Night Owl';
    } else if (topGenre.contains('classical') || topGenre.contains('jazz')) {
      return 'Connoisseur';
    } else if (topGenre.contains('indie')) {
      return 'Indie Soul';
    }

    return 'Music Lover';
  }

  // ============ Goals & Achievements ============

  @override
  Future<List<ListeningGoal>> getActiveGoals() async {
    return _goals.where((g) => !g.isCompleted).toList();
  }

  @override
  Future<void> setGoal(ListeningGoal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
    } else {
      _goals.add(goal);
    }
    await _saveGoals();
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    return _achievements.toList();
  }

  @override
  Future<List<Achievement>> checkNewAchievements() async {
    final newlyUnlocked = <Achievement>[];
    final stats = _stats.value ?? ListeningStats.empty();

    final updatedAchievements = _achievements.map((achievement) {
      if (achievement.isUnlocked) return achievement;

      final progress = _calculateAchievementProgress(achievement.id, stats);
      final isUnlocked = progress >= 1.0;

      if (isUnlocked && !achievement.isUnlocked) {
        final unlocked = Achievement(
          id: achievement.id,
          name: achievement.name,
          description: achievement.description,
          iconUrl: achievement.iconUrl,
          tier: achievement.tier,
          unlockedAt: DateTime.now(),
          isUnlocked: true,
          progress: 1.0,
        );
        newlyUnlocked.add(unlocked);
        return unlocked;
      }

      return Achievement(
        id: achievement.id,
        name: achievement.name,
        description: achievement.description,
        iconUrl: achievement.iconUrl,
        tier: achievement.tier,
        unlockedAt: achievement.unlockedAt,
        isUnlocked: achievement.isUnlocked,
        progress: progress,
      );
    }).toList();

    _achievements.value = updatedAchievements;
    await _saveAchievements();

    return newlyUnlocked;
  }

  double _calculateAchievementProgress(String achievementId, ListeningStats stats) {
    switch (achievementId) {
      case 'first_song':
        return stats.totalSongsPlayed > 0 ? 1.0 : 0;
      case 'play_100_songs':
        return (stats.totalSongsPlayed / 100).clamp(0, 1);
      case 'play_1000_songs':
        return (stats.totalSongsPlayed / 1000).clamp(0, 1);
      case 'listen_1_hour':
        return (stats.totalListeningTimeMs / 3600000).clamp(0, 1);
      case 'listen_100_hours':
        return (stats.totalListeningTimeMs / 360000000).clamp(0, 1);
      case 'streak_7_days':
        return (stats.currentStreak / 7).clamp(0, 1);
      case 'streak_30_days':
        return (stats.currentStreak / 30).clamp(0, 1);
      case 'discover_50_artists':
        return (stats.totalArtists / 50).clamp(0, 1);
      default:
        return 0;
    }
  }

  List<Achievement> _getDefaultAchievements() {
    return [
      const Achievement(
        id: 'first_song',
        name: 'First Steps',
        description: 'Play your first song',
        iconUrl: '',
        tier: AchievementTier.bronze,
      ),
      const Achievement(
        id: 'play_100_songs',
        name: 'Music Enthusiast',
        description: 'Play 100 songs',
        iconUrl: '',
        tier: AchievementTier.silver,
      ),
      const Achievement(
        id: 'play_1000_songs',
        name: 'Music Addict',
        description: 'Play 1,000 songs',
        iconUrl: '',
        tier: AchievementTier.gold,
      ),
      const Achievement(
        id: 'listen_1_hour',
        name: 'Time Flies',
        description: 'Listen for 1 hour',
        iconUrl: '',
        tier: AchievementTier.bronze,
      ),
      const Achievement(
        id: 'listen_100_hours',
        name: 'Dedicated Listener',
        description: 'Listen for 100 hours',
        iconUrl: '',
        tier: AchievementTier.platinum,
      ),
      const Achievement(
        id: 'streak_7_days',
        name: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        iconUrl: '',
        tier: AchievementTier.silver,
      ),
      const Achievement(
        id: 'streak_30_days',
        name: 'Monthly Maven',
        description: 'Maintain a 30-day streak',
        iconUrl: '',
        tier: AchievementTier.gold,
      ),
      const Achievement(
        id: 'discover_50_artists',
        name: 'Explorer',
        description: 'Listen to 50 different artists',
        iconUrl: '',
        tier: AchievementTier.silver,
      ),
    ];
  }

  // ============ Export ============

  @override
  Future<String> exportHistory({
    required DateTime startDate,
    required DateTime endDate,
    ExportFormat format = ExportFormat.json,
  }) async {
    final activities = await getActivityHistory(
      startDate: startDate,
      endDate: endDate,
    );

    if (format == ExportFormat.json) {
      return activities.map((a) => a.toJson()).toList().toString();
    } else {
      // CSV format
      final buffer = StringBuffer();
      buffer.writeln('Date,Listening Time (ms),Songs Played');
      for (final activity in activities) {
        buffer.writeln(
          '${activity.date.toIso8601String()},${activity.listeningTimeMs},${activity.songsPlayed}',
        );
      }
      return buffer.toString();
    }
  }
}
