/// # NeomAudioPlayer
///
/// Full-featured music streaming module for the Open Neom ecosystem.
/// Provides audio playback, queue management, radio stations, smart
/// recommendations, collaborative listening (Jam Sessions), listening
/// statistics, lyrics, equalizer, sleep timer, crossfade and a complete
/// Spotify-style web layout with mini player + full screen now playing.
///
/// ## Architecture
/// Built on top of [`just_audio`](https://pub.dev/packages/just_audio) and
/// [`audio_service`](https://pub.dev/packages/audio_service), with state
/// management via the **Sint** framework (a custom GetX wrapper used across
/// all Open Neom modules) and persistence via **Hive**. Real-time features
/// (Jam Sessions, listening stats sync) require a Firebase project on the
/// host app.
///
/// ## Quick start
/// ```dart
/// // 1. Register the audio handler in your root binding:
/// Bind.lazyPut(() => NeomAudioHandler(), fenix: true);
/// Bind.lazyPut(() => MiniPlayerController(), fenix: true);
/// Bind.lazyPut(() => AudioPlayerInvoker(), fenix: true);
///
/// // 2. Add the routes to your app router:
/// SintPage(name: AppRouteConstants.audioPlayer, page: () => const AudioPlayerRootPage(...)),
/// ...AudioPlayerRoutes.routes,
///
/// // 3. (Web only) Pass the bottom player + full now-playing builders
/// //    to your HomePage so they render below the main content.
/// ```
///
/// ## Hive boxes used by this module
/// The following Hive box names — declared by `AppHiveBox` in `neom_core` —
/// are read or written by the controllers shipped here. Make sure your host
/// app opens them on startup before any controller is invoked:
///
/// | Box                       | Used by                              | Purpose                              |
/// |---------------------------|--------------------------------------|--------------------------------------|
/// | `AppHiveBox.settings`     | `PlayerHiveController`               | Repeat mode, preferred language      |
/// | `AppHiveBox.favoriteItems`| `PlaylistHiveController`             | "Liked" tracks                       |
/// | `AppHiveBox.songSkips`    | `ListeningStatsController`           | Skip counters per track              |
/// | `AppHiveBox.songCompletes`| `ListeningStatsController`           | Complete-play counters               |
/// | `enhanced_playback`       | `EnhancedPlaybackController`         | Crossfade / sleep timer prefs        |
///
/// ## Public API map
/// * **Core handler**: [NeomAudioHandler], [AudioPlayerInvoker]
/// * **Routes**: [AudioPlayerRoutes]
/// * **Backend services & controllers**: see "Service Interfaces" and
///   "Controllers" sections of this barrel.
/// * **UI pages** (mobile + web): see "Pages" section.
/// * **Web layer**: see "Web layout" section — Spotify-style 3-column
///   responsive layout, drag-reorder queue, karaoke lyrics, ambient
///   gradient, pseudo-visualizer, full keyboard shortcuts.
/// * **Web utilities** (pure helpers, fully unit-tested): palette extractor,
///   image resolver, LRC parser, duration formatter, slider math, repeat
///   cycler, volume clamp.
library;

