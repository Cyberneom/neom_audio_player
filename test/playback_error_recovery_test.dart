import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/utils/playback_error_recovery.dart';

/// Unit tests for the pure [PlaybackErrorRecovery] decision policy, plus
/// source-level structural assertions that `NeomAudioHandler` stays wired
/// to it (same style as `single_player_invariant_test.dart`).
void main() {
  group('PlaybackErrorRecovery policy', () {
    late PlaybackErrorRecovery recovery;

    setUp(() {
      recovery = PlaybackErrorRecovery();
    });

    test('first error on an item retries the same track', () {
      expect(recovery.registerError('a', hasNext: true),
          PlaybackRecoveryAction.retrySame);
      expect(recovery.sameItemErrors, 1);
      expect(recovery.totalAttempts, 1);
    });

    test('retries up to maxRetriesPerItem then skips when a next item exists', () {
      expect(recovery.registerError('a', hasNext: true),
          PlaybackRecoveryAction.retrySame);
      expect(recovery.registerError('a', hasNext: true),
          PlaybackRecoveryAction.retrySame);
      expect(recovery.registerError('a', hasNext: true),
          PlaybackRecoveryAction.skipNext);
    });

    test('gives up instead of skipping when there is no next item', () {
      for (var i = 0; i < PlaybackErrorRecovery.maxRetriesPerItem; i++) {
        expect(recovery.registerError('a', hasNext: false),
            PlaybackRecoveryAction.retrySame);
      }
      expect(recovery.registerError('a', hasNext: false),
          PlaybackRecoveryAction.giveUp);
    });

    test('per-item budget resets after a skip but global budget survives', () {
      // Burn the per-item budget of track A and skip.
      recovery.registerError('a', hasNext: true);
      recovery.registerError('a', hasNext: true);
      expect(recovery.registerError('a', hasNext: true),
          PlaybackRecoveryAction.skipNext);
      final attemptsAfterSkip = recovery.totalAttempts;

      // Track B starts with a fresh per-item budget.
      expect(recovery.sameItemErrors, 0);
      expect(recovery.registerError('b', hasNext: true),
          PlaybackRecoveryAction.retrySame);
      expect(recovery.sameItemErrors, 1);
      expect(recovery.totalAttempts, attemptsAfterSkip + 1);
    });

    test('global budget gives up after maxAttempts even across items', () {
      PlaybackRecoveryAction? last;
      // Alternate dead tracks so per-item budgets reset; only the global
      // cap can stop the loop.
      const ids = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
      for (var i = 0; i <= PlaybackErrorRecovery.maxAttempts; i++) {
        last = recovery.registerError(ids[i % ids.length], hasNext: true);
      }
      expect(last, PlaybackRecoveryAction.giveUp);
    });

    test('reset clears every budget', () {
      recovery.registerError('a', hasNext: true);
      recovery.registerError('a', hasNext: true);
      recovery.reset();
      expect(recovery.sameItemErrors, 0);
      expect(recovery.totalAttempts, 0);
      // Behaves like a fresh instance.
      expect(recovery.registerError('a', hasNext: false),
          PlaybackRecoveryAction.retrySame);
    });
  });

  group('NeomAudioHandler error-recovery wiring (source invariants)', () {
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

    test('subscribes to player.errorStream exactly once', () {
      expect('player.errorStream'.allMatches(handlerSource).length, 1,
          reason: 'The handler must listen to player.errorStream; '
              'without it a dead URL leaves the user in silence. '
              '(PublishSubject: single-subscription, one listener only.)');
    });

    test('holds one PlaybackErrorRecovery policy instance', () {
      expect(
          handlerSource.contains(
              'final PlaybackErrorRecovery _errorRecovery = PlaybackErrorRecovery()'),
          isTrue);
    });

    test('resets recovery when processing state becomes ready', () {
      final readyIndex = handlerSource.indexOf('case ProcessingState.ready:');
      expect(readyIndex, greaterThan(-1));
      final readyBlock = handlerSource.substring(readyIndex, readyIndex + 400);
      expect(readyBlock.contains('_errorRecovery.reset()'), isTrue,
          reason: 'Budgets must reset on healthy playback so transient '
              'errors do not accumulate forever.');
    });

    test('play() feeds missing audio sources into the recovery funnel', () {
      expect(handlerSource.contains('_handlePlaybackError('), isTrue);
      final playIndex = handlerSource.indexOf('Future<void> play() async');
      expect(playIndex, greaterThan(-1));
      final playBlock = handlerSource.substring(playIndex, playIndex + 1500);
      expect(playBlock.contains('_handlePlaybackError('), isTrue,
          reason: 'A null audio source inside play() must escalate through '
              'recovery instead of returning silently.');
    });

    test('uses connectivity_plus for offline detection and resume', () {
      expect(handlerSource.contains('Connectivity().checkConnectivity()'),
          isTrue);
      expect(handlerSource.contains('onConnectivityChanged'), isTrue,
          reason: 'An offline give-up must re-arm playback when '
              'connectivity returns.');
    });
  });
}
