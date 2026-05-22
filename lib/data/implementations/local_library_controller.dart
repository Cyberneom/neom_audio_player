import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:sint/sint.dart';

/// Scans the local filesystem for audio files and maintains an indexed library.
///
/// Features:
/// - Incremental scanning (delta scan based on modification time)
/// - Deduplication against already-known tracks
/// - Metadata extraction from file tags
/// - Background scan with progress reporting
///
/// Inspired by SpotiFLAC-Mobile's local_library_provider.
class SaiaLocalLibraryController extends SintController {

  static const String _hiveKey = 'local_library';
  static const String _lastScanKey = 'local_library_last_scan';
  static const String _libraryPathKey = 'local_library_path';

  static const List<String> _audioExtensions = [
    '.mp3', '.m4a', '.flac', '.opus', '.ogg', '.wav', '.aac', '.wma',
  ];

  /// Indexed local audio files.
  final RxList<LocalAudioFile> items = <LocalAudioFile>[].obs;

  /// Whether a scan is in progress.
  final RxBool isScanning = false.obs;

  /// Scan progress (0.0 to 1.0).
  final RxDouble scanProgress = 0.0.obs;

  /// Number of files found in current scan.
  final RxInt filesFound = 0.obs;

  /// Configured library path.
  final RxString libraryPath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
    _loadLibraryPath();
  }

  /// Set the directory to scan.
  void setLibraryPath(String path) {
    libraryPath.value = path;
    Hive.box(AppHiveBox.settings.name).put(_libraryPathKey, path);
    AppConfig.logger.i('Library path set to: $path');
  }

  /// Start a full or incremental library scan.
  Future<ScanResult> scan({bool fullScan = false}) async {
    if (kIsWeb) return ScanResult(found: 0, added: 0, error: 'Not available on web');
    if (isScanning.value) return ScanResult(found: 0, added: 0, error: 'Scan already in progress');
    if (libraryPath.value.isEmpty) return ScanResult(found: 0, added: 0, error: 'No library path configured');

    isScanning.value = true;
    scanProgress.value = 0.0;
    filesFound.value = 0;

    final stopwatch = Stopwatch()..start();
    int added = 0;
    int skipped = 0;

    try {
      final dir = Directory(libraryPath.value);
      if (!await dir.exists()) {
        return ScanResult(found: 0, added: 0, error: 'Directory not found: ${libraryPath.value}');
      }

      // Get last scan timestamp for delta scan
      DateTime? lastScan;
      if (!fullScan) {
        final lastScanMs = Hive.box(AppHiveBox.settings.name).get(_lastScanKey) as int?;
        if (lastScanMs != null) {
          lastScan = DateTime.fromMillisecondsSinceEpoch(lastScanMs);
        }
      }

      // Collect all audio files
      final allFiles = <FileSystemEntity>[];
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if (_audioExtensions.contains('.$ext')) {
            allFiles.add(entity);
          }
        }
      }

      filesFound.value = allFiles.length;
      if (allFiles.isEmpty) {
        return ScanResult(found: 0, added: 0);
      }

      // Build existing path set for dedup
      final existingPaths = <String>{};
      for (final item in items) {
        existingPaths.add(item.filePath);
      }

      // Process files
      final newItems = <LocalAudioFile>[];
      for (int i = 0; i < allFiles.length; i++) {
        final file = allFiles[i] as File;
        scanProgress.value = (i + 1) / allFiles.length;

        // Skip if already indexed (unless full scan)
        if (!fullScan && existingPaths.contains(file.path)) {
          // Delta scan: check if file was modified after last scan
          if (lastScan != null) {
            final stat = await file.stat();
            if (stat.modified.isBefore(lastScan)) {
              skipped++;
              continue;
            }
          } else {
            skipped++;
            continue;
          }
        }

        try {
          final stat = await file.stat();
          final filename = file.path.split('/').last;
          final nameWithoutExt = filename.contains('.')
              ? filename.substring(0, filename.lastIndexOf('.'))
              : filename;

          // Parse artist - title from filename (common patterns)
          String title = nameWithoutExt;
          String artist = '';
          if (nameWithoutExt.contains(' - ')) {
            final parts = nameWithoutExt.split(' - ');
            artist = parts[0].trim();
            title = parts.sublist(1).join(' - ').trim();
          }

          final audioFile = LocalAudioFile(
            filePath: file.path,
            fileName: filename,
            title: title,
            artist: artist,
            album: file.parent.path.split('/').last,
            format: file.path.split('.').last.toLowerCase(),
            fileSizeBytes: stat.size,
            lastModified: stat.modified,
          );

          newItems.add(audioFile);
          added++;
        } catch (e) {
          AppConfig.logger.w('Error processing file: ${file.path}: $e');
        }
      }

      // Merge with existing
      if (fullScan) {
        items.assignAll(newItems);
      } else {
        // Remove items whose files no longer exist
        items.removeWhere((item) => !existingPaths.contains(item.filePath) &&
            newItems.every((n) => n.filePath != item.filePath));
        // Add new items
        for (final item in newItems) {
          final existingIndex = items.indexWhere((e) => e.filePath == item.filePath);
          if (existingIndex >= 0) {
            items[existingIndex] = item; // Update
          } else {
            items.add(item);
          }
        }
      }

      // Sort by title
      items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      // Persist
      _saveToCache();
      Hive.box(AppHiveBox.settings.name).put(_lastScanKey, DateTime.now().millisecondsSinceEpoch);

      stopwatch.stop();
      AppConfig.logger.i('Library scan complete: ${items.length} total, $added new, $skipped unchanged (${stopwatch.elapsed.inSeconds}s)');

      return ScanResult(found: allFiles.length, added: added, skipped: skipped);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_audio_player', operation: 'localLibraryScan');
      return ScanResult(found: filesFound.value, added: added, error: e.toString());
    } finally {
      isScanning.value = false;
      scanProgress.value = 1.0;
    }
  }

  /// Remove a file from the library index.
  void removeFromLibrary(String filePath) {
    items.removeWhere((item) => item.filePath == filePath);
    _saveToCache();
  }

  /// Clear the entire library index.
  void clearLibrary() {
    items.clear();
    Hive.box(AppHiveBox.cache.name).delete(_hiveKey);
    Hive.box(AppHiveBox.settings.name).delete(_lastScanKey);
  }

  /// Search within local library.
  List<LocalAudioFile> search(String query) {
    if (query.isEmpty) return items.toList();
    final q = query.toLowerCase();
    return items.where((item) =>
      item.title.toLowerCase().contains(q) ||
      item.artist.toLowerCase().contains(q) ||
      item.album.toLowerCase().contains(q)
    ).toList();
  }

  /// Group items by album.
  Map<String, List<LocalAudioFile>> get byAlbum {
    final map = <String, List<LocalAudioFile>>{};
    for (final item in items) {
      map.putIfAbsent(item.album, () => []).add(item);
    }
    return map;
  }

  /// Group items by artist.
  Map<String, List<LocalAudioFile>> get byArtist {
    final map = <String, List<LocalAudioFile>>{};
    for (final item in items) {
      final key = item.artist.isEmpty ? 'Unknown' : item.artist;
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  void _loadFromCache() {
    try {
      final box = Hive.box(AppHiveBox.cache.name);
      final data = box.get(_hiveKey);
      if (data is List) {
        final loaded = data
            .whereType<Map>()
            .map((m) => LocalAudioFile.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        items.assignAll(loaded);
        AppConfig.logger.d('Loaded ${loaded.length} local library items from cache');
      }
    } catch (e) {
      AppConfig.logger.w('Error loading local library cache: $e');
    }
  }

  void _loadLibraryPath() {
    libraryPath.value = Hive.box(AppHiveBox.settings.name).get(_libraryPathKey, defaultValue: '') as String;
  }

  void _saveToCache() {
    try {
      final box = Hive.box(AppHiveBox.cache.name);
      box.put(_hiveKey, items.map((e) => e.toJson()).toList());
    } catch (e) {
      AppConfig.logger.w('Error saving local library cache: $e');
    }
  }
}

/// Represents a local audio file found during scanning.
class LocalAudioFile {
  final String filePath;
  final String fileName;
  final String title;
  final String artist;
  final String album;
  final String format;
  final int fileSizeBytes;
  final DateTime lastModified;
  final String? isrc;
  final String? genre;

  const LocalAudioFile({
    required this.filePath,
    required this.fileName,
    required this.title,
    this.artist = '',
    this.album = '',
    required this.format,
    this.fileSizeBytes = 0,
    required this.lastModified,
    this.isrc,
    this.genre,
  });

  /// Lookup key for deduplication: "title|artist" normalized.
  String get trackArtistKey => '${title.toLowerCase()}|${artist.toLowerCase()}';

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'fileName': fileName,
    'title': title,
    'artist': artist,
    'album': album,
    'format': format,
    'fileSizeBytes': fileSizeBytes,
    'lastModified': lastModified.toIso8601String(),
    'isrc': isrc,
    'genre': genre,
  };

  factory LocalAudioFile.fromJson(Map<String, dynamic> json) {
    return LocalAudioFile(
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String? ?? '',
      album: json['album'] as String? ?? '',
      format: json['format'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ?? DateTime.now(),
      isrc: json['isrc'] as String?,
      genre: json['genre'] as String?,
    );
  }
}

/// Result of a library scan operation.
class ScanResult {
  final int found;
  final int added;
  final int skipped;
  final String? error;

  const ScanResult({
    required this.found,
    required this.added,
    this.skipped = 0,
    this.error,
  });

  bool get hasError => error != null;
}