// ═══════════════════════════════════════════════════════════════════════════
// Core Audio Handler
// ═══════════════════════════════════════════════════════════════════════════
export 'neom_audio_handler.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Routes & Invoker
// ═══════════════════════════════════════════════════════════════════════════
export 'audio_player_routes.dart';
export 'audio_player_invoker.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Enums
// ═══════════════════════════════════════════════════════════════════════════
export 'utils/enums/playlist_type.dart';
export 'utils/enums/lyrics_source.dart';
export 'utils/enums/lyrics_type.dart';
export 'utils/enums/radio_seed_type.dart';
export 'utils/enums/jam_session_type.dart';
export 'utils/enums/equalizer_preset.dart';
export 'utils/enums/playback_mode.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Domain Models
// ═══════════════════════════════════════════════════════════════════════════
export 'domain/models/playlist_item.dart';
export 'domain/models/playlist_section.dart';
export 'domain/models/queue_state.dart';
export 'domain/models/media_state.dart';
export 'domain/models/position_data.dart';
export 'domain/models/lrc_entry.dart';
export 'domain/models/lyrics_cache_entry.dart';
export 'domain/models/media_lyrics.dart';
export 'domain/models/radio_station.dart';
export 'domain/models/jam_session.dart';
export 'domain/models/listening_stats.dart';
export 'domain/models/smart_queue.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Service Interfaces (use these to depend on this module from other modules)
// ═══════════════════════════════════════════════════════════════════════════
export 'domain/use_cases/audio_player_service.dart';
export 'domain/use_cases/player_hive_service.dart';
export 'domain/use_cases/playlist_hive_service.dart';
export 'domain/use_cases/radio_service.dart';
export 'domain/use_cases/jam_session_service.dart';
export 'domain/use_cases/listening_stats_service.dart';
export 'domain/use_cases/smart_queue_service.dart';
export 'domain/use_cases/enhanced_playback_service.dart';
export 'domain/use_cases/artwork_color_service.dart';
export 'domain/use_cases/equalizer_service.dart';
export 'domain/use_cases/lyrics_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Controllers / Implementations
//
// Only the player-pure implementations live here. Platform-level controllers
// (jam_session, smart_queue, playlist_generator, radio, listening_stats,
// audio_recommendation, casete) have moved to `neom_audio_platform`.
// The corresponding service interfaces still live in this package (see
// "Service Interfaces") so widgets in this layer can stay decoupled from
// the concrete impls.
// ═══════════════════════════════════════════════════════════════════════════
export 'data/implementations/artwork_color_controller.dart';
export 'data/implementations/audio_lite_player_controller.dart';
export 'data/implementations/casete_hive_controller.dart';
export 'data/implementations/enhanced_playback_controller.dart';
export 'data/implementations/equalizer_controller.dart';
export 'data/implementations/player_hive_controller.dart';
export 'data/implementations/lyrics_controller.dart';
export 'data/implementations/playlist_hive_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Hive caches (player-local, no Firestore dependency)
// ═══════════════════════════════════════════════════════════════════════════
export 'data/hive/catalog_cache_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════════════
export 'data/providers/neom_audio_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Mappers & Helpers
// ═══════════════════════════════════════════════════════════════════════════
export 'utils/mappers/media_item_mapper.dart';
export 'utils/helpers/add_mediaitem_to_queue.dart';
export 'utils/helpers/route_handler.dart';
export 'utils/helpers/songs_count.dart';
export 'utils/helpers/lrc_parser.dart';
export 'utils/helpers/spotify_lyrics_helper.dart';
export 'utils/audio_player_utilities.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Pages (mobile + web entry points)
//
// Home feed + library detail page have moved to `neom_audio_platform`.
// ═══════════════════════════════════════════════════════════════════════════
export 'ui/audio_player_root_page.dart';
export 'ui/library/now_playing_page.dart';
export 'ui/player/audio_player_controller.dart';
export 'ui/player/audio_player_page.dart';
export 'ui/player/miniplayer.dart';
export 'ui/player/miniplayer_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════
// UI Widgets — top-level reusable components
//
// `radio_station_card`, `listening_stats_card` and `jam_session_widget`
// have moved to `neom_audio_platform`.
// ═══════════════════════════════════════════════════════════════════════════
export 'ui/widgets/equalizer_widget.dart';
export 'ui/widgets/playback_control_panel.dart';
export 'ui/widgets/sleep_timer_sheet.dart';
export 'ui/widgets/car_mode_player.dart';
export 'ui/widgets/add_to_playlist_button.dart';
export 'ui/player/lyrics/synced_lyrics_widget.dart';
export 'ui/player/widgets/player_options_menu.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Web layout — Spotify-style 3-column responsive layout for Flutter Web
//
// The layout exposes builder slots for the home feed, search feed, sidebar
// library, playlist detail and jam session views — all of which live in
// `neom_audio_platform`. The bottom player, full-screen now playing, queue
// panel, lyrics panel and pseudo-visualizer stay in this layer.
// ═══════════════════════════════════════════════════════════════════════════
export 'ui/web/audio_player_web_layout.dart';
export 'ui/web/web_keyboard_shortcuts.dart';
export 'ui/web/widgets/web_bottom_player.dart';
export 'ui/web/widgets/web_now_playing_full.dart';
export 'ui/web/widgets/web_queue_panel.dart';
export 'ui/web/widgets/web_lyrics_panel.dart';
export 'ui/web/widgets/web_create_playlist_dialog.dart';
export 'ui/web/widgets/web_edit_playlist_dialog.dart';
export 'ui/web/widgets/web_context_menu.dart';
export 'ui/web/widgets/web_upgrade_banner.dart';
export 'ui/web/widgets/web_pseudo_visualizer.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Web utilities — pure helpers, fully unit-tested
// ═══════════════════════════════════════════════════════════════════════════
export 'ui/web/utils/web_color_extractor.dart';
export 'ui/web/utils/web_image_resolver.dart';
export 'ui/web/utils/web_track_transition.dart';
export 'ui/web/utils/web_lrc_parser.dart';
export 'ui/web/utils/web_duration_formatter.dart';
export 'ui/web/utils/web_player_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Constants
// ═══════════════════════════════════════════════════════════════════════════
export 'utils/constants/audio_player_constants.dart';
export 'utils/constants/audio_player_route_constants.dart';
export 'utils/constants/audio_player_translation_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Local Library
// ═══════════════════════════════════════════════════════════════════════════
export 'data/implementations/local_library_controller.dart';
export 'domain/use_cases/local_library_service.dart';
