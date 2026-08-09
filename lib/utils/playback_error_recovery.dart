/// Pure decision policy for playback error recovery.
///
/// Extracted from `NeomAudioHandler` so the escalation rules are unit-testable
/// without a platform `AudioPlayer`. The handler wires player events in and
/// executes the returned [PlaybackRecoveryAction]:
///
/// * [PlaybackRecoveryAction.retrySame] — rebuild/re-seek the current source
///   and try the same track again (per-item budget: [maxRetriesPerItem]).
/// * [PlaybackRecoveryAction.skipNext] — the current track is considered
///   dead; advance to the next queue item (only when one exists).
/// * [PlaybackRecoveryAction.giveUp] — the global attempt budget
///   ([maxAttempts]) is exhausted or there is nowhere to skip to; pause and
///   surface the problem to the user.
///
/// Budgets reset via [reset] once playback reaches a healthy ready state, so
/// a transient network blip does not poison the whole session.
enum PlaybackRecoveryAction { retrySame, skipNext, giveUp }

class PlaybackErrorRecovery {
  /// How many times the same item is retried before it is declared dead.
  static const int maxRetriesPerItem = 2;

  /// Global cap of recovery actions across items before giving up, guarding
  /// against skip-loops through a queue of dead tracks.
  static const int maxAttempts = 5;

  int _sameItemErrors = 0;
  int _totalAttempts = 0;
  String? _lastErrorItemId;

  int get sameItemErrors => _sameItemErrors;
  int get totalAttempts => _totalAttempts;

  /// Registers a playback error for [itemId] and decides what to do next.
  ///
  /// [hasNext] must reflect whether the queue holds another item after the
  /// failing one; without it, a dead track can only be retried or abandoned.
  PlaybackRecoveryAction registerError(String itemId, {required bool hasNext}) {
    if (itemId == _lastErrorItemId) {
      _sameItemErrors++;
    } else {
      _lastErrorItemId = itemId;
      _sameItemErrors = 1;
    }
    _totalAttempts++;

    if (_totalAttempts > maxAttempts) {
      return PlaybackRecoveryAction.giveUp;
    }
    if (_sameItemErrors <= maxRetriesPerItem) {
      return PlaybackRecoveryAction.retrySame;
    }
    if (hasNext) {
      // Moving to a different item: its per-item budget starts fresh while
      // the global budget keeps guarding against a queue full of dead tracks.
      _sameItemErrors = 0;
      _lastErrorItemId = null;
      return PlaybackRecoveryAction.skipNext;
    }
    return PlaybackRecoveryAction.giveUp;
  }

  /// Drops all budgets. Call when playback reaches a healthy ready state or
  /// when the queue/media item changes through a successful user action.
  void reset() {
    _sameItemErrors = 0;
    _totalAttempts = 0;
    _lastErrorItemId = null;
  }
}
