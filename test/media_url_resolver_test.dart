import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/utils/audio_quality_swap.dart';
import 'package:neom_audio_player/utils/media_url_resolver_registry.dart';

/// Unit tests for the fresh-URL resolver registry and the quality-swap
/// helpers, plus source-level structural assertions that the handler stays
/// wired to them (same style as `single_player_invariant_test.dart`).
void main() {
  group('MediaUrlResolverRegistry', () {
    late MediaUrlResolverRegistry registry;

    final item = {'url': 'https://cdn/old_96.mp3', 'ownerId': 'u1'};

    setUp(() {
      registry = MediaUrlResolverRegistry();
    });

    test('empty registry resolves to null', () async {
      expect(await registry.resolveFreshUrl('a', item), isNull);
    });

    test('first non-empty, different URL wins', () async {
      registry.register('nullResolver', (id, extras) async => null);
      registry.register('sameResolver', (id, extras) async => 'https://cdn/old_96.mp3');
      registry.register('freshResolver', (id, extras) async => 'https://cdn/fresh_96.mp3');
      registry.register('neverReached', (id, extras) async => 'https://cdn/other.mp3');
      expect(await registry.resolveFreshUrl('a', item), 'https://cdn/fresh_96.mp3');
    });

    test('a throwing resolver is isolated and skipped', () async {
      registry.register('broken', (id, extras) async => throw StateError('boom'));
      registry.register('working', (id, extras) async => 'https://cdn/new.mp3');
      expect(await registry.resolveFreshUrl('a', item), 'https://cdn/new.mp3');
    });

    test('empty-string results are rejected', () async {
      registry.register('empty', (id, extras) async => '');
      expect(await registry.resolveFreshUrl('a', item), isNull);
    });

    test('re-registering the same owner replaces the resolver', () async {
      registry.register('owner', (id, extras) async => 'https://cdn/v1.mp3');
      registry.register('owner', (id, extras) async => 'https://cdn/v2.mp3');
      expect(registry.length, 1);
      expect(await registry.resolveFreshUrl('a', item), 'https://cdn/v2.mp3');
    });

    test('unregister removes the resolver', () async {
      registry.register('owner', (id, extras) async => 'https://cdn/v1.mp3');
      registry.unregister('owner');
      expect(registry.isEmpty, isTrue);
      expect(await registry.resolveFreshUrl('a', item), isNull);
    });

    test('resolver receives the item id and extras', () async {
      String? seenId;
      registry.register('spy', (id, extras) async {
        seenId = id;
        return null;
      });
      await registry.resolveFreshUrl('track-42', item);
      expect(seenId, 'track-42');
    });
  });

  group('AudioQualitySwap.apply', () {
    test('rewrites the baseline _96 suffix to the preferred bitrate', () {
      expect(AudioQualitySwap.apply('https://hub/song_96.mp3', '320 kbps'),
          'https://hub/song_320.mp3');
      expect(AudioQualitySwap.apply('https://hub/song_96.mp3', '128 kbps'),
          'https://hub/song_128.mp3');
    });

    test('returns the url unchanged when nothing should happen', () {
      // No preferred quality configured.
      expect(AudioQualitySwap.apply('https://hub/song_96.mp3', ''),
          'https://hub/song_96.mp3');
      // No baseline suffix present.
      expect(AudioQualitySwap.apply('https://hub/song.mp3', '320 kbps'),
          'https://hub/song.mp3');
      // Malformed preference must not corrupt the URL.
      expect(AudioQualitySwap.apply('https://hub/song_96.mp3', 'high'),
          'https://hub/song_96.mp3');
    });

    test('wouldSwap mirrors apply', () {
      expect(AudioQualitySwap.wouldSwap('https://hub/song_96.mp3', '320 kbps'), isTrue);
      expect(AudioQualitySwap.wouldSwap('https://hub/song_96.mp3', ''), isFalse);
      expect(AudioQualitySwap.wouldSwap('https://hub/song.mp3', '320 kbps'), isFalse);
    });
  });

  group('NeomAudioHandler URL-resolver wiring (source invariants)', () {
    late String handlerSource;

    String stripComments(String src) {
      var out = src.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
      out = out.replaceAll(RegExp(r'//[^\n]*'), '');
      return out;
    }

    setUpAll(() {
      final file = File('lib/neom_audio_handler.dart');
      expect(file.existsSync(), isTrue,
          reason: 'lib/neom_audio_handler.dart not found — '
              'are tests being run from the module root?');
      handlerSource = stripComments(file.readAsStringSync());
    });

    test('exposes the resolver registry through the service interface', () {
      expect(handlerSource.contains('registerUrlResolver'), isTrue);
      expect(handlerSource.contains('unregisterUrlResolver'), isTrue);
      expect(handlerSource.contains('MediaUrlResolverRegistry()'), isTrue);
    });

    test('recovery consults resolvers before reloading', () {
      final recoveryIndex = handlerSource.indexOf('PlaybackRecoveryAction.retrySame');
      expect(recoveryIndex, greaterThan(-1));
      final retryBlock =
          handlerSource.substring(recoveryIndex, recoveryIndex + 1200);
      final freshIndex = retryBlock.indexOf('_tryResolveFreshUrl');
      final reloadIndex = retryBlock.indexOf('_reloadCurrentItem()');
      expect(freshIndex, greaterThan(-1));
      expect(reloadIndex, greaterThan(-1));
      expect(freshIndex, lessThan(reloadIndex),
          reason: 'A fresh URL must be requested before blindly reloading '
              'the same stale URL.');
    });

    test('quality swap honors the noQualitySwap bypass flag', () {
      expect(handlerSource.contains('AudioQualitySwap.noSwapFlag'), isTrue);
      expect(handlerSource.contains('AudioQualitySwap.apply('), isTrue);
    });

    test('refreshLink replaces stale sources in place instead of appending', () {
      final refreshIndex = handlerSource.indexOf('Future<void> refreshLink(');
      expect(refreshIndex, greaterThan(-1));
      final refreshBlock =
          handlerSource.substring(refreshIndex, refreshIndex + 1200);
      expect(refreshBlock.contains('removeAudioSourceAt'), isTrue);
      expect(refreshBlock.contains('insertAudioSource'), isTrue);
    });
  });
}
