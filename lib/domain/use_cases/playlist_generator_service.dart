import 'package:neom_core/domain/model/item_list.dart';

/// Abstract service for generating recommended/auto-curated playlists.
abstract class PlaylistGeneratorService {

  /// Generate a collection of recommended playlists for the current user.
  Future<List<Itemlist>> generateRecommendedPlaylists({int limit = 8});

  /// Generate a genre-specific mix playlist.
  Future<Itemlist> generateGenreMix(String genre, {int songCount = 25});

  /// Generate a language-based mix playlist.
  Future<Itemlist> generateLanguageMix(String language, {int songCount = 25});

  /// Generate a trending playlist (most liked songs).
  Future<Itemlist> generateTrendingPlaylist({int songCount = 30});

  /// Generate a new releases playlist (most recent songs).
  Future<Itemlist> generateNewReleases({int songCount = 20});

  /// Force refresh recommendations.
  Future<void> refreshRecommendedPlaylists();

  /// Get cached recommendations (empty if not yet generated).
  List<Itemlist> get cachedRecommendations;
}
