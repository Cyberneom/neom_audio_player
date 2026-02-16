import 'package:audio_service/audio_service.dart';

import '../models/radio_station.dart';
import '../../utils/enums/radio_seed_type.dart';

/// Abstract service for radio station generation and management
abstract class RadioService {
  /// Get list of user's saved radio stations
  Future<List<RadioStation>> getSavedStations();

  /// Get recently played radio stations
  Future<List<RadioStation>> getRecentStations({int limit = 10});

  /// Create a new radio station from a song
  Future<RadioStation> createStationFromSong(
    String songId, {
    RadioMood? mood,
    int initialQueueSize = 25,
  });

  /// Create a new radio station from an artist
  Future<RadioStation> createStationFromArtist(
    String artistId, {
    RadioMood? mood,
    int initialQueueSize = 25,
  });

  /// Create a new radio station from a genre
  Future<RadioStation> createStationFromGenre(
    String genre, {
    RadioMood? mood,
    int initialQueueSize = 25,
  });

  /// Create a personal mix station based on listening history
  Future<RadioStation> createPersonalMix({
    RadioMood? mood,
    int initialQueueSize = 25,
  });

  /// Create a discovery station with new music
  Future<RadioStation> createDiscoveryStation({
    RadioMood? mood,
    int initialQueueSize = 25,
  });

  /// Create a station based on liked songs
  Future<RadioStation> createLikedSongsStation({
    RadioMood? mood,
    int initialQueueSize = 25,
  });

  /// Create a station with custom parameters
  Future<RadioStation> createCustomStation(RadioStationParams params);

  /// Get more songs for an existing station
  Future<List<MediaItem>> refreshStation(
    String stationId, {
    int count = 15,
  });

  /// Save a radio station
  Future<void> saveStation(RadioStation station);

  /// Delete a saved radio station
  Future<void> deleteStation(String stationId);

  /// Mark a song as skipped in station (affects future recommendations)
  Future<void> markSongSkipped(String stationId, String songId);

  /// Mark a song as liked in station
  Future<void> markSongLiked(String stationId, String songId);

  /// Get suggested radio stations based on context
  Future<List<RadioStation>> getSuggestedStations({
    int limit = 6,
    String? timeOfDay,
    String? activity,
  });

  /// Get quick mix stations (genre-based)
  Future<List<RadioStation>> getQuickMixStations();

  /// Start playing a radio station
  Future<void> playStation(String stationId);

  /// Update station play count and last played
  Future<void> updateStationPlayStats(String stationId);
}

/// Radio station generation algorithm hints
class RadioAlgorithmHints {
  /// Weight for similar artists (0-1)
  final double similarArtistWeight;

  /// Weight for similar genres (0-1)
  final double similarGenreWeight;

  /// Weight for similar mood/energy (0-1)
  final double similarMoodWeight;

  /// Weight for user history (0-1)
  final double historyWeight;

  /// Weight for popularity (0-1)
  final double popularityWeight;

  /// Weight for discovery/new music (0-1)
  final double discoveryWeight;

  /// Variety factor (0 = very similar, 1 = very diverse)
  final double varietyFactor;

  const RadioAlgorithmHints({
    this.similarArtistWeight = 0.3,
    this.similarGenreWeight = 0.25,
    this.similarMoodWeight = 0.2,
    this.historyWeight = 0.1,
    this.popularityWeight = 0.1,
    this.discoveryWeight = 0.05,
    this.varietyFactor = 0.5,
  });

  /// Preset for very similar songs
  static const RadioAlgorithmHints verySimilar = RadioAlgorithmHints(
    similarArtistWeight: 0.5,
    similarGenreWeight: 0.3,
    similarMoodWeight: 0.15,
    historyWeight: 0.05,
    popularityWeight: 0,
    discoveryWeight: 0,
    varietyFactor: 0.2,
  );

  /// Preset for balanced mix
  static const RadioAlgorithmHints balanced = RadioAlgorithmHints();

  /// Preset for discovery/exploration
  static const RadioAlgorithmHints discovery = RadioAlgorithmHints(
    similarArtistWeight: 0.1,
    similarGenreWeight: 0.2,
    similarMoodWeight: 0.15,
    historyWeight: 0.05,
    popularityWeight: 0.2,
    discoveryWeight: 0.3,
    varietyFactor: 0.8,
  );

  /// Preset for personal favorites
  static const RadioAlgorithmHints personal = RadioAlgorithmHints(
    similarArtistWeight: 0.2,
    similarGenreWeight: 0.15,
    similarMoodWeight: 0.1,
    historyWeight: 0.4,
    popularityWeight: 0.05,
    discoveryWeight: 0.1,
    varietyFactor: 0.4,
  );
}
