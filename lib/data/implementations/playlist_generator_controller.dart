import 'dart:math';

import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/repository/casete_session_repository.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:sint/sint.dart';
import 'package:uuid/uuid.dart';

import '../../domain/use_cases/playlist_generator_service.dart';

/// Generates recommended/auto-curated playlists using existing catalog data.
/// Playlists are ephemeral (client-side only, not persisted to Firestore).
class PlaylistGeneratorController extends SintController implements PlaylistGeneratorService {

  final _recommendations = <Itemlist>[].obs;
  final _isGenerating = false.obs;
  DateTime? _lastGenerated;
  final _random = Random();
  final _uuid = const Uuid();

  /// Dedicated observables for home sections.
  final _topPlayedPlaylist = Rxn<Itemlist>();
  final _newReleasesPlaylist = Rxn<Itemlist>();

  bool get isGenerating => _isGenerating.value;
  Itemlist? get topPlayedPlaylist => _topPlayedPlaylist.value;
  Itemlist? get newReleasesPlaylist => _newReleasesPlaylist.value;

  @override
  List<Itemlist> get cachedRecommendations => _recommendations.toList();

  @override
  Future<List<Itemlist>> generateRecommendedPlaylists({int limit = 8}) async {
    // Don't regenerate if less than 1 hour old
    if (_lastGenerated != null &&
        DateTime.now().difference(_lastGenerated!).inHours < 1 &&
        _recommendations.isNotEmpty) {
      return _recommendations.toList();
    }

    _isGenerating.value = true;
    final playlists = <Itemlist>[];

    try {
      // Get user's preferred genres
      final userGenres = <String>[];
      try {
        final profile = Sint.find<UserService>().profile;
        if (profile.genres != null) {
          userGenres.addAll(
            profile.genres!.values
                .where((g) => g.name.isNotEmpty)
                .map((g) => g.name)
                .toList(),
          );
        }
      } catch (_) {}

      // Generate genre mixes (up to 3)
      final genresToUse = userGenres.take(3).toList();
      for (final genre in genresToUse) {
        try {
          final mix = await generateGenreMix(genre);
          if (mix.appReleaseItems != null && mix.appReleaseItems!.isNotEmpty) {
            playlists.add(mix);
          }
        } catch (_) {}
      }

      // Trending playlist
      try {
        final trending = await generateTrendingPlaylist();
        if (trending.appReleaseItems != null && trending.appReleaseItems!.isNotEmpty) {
          playlists.add(trending);
        }
      } catch (_) {}

      // New releases
      try {
        final newRel = await generateNewReleases();
        if (newRel.appReleaseItems != null && newRel.appReleaseItems!.isNotEmpty) {
          playlists.add(newRel);
        }
      } catch (_) {}

      // Language mix based on user's first language preference
      try {
        final profile = Sint.find<UserService>().profile;
        final lang = profile.genres?.values.firstOrNull?.name.isNotEmpty == true
            ? 'es' : 'en'; // Default to Spanish for Gigmeout
        final langMix = await generateLanguageMix(lang);
        if (langMix.appReleaseItems != null && langMix.appReleaseItems!.isNotEmpty) {
          playlists.add(langMix);
        }
      } catch (_) {}

      _recommendations.value = playlists.take(limit).toList();
      _lastGenerated = DateTime.now();
    } finally {
      _isGenerating.value = false;
    }

    return _recommendations.toList();
  }

