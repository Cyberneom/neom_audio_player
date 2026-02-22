/// NeomAudioPlayer - Full-featured music streaming module for Open Neom
///
/// Provides audio playback, queue management, radio stations, collaborative
/// listening (Jam Sessions), and advanced playback features comparable to
/// Spotify and YouTube Music.
library;

// ============ Core Audio Handler ============
export 'neom_audio_handler.dart';

// ============ Routes & Invoker ============
export 'audio_player_routes.dart';
export 'audio_player_invoker.dart';

// ============ Enums ============
export 'utils/enums/playlist_type.dart';
export 'utils/enums/lyrics_source.dart';
export 'utils/enums/lyrics_type.dart';
export 'utils/enums/radio_seed_type.dart';
export 'utils/enums/jam_session_type.dart';
export 'utils/enums/playback_mode.dart';

// ============ Domain Models ============
export 'domain/models/playlist_item.dart';
export 'domain/models/playlist_section.dart';
export 'domain/models/queue_state.dart';
export 'domain/models/media_state.dart';
export 'domain/models/position_data.dart';
export 'domain/models/media_lyrics.dart';
export 'domain/models/radio_station.dart';
export 'domain/models/jam_session.dart';
export 'domain/models/listening_stats.dart';
export 'domain/models/smart_queue.dart';

// ============ Service Interfaces ============
export 'domain/use_cases/audio_player_service.dart';
export 'domain/use_cases/player_hive_service.dart';
export 'domain/use_cases/playlist_hive_service.dart';
export 'domain/use_cases/radio_service.dart';
export 'domain/use_cases/jam_session_service.dart';
export 'domain/use_cases/listening_stats_service.dart';
export 'domain/use_cases/smart_queue_service.dart';
export 'domain/use_cases/enhanced_playback_service.dart';

// ============ Controllers / Implementations ============
export 'data/implementations/audio_lite_player_controller.dart';
export 'data/implementations/casete_hive_controller.dart';
export 'data/implementations/player_hive_controller.dart';
export 'data/implementations/playlist_hive_controller.dart';
export 'data/implementations/radio_controller.dart';
export 'data/implementations/jam_session_controller.dart';
export 'data/implementations/listening_stats_controller.dart';
export 'data/implementations/enhanced_playback_controller.dart';

// ============ Providers ============
export 'data/providers/neom_audio_provider.dart';

// ============ UI Widgets ============
export 'ui/widgets/sleep_timer_sheet.dart';
export 'ui/widgets/radio_station_card.dart';
export 'ui/widgets/listening_stats_card.dart';
export 'ui/widgets/jam_session_widget.dart';
export 'ui/widgets/car_mode_player.dart';
export 'ui/player/widgets/player_options_menu.dart';

// ============ Constants ============
export 'utils/constants/audio_player_constants.dart';
export 'utils/constants/audio_player_route_constants.dart';
export 'utils/constants/audio_player_translation_constants.dart';
