/// The paths that can start or continue audio playback.
///
/// Keeping the origin explicit makes it harder for a new transport control to
/// bypass the same entitlement decision used by the main play button.
enum PlaybackRequestOrigin {
  play,
  skipNext,
  skipPrevious,
  skipToQueueItem,
  playMediaItem,
  recovery,
  trialTimer,
}

enum PlaybackAccessReason {
  publicContent,
  fullSubscription,
  activeTrial,
  sessionNotReady,
  guestTrialExhausted,
  freemiumTrialExhausted,
}

class PlaybackAccessSnapshot {
  const PlaybackAccessSnapshot({
    required this.isSessionReady,
    required this.isAuthenticated,
    required this.hasFullSubscription,
    required this.hasActiveTrial,
    required this.isPubliclyFree,
  });

  /// True only after authentication has resolved to either a fully loaded
  /// account or a known signed-out session.
  final bool isSessionReady;

  /// This is a strict, loaded-account signal. Merely leaving guest mode is not
  /// authentication.
  final bool isAuthenticated;

  final bool hasFullSubscription;
  final bool hasActiveTrial;

  /// Explicit unmetered content. Public catalogue visibility alone does not
  /// imply that a track is free to stream without the normal trial limits.
  final bool isPubliclyFree;
}

class PlaybackAccessDecision {
  const PlaybackAccessDecision._(this.allowed, this.reason);

  const PlaybackAccessDecision.allow(PlaybackAccessReason reason)
    : this._(true, reason);

  const PlaybackAccessDecision.deny(PlaybackAccessReason reason)
    : this._(false, reason);

  final bool allowed;
  final PlaybackAccessReason reason;
}

/// Pure, fail-closed playback entitlement policy.
///
/// The policy deliberately does not accept `isGuestMode`: authorization is
/// based on a resolved session plus a strict authenticated-account signal.
/// Guest mode remains a presentation/navigation concern, not an entitlement.
abstract final class PlaybackAccessPolicy {
  static PlaybackAccessDecision evaluate(
    PlaybackAccessSnapshot snapshot, {
    required PlaybackRequestOrigin origin,
  }) {
    // The origin is intentionally part of the contract even though every
    // transport currently follows the same decision matrix.
    switch (origin) {
      case PlaybackRequestOrigin.play:
      case PlaybackRequestOrigin.skipNext:
      case PlaybackRequestOrigin.skipPrevious:
      case PlaybackRequestOrigin.skipToQueueItem:
      case PlaybackRequestOrigin.playMediaItem:
      case PlaybackRequestOrigin.recovery:
      case PlaybackRequestOrigin.trialTimer:
        break;
    }

    if (snapshot.isPubliclyFree) {
      return const PlaybackAccessDecision.allow(
        PlaybackAccessReason.publicContent,
      );
    }

    if (!snapshot.isSessionReady) {
      return const PlaybackAccessDecision.deny(
        PlaybackAccessReason.sessionNotReady,
      );
    }

    if (snapshot.isAuthenticated && snapshot.hasFullSubscription) {
      return const PlaybackAccessDecision.allow(
        PlaybackAccessReason.fullSubscription,
      );
    }

    if (snapshot.hasActiveTrial) {
      return const PlaybackAccessDecision.allow(
        PlaybackAccessReason.activeTrial,
      );
    }

    return PlaybackAccessDecision.deny(
      snapshot.isAuthenticated
          ? PlaybackAccessReason.freemiumTrialExhausted
          : PlaybackAccessReason.guestTrialExhausted,
    );
  }
}
