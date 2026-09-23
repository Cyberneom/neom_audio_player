import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/utils/audio_cache_store_io.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('audio_cache_store_');
    AudioCacheStore.debugDir = dir;
  });
  tearDown(() async {
    AudioCacheStore.debugDir = null;
    await dir.delete(recursive: true);
  });

  /// A cached song of [kb] KB with its .mime companion, last used [age] ago.
  File song(String name, int kb, Duration age) {
    final f = File('${dir.path}/$name.mp3')..writeAsBytesSync(List.filled(kb * 1024, 1));
    File('${f.path}.mime').writeAsStringSync('audio/mpeg');
    f.setLastModifiedSync(DateTime.now().subtract(age));
    return f;
  }

  test('size counts every file, downloads in progress included', () async {
    song('a', 10, Duration.zero);
    File('${dir.path}/b.mp3.part').writeAsBytesSync(List.filled(5 * 1024, 1));
    // 10 KB + 5 KB + the 10-byte mime file.
    expect(await AudioCacheStore.sizeBytes(), 15 * 1024 + 10);
  });

  test('over the cap, the songs played longest ago go first', () async {
    final old = song('old', 40, const Duration(days: 30));
    final mid = song('mid', 40, const Duration(days: 3));
    final recent = song('recent', 40, const Duration(hours: 1));

    final freed = await AudioCacheStore.enforceLimit(maxBytes: 90 * 1024);

    expect(old.existsSync(), isFalse);
    expect(File('${old.path}.mime').existsSync(), isFalse);
    expect(mid.existsSync(), isTrue);
    expect(recent.existsSync(), isTrue);
    expect(freed, 40 * 1024 + 10);
  });

  test('playing a song moves it to the back of the eviction line', () async {
    final favourite = song('favourite', 40, const Duration(days: 30));
    final other = song('other', 40, const Duration(days: 3));

    await AudioCacheStore.markPlayed(favourite);
    await AudioCacheStore.enforceLimit(maxBytes: 50 * 1024);

    expect(favourite.existsSync(), isTrue);
    expect(other.existsSync(), isFalse);
  });

  test('under the cap nothing is deleted', () async {
    final a = song('a', 10, const Duration(days: 30));
    expect(await AudioCacheStore.enforceLimit(maxBytes: 1024 * 1024), 0);
    expect(a.existsSync(), isTrue);
  });

  test('clear never touches a song still downloading', () async {
    song('done', 10, Duration.zero);
    final part = File('${dir.path}/playing.mp3.part')
      ..writeAsBytesSync(List.filled(1024, 1));
    final partMime = File('${dir.path}/playing.mp3.mime')
      ..writeAsStringSync('audio/mpeg');

    await AudioCacheStore.clear();

    expect(File('${dir.path}/done.mp3').existsSync(), isFalse);
    expect(part.existsSync(), isTrue,
        reason: 'Deleting it would break the song that is playing.');
    expect(partMime.existsSync(), isTrue);
  });

  test('a missing cache directory is an empty cache', () async {
    AudioCacheStore.debugDir = Directory('${dir.path}/never-created');
    expect(await AudioCacheStore.sizeBytes(), 0);
    expect(await AudioCacheStore.clear(), 0);
  });
}
