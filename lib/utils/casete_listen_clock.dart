/// One listening window of an item: what a casete session records.
typedef CaseteListenWindow = ({String itemId, int seconds});

/// Measures how long each item is actually heard.
///
/// Casete sessions are what listeners' time is attributed by, so the clock
/// has to answer one question exactly: how long was THIS item audible? Two
/// rules, each of which the previous stopwatch wiring broke:
///
/// 1. **Time counts only while audio is audible** — the player is playing
///    and ready. A queue restored at launch, a seek while paused, or a buffer
///    stall is not listening. The old wiring started the stopwatch whenever an
///    item became current or the player became ready, so an item left paused
///    for ten minutes reported ten minutes.
/// 2. **Each item has its own window, closed when the item changes.** The old
///    shared stopwatch started a new reference without stopping the previous
///    one: an item that advanced on its own was never saved, and it kept
///    running, so replaying it later reported every minute since it first
///    played.
class CaseteListenClock {
  CaseteListenClock({Stopwatch Function()? stopwatchFactory})
      : _newStopwatch = stopwatchFactory ?? Stopwatch.new;

  final Stopwatch Function() _newStopwatch;
  String? _itemId;
  Stopwatch? _window;
  bool _audible = false;

  /// The item whose time is being measured.
  String? get itemId => _itemId;

  /// Seconds heard of the current item in the open window.
  int get elapsedSeconds => _window?.elapsed.inSeconds ?? 0;

  /// Reports whether audio is audible right now (playing and ready).
  void setAudible(bool audible) {
    _audible = audible;
    if (audible) {
      _window?.start();
    } else {
      _window?.stop();
    }
  }

  /// Moves the clock to [itemId] and returns the previous item's window,
  /// now closed, or null when the item did not change.
  CaseteListenWindow? switchTo(String itemId) {
    if (itemId == _itemId) return null;
    final closed = _itemId == null ? null : takeWindow();
    _itemId = itemId;
    _window = _newStopwatch();
    if (_audible) _window!.start();
    return closed;
  }

  /// Returns the current item's window and opens a fresh one for the same
  /// item, keeping the audible state. Used when a session is saved without
  /// the item changing: a pause, a stop, a restart from zero.
  CaseteListenWindow? takeWindow() {
    final id = _itemId;
    final window = _window;
    if (id == null || window == null) return null;
    final seconds = window.elapsed.inSeconds;
    window.reset();
    return (itemId: id, seconds: seconds);
  }

  /// Forgets the current item without reporting it (e.g. crossing the
  /// guest/account boundary, where the time belongs to nobody).
  void clear() {
    _window?.stop();
    _itemId = null;
    _window = null;
  }
}
