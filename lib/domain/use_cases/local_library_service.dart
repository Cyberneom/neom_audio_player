import '../models/media_state.dart';

/// Service interface for local library operations.
///
/// Implemented by [SaiaLocalLibraryController] in neom_audio_player.
abstract class LocalLibraryService {

  /// Whether a scan is currently in progress.
  bool get isScanning;

  /// Current scan progress (0.0 to 1.0).
  double get scanProgress;

  /// Number of indexed local files.
  int get itemCount;

  /// Set the directory path to scan for music files.
  void setLibraryPath(String path);

  /// Start scanning the configured library path.
  /// Set [fullScan] to true to rescan everything ignoring modification times.
  Future<void> scan({bool fullScan = false});

  /// Search the local library by query string.
  List<dynamic> search(String query);

  /// Clear the library index.
  void clearLibrary();
}
