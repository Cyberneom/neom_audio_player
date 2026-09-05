import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/utils/playback_access_policy.dart';

void main() {
  const guestWithTrial = PlaybackAccessSnapshot(
    isSessionReady: true,
    isAuthenticated: false,
    hasFullSubscription: false,
    hasActiveTrial: true,
    isPubliclyFree: false,
  );
  const loginInProgress = PlaybackAccessSnapshot(
    isSessionReady: false,
    isAuthenticated: false,
    hasFullSubscription: false,
    hasActiveTrial: true,
    isPubliclyFree: false,
  );
  const exhaustedGuest = PlaybackAccessSnapshot(
    isSessionReady: true,
    isAuthenticated: false,
    hasFullSubscription: false,
    hasActiveTrial: false,
    isPubliclyFree: false,
  );
  const exhaustedFreemium = PlaybackAccessSnapshot(
    isSessionReady: true,
    isAuthenticated: true,
    hasFullSubscription: false,
    hasActiveTrial: false,
    isPubliclyFree: false,
  );
  const premium = PlaybackAccessSnapshot(
    isSessionReady: true,
    isAuthenticated: true,
    hasFullSubscription: true,
    hasActiveTrial: false,
    isPubliclyFree: false,
  );

  group('PlaybackAccessPolicy', () {
    test('guest can play during the intentional daily trial', () {
      final decision = PlaybackAccessPolicy.evaluate(
        guestWithTrial,
        origin: PlaybackRequestOrigin.play,
      );

      expect(decision.allowed, isTrue);
      expect(decision.reason, PlaybackAccessReason.activeTrial);
    });

    test(
      'login-in-progress fails closed even if a stale trial flag is true',
      () {
        final decision = PlaybackAccessPolicy.evaluate(
          loginInProgress,
          origin: PlaybackRequestOrigin.play,
        );

        expect(decision.allowed, isFalse);
        expect(decision.reason, PlaybackAccessReason.sessionNotReady);
      },
    );

    test('guest is denied after the five-minute trial is exhausted', () {
      final decision = PlaybackAccessPolicy.evaluate(
        exhaustedGuest,
        origin: PlaybackRequestOrigin.play,
      );

      expect(decision.allowed, isFalse);
      expect(decision.reason, PlaybackAccessReason.guestTrialExhausted);
    });

    test('authenticated freemium is denied after its trial is exhausted', () {
      final decision = PlaybackAccessPolicy.evaluate(
        exhaustedFreemium,
        origin: PlaybackRequestOrigin.play,
      );

      expect(decision.allowed, isFalse);
      expect(decision.reason, PlaybackAccessReason.freemiumTrialExhausted);
    });

    test('premium remains allowed without a trial', () {
      final decision = PlaybackAccessPolicy.evaluate(
        premium,
        origin: PlaybackRequestOrigin.play,
      );

      expect(decision.allowed, isTrue);
      expect(decision.reason, PlaybackAccessReason.fullSubscription);
    });

    test('explicitly free content remains playable while auth resolves', () {
      const publicDuringBootstrap = PlaybackAccessSnapshot(
        isSessionReady: false,
        isAuthenticated: false,
        hasFullSubscription: false,
        hasActiveTrial: false,
        isPubliclyFree: true,
      );

      final decision = PlaybackAccessPolicy.evaluate(
        publicDuringBootstrap,
        origin: PlaybackRequestOrigin.play,
      );

      expect(decision.allowed, isTrue);
      expect(decision.reason, PlaybackAccessReason.publicContent);
    });

    test('skip, media-item and recovery paths cannot bypass exhaustion', () {
      const bypassOrigins = <PlaybackRequestOrigin>[
        PlaybackRequestOrigin.skipNext,
        PlaybackRequestOrigin.skipPrevious,
        PlaybackRequestOrigin.skipToQueueItem,
        PlaybackRequestOrigin.playMediaItem,
        PlaybackRequestOrigin.recovery,
      ];

      for (final origin in bypassOrigins) {
        final decision = PlaybackAccessPolicy.evaluate(
          exhaustedFreemium,
          origin: origin,
        );
        expect(
          decision.allowed,
          isFalse,
          reason: '${origin.name} must use the same exhausted entitlement',
        );
      }
    });
  });

  group('NeomAudioHandler authorization wiring', () {
    late String handlerSource;

    setUpAll(() {
      handlerSource = File('lib/neom_audio_handler.dart').readAsStringSync();
    });

    String between(String start, String end) {
      final startIndex = handlerSource.indexOf(start);
      expect(startIndex, isNonNegative, reason: 'Missing $start');
      final endIndex = handlerSource.indexOf(end, startIndex + start.length);
      expect(endIndex, greaterThan(startIndex), reason: 'Missing $end');
      return handlerSource.substring(startIndex, endIndex);
    }

    test('entitlement mirrors start fail-closed', () {
      expect(handlerSource, contains('bool allowFullAccess = false;'));
      expect(handlerSource, contains('bool allowFreeTrial = false;'));
      expect(
        handlerSource,
        isNot(contains(': true;\n      if (!isFree && !allowFullAccess)')),
      );
    });

    test('all public playback transports call the central gate', () {
      final transports = <(String, String)>[
        ('Future<void> skipToNext() async', 'Future<void> fastForward() async'),
        (
          'Future<void> skipToPrevious() async',
          'Future<void> skipToQueueItem(int index) async',
        ),
        (
          'Future<void> skipToQueueItem(int index) async',
          'Future<void> _skipToQueueItemAfterAuthorization(',
        ),
        (
          'Future<void> playMediaItem(MediaItem mediaItem) async',
          'Future<void> play() async',
        ),
        ('Future<void> play() async', 'Future<void> pause() async'),
      ];

      for (final (start, end) in transports) {
        expect(
          between(start, end),
          contains('_authorizePlayback('),
          reason: '$start must not bypass playback authorization',
        );
      }
    });

    test('every recovery restart path calls the central gate', () {
      final recoveryPaths = <(String, String)>[
        (
          'Future<void> _handlePlaybackError(Object error) async',
          'Future<bool> _tryResolveFreshUrl(String itemId) async',
        ),
        (
          'Future<bool> _tryResolveFreshUrl(String itemId) async',
          'Future<bool> _reloadCurrentItem() async',
        ),
        (
          'Future<bool> _reloadCurrentItem() async',
          'Future<bool> _isOnline() async',
        ),
      ];

      for (final (start, end) in recoveryPaths) {
        expect(
          between(start, end),
          contains('PlaybackRequestOrigin.recovery'),
          reason: '$start must not restart playback without authorization',
        );
      }
    });

    test('legacy guest-mode-only playback condition is gone', () {
      expect(handlerSource, isNot(contains('AppConfig.instance.isGuestMode')));
    });
  });
}
