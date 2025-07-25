import 'package:rxdart/rxdart.dart';

import '../entities/queue_state.dart';

abstract class AudioHandlerService {

  Stream<QueueState> get queueState;
  Future<void> moveQueueItem(int currentIndex, int newIndex);
  ValueStream<double> get volume;
  Future<void> setVolume(double volume);
  ValueStream<double> get speed;

}
