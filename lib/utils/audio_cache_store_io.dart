import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:path_provider/path_provider.dart';

/// The songs a subscriber keeps whole on the device.
///
/// `LockCachingAudioSource` writes each song to
/// `<temp>/just_audio_cache/remote/<hash>.<ext>` and never evicts anything,
/// so without this the cache grew with every song ever played. The OS may
/// purge the temp directory eventually, but only under storage pressure,
/// long after the listener has noticed the app's size.
///
/// A song still downloading is `<file>.part` (plus `<file>.mime`); those are
/// never touched here — deleting one under an active download would break
/// the song that is playing.
class AudioCacheStore {
  AudioCacheStore._();

  /// Cap for the whole cache. Past it, the songs played longest ago go first.
  static const int defaultMaxBytes = 500 * 1024 * 1024;

  /// Replaces the cache directory, so tests can run without path_provider.
  @visibleForTesting
  static Directory? debugDir;

  static Future<Directory> _dir() async =>
      debugDir ??
      Directory('${(await getTemporaryDirectory()).path}/just_audio_cache/remote');

  /// Total bytes on disk, downloads in progress included.
  static Future<int> sizeBytes() async {
    try {
      final dir = await _dir();
      if (!dir.existsSync()) return 0;
      var total = 0;
      for (final f in dir.listSync().whereType<File>()) {
        total += f.lengthSync();
      }
      return total;
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(e, st,
          module: 'neom_audio_player', operation: 'AudioCacheStore.sizeBytes');
      return 0;
    }
  }

  /// Deletes every completed song. Returns the bytes freed.
  static Future<int> clear() => _evictDownTo(0);

  /// Deletes the songs played longest ago until the cache fits [maxBytes].
  /// Returns the bytes freed.
  static Future<int> enforceLimit({int maxBytes = defaultMaxBytes}) =>
      _evictDownTo(maxBytes);

  /// Marks [file] as just played, so eviction keeps it longest. The cache
  /// stamps a song once, when it finishes downloading; without this, a
  /// favourite played every day would be the first to go.
  static Future<void> markPlayed(File file) async {
    try {
      if (file.existsSync()) file.setLastModifiedSync(DateTime.now());
    } catch (_) {
      // Only an eviction-order hint; never worth failing playback over.
    }
  }

  static bool _isCompletedSong(File f) =>
      !f.path.endsWith('.part') && !f.path.endsWith('.mime');

  static Future<int> _evictDownTo(int targetBytes) async {
    try {
      final dir = await _dir();
      if (!dir.existsSync()) return 0;
      final files = dir.listSync().whereType<File>().toList();
      var total = files.fold<int>(0, (sum, f) => sum + f.lengthSync());
      if (total <= targetBytes) return 0;

      final songs = files.where(_isCompletedSong).toList()
        ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      var freed = 0;
      for (final song in songs) {
        if (total <= targetBytes) break;
        final mime = File('${song.path}.mime');
        final bytes = song.lengthSync() +
            (mime.existsSync() ? mime.lengthSync() : 0);
        song.deleteSync();
        if (mime.existsSync()) mime.deleteSync();
        total -= bytes;
        freed += bytes;
      }
      return freed;
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(e, st,
          module: 'neom_audio_player', operation: 'AudioCacheStore.evict');
      return 0;
    }
  }
}
