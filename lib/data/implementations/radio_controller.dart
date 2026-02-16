import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:sint/sint.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/radio_station.dart';
import '../../domain/use_cases/radio_service.dart';
import '../../utils/enums/radio_seed_type.dart';

/// Controller implementation for Radio Station feature
class RadioController extends SintController implements RadioService {
  static const String _boxName = 'radio_stations';
  static const String _recentKey = 'recent_stations';
  static const String _savedKey = 'saved_stations';

  final _stations = <RadioStation>[].obs;
  final _recentStations = <RadioStation>[].obs;
  final _currentStation = Rxn<RadioStation>();
  final _isLoading = false.obs;

  Box? _box;
  final _uuid = const Uuid();
  final _random = Random();

  /// Current playing station
  RadioStation? get currentStation => _currentStation.value;

  /// All saved stations
  List<RadioStation> get stations => _stations;

  /// Recent stations
  List<RadioStation> get recentStations => _recentStations;

  /// Loading state
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _initHive();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox(_boxName);
    await _loadSavedStations();
    await _loadRecentStations();
  }

  Future<void> _loadSavedStations() async {
    final data = _box?.get(_savedKey) as List?;
    if (data != null) {
      _stations.value = data
          .map((e) => RadioStation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<void> _loadRecentStations() async {
    final data = _box?.get(_recentKey) as List?;
    if (data != null) {
      _recentStations.value = data
          .map((e) => RadioStation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<void> _saveStations() async {
    await _box?.put(_savedKey, _stations.map((e) => e.toJson()).toList());
  }

  Future<void> _saveRecentStations() async {
    await _box?.put(_recentKey, _recentStations.map((e) => e.toJson()).toList());
  }

  @override
  Future<List<RadioStation>> getSavedStations() async {
    return _stations.toList();
  }

  @override
  Future<List<RadioStation>> getRecentStations({int limit = 10}) async {
    return _recentStations.take(limit).toList();
  }

  @override
  Future<RadioStation> createStationFromSong(
    String songId, {
    RadioMood? mood,
    int initialQueueSize = 25,
  }) async {
    _isLoading.value = true;

    try {
      final station = RadioStation(
        id: _uuid.v4(),
        name: 'Song Radio',
        description: 'Based on your selected song',
        seedType: RadioSeedType.song,
        seedValue: songId,
        mood: mood,
        createdAt: DateTime.now(),
        queue: await _generateQueueFromSong(songId, initialQueueSize, mood),
      );

      _addToRecent(station);
      return station;
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<RadioStation> createStationFromArtist(
    String artistId, {
    RadioMood? mood,
    int initialQueueSize = 25,
  }) async {
    _isLoading.value = true;

    try {
      final station = RadioStation(
        id: _uuid.v4(),
        name: 'Artist Radio',
        description: 'Based on this artist',
        seedType: RadioSeedType.artist,
        seedValue: artistId,
        mood: mood,
        createdAt: DateTime.now(),
        queue: await _generateQueueFromArtist(artistId, initialQueueSize, mood),
      );

      _addToRecent(station);
      return station;
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<RadioStation> createStationFromGenre(
    String genre, {
    RadioMood? mood,
    int initialQueueSize = 25,
  }) async {
    _isLoading.value = true;

    try {
      final station = RadioStation(
        id: _uuid.v4(),
        name: '$genre Radio',
        description: 'Songs from $genre genre',
        seedType: RadioSeedType.genre,
        seedValue: genre,
        mood: mood,
        createdAt: DateTime.now(),
        queue: await _generateQueueFromGenre(genre, initialQueueSize, mood),
      );

      _addToRecent(station);
      return station;
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<RadioStation> createPersonalMix({
    RadioMood? mood,
    int initialQueueSize = 25,
  }) async {
    _isLoading.value = true;

    try {
      final station = RadioStation(
        id: _uuid.v4(),
        name: 'Your Personal Mix',
        description: 'Based on your listening history',
        seedType: RadioSeedType.personalMix,
        seedValue: 'personal',
        mood: mood,
        createdAt: DateTime.now(),
        queue: await _generatePersonalMix(initialQueueSize, mood),
      );

      _addToRecent(station);
      return station;
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<RadioStation> createDiscoveryStation({
    RadioMood? mood,
    int initialQueueSize = 25,
  }) async {
    _isLoading.value = true;

    try {
      final station = RadioStation(
        id: _uuid.v4(),
        name: 'Discover Weekly',
        description: 'New music for you',
        seedType: RadioSeedType.discovery,
        seedValue: 'discovery',
        mood: mood,
        createdAt: DateTime.now(),
        queue: await _generateDiscoveryQueue(initialQueueSize, mood),
      );

      _addToRecent(station);
      return station;
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<RadioStation> createLikedSongsStation({
    RadioMood? mood,
    int initialQueueSize = 25,
  }) async {
    _isLoading.value = true;

    try {
      final station = RadioStation(
        id: _uuid.v4(),
        name: 'Liked Songs Radio',
        description: 'Based on your liked songs',
        seedType: RadioSeedType.liked,
        seedValue: 'liked',
        mood: mood,
        createdAt: DateTime.now(),
        queue: await _generateFromLikedSongs(initialQueueSize, mood),
      );

      _addToRecent(station);
      return station;
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<RadioStation> createCustomStation(RadioStationParams params) async {
    _isLoading.value = true;

    try {
      final station = RadioStation(
        id: _uuid.v4(),
        name: 'Custom Radio',
        description: params.seedType.displayName,
        seedType: params.seedType,
        seedValue: params.seedValue,
        mood: params.mood,
        createdAt: DateTime.now(),
        queue: await _generateCustomQueue(params),
      );

      _addToRecent(station);
      return station;
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<List<MediaItem>> refreshStation(
    String stationId, {
    int count = 15,
  }) async {
    final stationIndex = _stations.indexWhere((s) => s.id == stationId);
    if (stationIndex == -1) {
      final recentIndex = _recentStations.indexWhere((s) => s.id == stationId);
      if (recentIndex == -1) return [];

      final station = _recentStations[recentIndex];
      final newSongs = await _generateMoreSongs(station, count);

      _recentStations[recentIndex] = station.copyWith(
        queue: [...station.queue, ...newSongs],
      );
      await _saveRecentStations();

      return newSongs;
    }

    final station = _stations[stationIndex];
    final newSongs = await _generateMoreSongs(station, count);

    _stations[stationIndex] = station.copyWith(
      queue: [...station.queue, ...newSongs],
    );
    await _saveStations();

    return newSongs;
  }

  @override
  Future<void> saveStation(RadioStation station) async {
    final index = _stations.indexWhere((s) => s.id == station.id);
    if (index == -1) {
      _stations.add(station);
    } else {
      _stations[index] = station;
    }
    await _saveStations();
  }

  @override
  Future<void> deleteStation(String stationId) async {
    _stations.removeWhere((s) => s.id == stationId);
    await _saveStations();
  }

  @override
  Future<void> markSongSkipped(String stationId, String songId) async {
    final index = _findStationIndex(stationId);
    if (index == -1) return;

    final station = _getStation(stationId)!;
    if (!station.skippedSongIds.contains(songId)) {
      final updatedStation = station.copyWith(
        skippedSongIds: [...station.skippedSongIds, songId],
      );
      _updateStation(stationId, updatedStation);
    }
  }

  @override
  Future<void> markSongLiked(String stationId, String songId) async {
    final station = _getStation(stationId);
    if (station == null) return;

    if (!station.likedSongIds.contains(songId)) {
      final updatedStation = station.copyWith(
        likedSongIds: [...station.likedSongIds, songId],
      );
      _updateStation(stationId, updatedStation);
    }
  }

  @override
  Future<List<RadioStation>> getSuggestedStations({
    int limit = 6,
    String? timeOfDay,
    String? activity,
  }) async {
    // Generate suggestions based on context
    final suggestions = <RadioStation>[];

    // Add personal mix
    suggestions.add(await createPersonalMix(mood: _getMoodForTimeOfDay(timeOfDay)));

    // Add discovery
    suggestions.add(await createDiscoveryStation());

    // Add genre-based suggestions
    final topGenres = ['Pop', 'Rock', 'Hip-Hop', 'Electronic', 'R&B'];
    for (final genre in topGenres.take(limit - 2)) {
      suggestions.add(await createStationFromGenre(genre));
    }

    return suggestions.take(limit).toList();
  }

  @override
  Future<List<RadioStation>> getQuickMixStations() async {
    final genres = ['Pop', 'Rock', 'Hip-Hop', 'Electronic', 'Jazz', 'Classical'];
    final stations = <RadioStation>[];

    for (final genre in genres) {
      stations.add(RadioStation(
        id: 'quick_mix_$genre',
        name: '$genre Mix',
        description: 'Quick mix of $genre',
        seedType: RadioSeedType.genre,
        seedValue: genre,
        createdAt: DateTime.now(),
      ));
    }

    return stations;
  }

  @override
  Future<void> playStation(String stationId) async {
    final station = _getStation(stationId);
    if (station == null) return;

    _currentStation.value = station;
    await updateStationPlayStats(stationId);

    // Audio handler integration would go here
    // audioHandler.updateQueue(station.queue.map((e) => e).toList());
  }

  @override
  Future<void> updateStationPlayStats(String stationId) async {
    final station = _getStation(stationId);
    if (station == null) return;

    final updatedStation = station.copyWith(
      lastPlayedAt: DateTime.now(),
      playCount: station.playCount + 1,
    );

    _updateStation(stationId, updatedStation);
  }

  // ============ Private Helpers ============

  void _addToRecent(RadioStation station) {
    _recentStations.removeWhere((s) => s.id == station.id);
    _recentStations.insert(0, station);
    if (_recentStations.length > 20) {
      _recentStations.removeLast();
    }
    _saveRecentStations();
  }

  int _findStationIndex(String stationId) {
    final index = _stations.indexWhere((s) => s.id == stationId);
    if (index != -1) return index;
    return _recentStations.indexWhere((s) => s.id == stationId);
  }

  RadioStation? _getStation(String stationId) {
    final saved = _stations.firstWhereOrNull((s) => s.id == stationId);
    if (saved != null) return saved;
    return _recentStations.firstWhereOrNull((s) => s.id == stationId);
  }

  void _updateStation(String stationId, RadioStation station) {
    final savedIndex = _stations.indexWhere((s) => s.id == stationId);
    if (savedIndex != -1) {
      _stations[savedIndex] = station;
      _saveStations();
      return;
    }

    final recentIndex = _recentStations.indexWhere((s) => s.id == stationId);
    if (recentIndex != -1) {
      _recentStations[recentIndex] = station;
      _saveRecentStations();
    }
  }

  RadioMood? _getMoodForTimeOfDay(String? timeOfDay) {
    switch (timeOfDay?.toLowerCase()) {
      case 'morning':
        return RadioMood.energetic;
      case 'afternoon':
        return RadioMood.focus;
      case 'evening':
        return RadioMood.relaxed;
      case 'night':
        return RadioMood.chill;
      default:
        return null;
    }
  }

  // ============ Queue Generation (Placeholder implementations) ============

  Future<List<MediaItem>> _generateQueueFromSong(
    String songId,
    int count,
    RadioMood? mood,
  ) async {
    // In production, this would call a recommendation API
    // For now, return empty list as placeholder
    return [];
  }

  Future<List<MediaItem>> _generateQueueFromArtist(
    String artistId,
    int count,
    RadioMood? mood,
  ) async {
    return [];
  }

  Future<List<MediaItem>> _generateQueueFromGenre(
    String genre,
    int count,
    RadioMood? mood,
  ) async {
    return [];
  }

  Future<List<MediaItem>> _generatePersonalMix(
    int count,
    RadioMood? mood,
  ) async {
    return [];
  }

  Future<List<MediaItem>> _generateDiscoveryQueue(
    int count,
    RadioMood? mood,
  ) async {
    return [];
  }

  Future<List<MediaItem>> _generateFromLikedSongs(
    int count,
    RadioMood? mood,
  ) async {
    return [];
  }

  Future<List<MediaItem>> _generateCustomQueue(
    RadioStationParams params,
  ) async {
    return [];
  }

  Future<List<MediaItem>> _generateMoreSongs(
    RadioStation station,
    int count,
  ) async {
    switch (station.seedType) {
      case RadioSeedType.song:
        return _generateQueueFromSong(station.seedValue, count, station.mood);
      case RadioSeedType.artist:
        return _generateQueueFromArtist(station.seedValue, count, station.mood);
      case RadioSeedType.genre:
        return _generateQueueFromGenre(station.seedValue, count, station.mood);
      case RadioSeedType.personalMix:
        return _generatePersonalMix(count, station.mood);
      case RadioSeedType.discovery:
        return _generateDiscoveryQueue(count, station.mood);
      case RadioSeedType.liked:
        return _generateFromLikedSongs(count, station.mood);
      default:
        return [];
    }
  }
}