  @override
  Future<Itemlist> generateGenreMix(String genre, {int songCount = 25}) async {
    final releaseItems = await AppReleaseItemFirestore().retrieveByCategory(genre, limit: 50);
    final items = releaseItems.values.toList()..shuffle(_random);
    final selected = items.take(songCount).toList();

    return Itemlist(
      id: 'gen_genre_${_uuid.v4().substring(0, 8)}',
      name: '$genre Mix',
      description: 'Auto-generated mix based on $genre',
      ownerName: 'Gigmeout',
      ownerType: OwnerType.profile,
      type: ItemlistType.playlist,
      public: false,
      isModifiable: false,
      appReleaseItems: selected,
      categories: [genre],
      createdTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<Itemlist> generateLanguageMix(String language, {int songCount = 25}) async {
    final releaseItems = await AppReleaseItemFirestore().retrieveByLanguage(language, limit: 50);
    final items = releaseItems.values.toList()..shuffle(_random);
    final selected = items.take(songCount).toList();

    final langName = _languageDisplayName(language);

    return Itemlist(
      id: 'gen_lang_${_uuid.v4().substring(0, 8)}',
      name: '$langName Mix',
      description: 'Songs in $langName',
      ownerName: 'Gigmeout',
      ownerType: OwnerType.profile,
      type: ItemlistType.playlist,
      public: false,
      isModifiable: false,
      appReleaseItems: selected,
      language: language,
      createdTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<Itemlist> generateTrendingPlaylist({int songCount = 30}) async {
    final allItems = await AppReleaseItemFirestore().retrieveAll();
    final items = allItems.values.where((item) => item.isAudioContent).toList();

    // Sort by popularity (likedProfiles count)
    items.sort((a, b) =>
        (b.likedProfiles?.length ?? 0).compareTo(a.likedProfiles?.length ?? 0));

    final selected = items.take(songCount).toList();

    return Itemlist(
      id: 'gen_trending_${_uuid.v4().substring(0, 8)}',
      name: 'Trending',
      description: 'Most popular songs right now',
      ownerName: 'Gigmeout',
      ownerType: OwnerType.profile,
      type: ItemlistType.playlist,
      public: false,
      isModifiable: false,
      appReleaseItems: selected,
      createdTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<Itemlist> generateNewReleases({int songCount = 20}) async {
    final allItems = await AppReleaseItemFirestore().retrieveAll();
    final items = allItems.values.where((item) => item.isAudioContent).toList();

    // Sort by creation time (most recent first)
    items.sort((a, b) => (b.createdTime).compareTo(a.createdTime));

    final selected = items.take(songCount).toList();

    return Itemlist(
      id: 'gen_new_${_uuid.v4().substring(0, 8)}',
      name: 'New Releases',
      description: 'Latest songs on the platform',
      ownerName: 'Gigmeout',
      ownerType: OwnerType.profile,
      type: ItemlistType.playlist,
      public: false,
      isModifiable: false,
      appReleaseItems: selected,
      createdTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Generates Top 20 most played based on real CaseteSession listening data.
  ///
  /// Aggregates total seconds listened per item from CaseteSession records,
  /// then cross-references with AppReleaseItem catalog to build the playlist.
  Future<Itemlist> generateTopPlayed({int songCount = 20}) async {
    try {
      // 1. Fetch all listening sessions via DI (same pattern as neom_audio_handler)
      final caseteRepo = Sint.find<CaseteSessionRepository>();
      final sessions = await caseteRepo.fetchAll(skipTest: true);

      // 2. Aggregate total seconds listened per itemId
      final Map<String, int> casetePerItem = {};
      for (final session in sessions.values) {
        if (session.itemId.isEmpty) continue;
        casetePerItem[session.itemId] = (casetePerItem[session.itemId] ?? 0) + session.casete;
      }

      // 3. Sort by total listening time descending, take top N
      final sortedEntries = casetePerItem.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topItemIds = sortedEntries.take(songCount).map((e) => e.key).toList();

      // 4. Fetch catalog and cross-reference (audio only)
      final allItems = await AppReleaseItemFirestore().retrieveAll();
      final selected = topItemIds
          .where((id) => allItems.containsKey(id) && allItems[id]!.isAudioContent)
          .map((id) => allItems[id]!)
          .toList();

      return Itemlist(
        id: 'gen_top_played_${_uuid.v4().substring(0, 8)}',
        name: 'Top 20',
        description: 'Most played songs based on listening time',
        ownerName: 'Gigmeout',
        ownerType: OwnerType.profile,
        type: ItemlistType.playlist,
        public: false,
        isModifiable: false,
        appReleaseItems: selected,
        createdTime: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'generateTopPlayed');
      // Fallback to trending by likes if CaseteSession fails
      return generateTrendingPlaylist(songCount: songCount);
    }
  }

  /// Generates dedicated home sections (Top Played + New Releases).
  ///
  /// Called from AudioPlayerHomeController.onReady() after a delay.
  Future<void> generateHomeSections() async {
    AppConfig.logger.d('PlaylistGenerator: Generating home sections...');

    try {
      final results = await Future.wait([
        generateTopPlayed(songCount: 20),
        generateNewReleases(songCount: 20),
      ]);

      _topPlayedPlaylist.value = results[0];
      _newReleasesPlaylist.value = results[1];

      AppConfig.logger.d('PlaylistGenerator: Home sections generated — '
          'Top Played: ${results[0].getTotalItems()}, '
          'New Releases: ${results[1].getTotalItems()}');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'generateHomeSections');
    }
  }

  @override
  Future<void> refreshRecommendedPlaylists() async {
    _lastGenerated = null;
    _recommendations.clear();
    await generateRecommendedPlaylists();
  }

  String _languageDisplayName(String code) {
    switch (code) {
      case 'es': return 'Español';
      case 'en': return 'English';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      default: return code.toUpperCase();
    }
  }
}
