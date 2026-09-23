import 'package:flutter_test/flutter_test.dart';
import 'package:neom_audio_player/utils/casete_listen_clock.dart';

/// Test time: advanced by hand, shared by every stopwatch the clock creates.
class _Time {
  Duration now = Duration.zero;
  void pass(int seconds) => now += Duration(seconds: seconds);
}

class _Stopwatch extends Fake implements Stopwatch {
  _Stopwatch(this.time);
  final _Time time;
  Duration _banked = Duration.zero;
  Duration? _since;

  @override
  bool get isRunning => _since != null;
  @override
  Duration get elapsed =>
      _banked + (_since == null ? Duration.zero : time.now - _since!);
  @override
  void start() => _since ??= time.now;
  @override
  void stop() {
    if (_since == null) return;
    _banked += time.now - _since!;
    _since = null;
  }

  @override
  void reset() {
    _banked = Duration.zero;
    if (_since != null) _since = time.now;
  }
}

void main() {
  late _Time time;
  late CaseteListenClock clock;

  setUp(() {
    time = _Time();
    clock = CaseteListenClock(stopwatchFactory: () => _Stopwatch(time));
  });

  test('an item that advances on its own hands back its time', () {
    // Album played straight through: nobody pauses or skips, and no
    // transport method runs. The item change alone must close the window.
    clock.switchTo('a');
    clock.setAudible(true);
    time.pass(180);

    final closed = clock.switchTo('b');

    expect(closed, (itemId: 'a', seconds: 180));
    expect(clock.itemId, 'b');
  });

  test('a replayed item starts from zero, not from its first play', () {
    clock.switchTo('a');
    clock.setAudible(true);
    time.pass(30);
    clock.switchTo('b');
    time.pass(600); // ten minutes of other music
    clock.switchTo('a');
    time.pass(20);

    expect(clock.switchTo('c'), (itemId: 'a', seconds: 20),
        reason: 'The old stopwatch kept running and reported 650 s.');
  });

  test('time does not count while nothing is audible', () {
    // A queue restored at launch makes an item current without playing it.
    clock.switchTo('a');
    time.pass(600);
    clock.setAudible(true);
    time.pass(40);
    clock.setAudible(false); // paused, buffering, or seeking while paused
    time.pass(300);

    expect(clock.elapsedSeconds, 40);
  });

  test('a new item keeps the audible state of the player', () {
    clock.switchTo('a');
    clock.setAudible(true);
    time.pass(10);
    clock.switchTo('b'); // gapless advance while playing
    time.pass(15);
    expect(clock.elapsedSeconds, 15);
  });

  test('taking a window restarts it for the same item', () {
    clock.switchTo('a');
    clock.setAudible(true);
    time.pass(50);

    expect(clock.takeWindow(), (itemId: 'a', seconds: 50));
    time.pass(7);
    expect(clock.elapsedSeconds, 7,
        reason: 'Still playing: the next window counts from here.');
  });

  test('the same item again is not a change', () {
    clock.switchTo('a');
    clock.setAudible(true);
    time.pass(12);
    expect(clock.switchTo('a'), isNull);
    expect(clock.elapsedSeconds, 12);
  });

  test('clearing forgets the time without reporting it', () {
    clock.switchTo('a');
    clock.setAudible(true);
    time.pass(90);
    clock.clear();

    expect(clock.itemId, isNull);
    expect(clock.takeWindow(), isNull);
    expect(clock.switchTo('b'), isNull,
        reason: 'Time heard before the account changed belongs to nobody.');
  });
}
