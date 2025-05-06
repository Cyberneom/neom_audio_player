import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:neom_commerce/woo/data/api_services/woo_orders_api.dart';
import 'package:neom_commons/core/data/implementations/app_hive_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';
import 'package:neom_commons/core/utils/neom_stopwatch.dart';
import 'package:neom_media_player/utils/helpers/media_item_mapper.dart';
import 'package:rxdart/rxdart.dart' as rx;

import '../../data/firestore/casete_session_firestore.dart';
import '../../data/firestore/casete_trial_usage_manager.dart';
import '../../data/implementations/player_hive_controller.dart';
import '../../data/implementations/playlist_hive_controller.dart';
import '../../ui/player/media_player_controller.dart';
import '../../ui/player/miniplayer_controller.dart';
import '../../utils/audio_player_stats.dart';
import 'package:neom_commons/core/utils/constants/app_hive_constants.dart';
import '../../utils/constants/audio_player_constants.dart';
import '../../utils/neom_audio_utilities.dart';
import '../entities/casete_session.dart';
import '../entities/queue_state.dart';
import 'neom_audio_service.dart';

class NeomAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler implements NeomAudioService {

  int? count;
  Timer? _sleepTimer;

  AudioPlayer player = AudioPlayer();
  MediaItem? currentMediaItem;

  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(
      children: []);

  String connectionType = AudioPlayerConstants.wifi;

  final List<String> refreshLinks = [];
  bool jobRunning = false;

  PlayerHiveController playerHiveController =  PlayerHiveController();

  bool stopForegroundService = true;

  final rx.BehaviorSubject<List<MediaItem>> _recentSubject = rx.BehaviorSubject
      .seeded(<MediaItem>[]);

  final userController = Get.find<UserController>();
  final neomStopwatch =  NeomStopwatch();

  int caseteSessionDuration = 0; //Seconds per session
  int casetePerSession = 0; //Pages per session
  int averageCasete = 0;
  bool isCaseteElegible = true;
  bool isAuthor = false;
  bool isLastPage = false;
  bool isFree = false;
  bool allowFullAccess = false;
  bool allowFreeTrial = true;

  @override
  final rx.BehaviorSubject<double> volume = rx.BehaviorSubject.seeded(1.0);
  @override
  final rx.BehaviorSubject<double> speed = rx.BehaviorSubject.seeded(1.0);
  final _mediaItemExpando = Expando<MediaItem>();

  Stream<List<IndexedAudioSource>> get _effectiveSequence =>
      rx.Rx.combineLatest3<List<IndexedAudioSource>?,
          List<int>?,
          bool,
          List<IndexedAudioSource>?>(
          player.sequenceStream, player.shuffleIndicesStream,
          player.shuffleModeEnabledStream, (sequence, shuffleIndices,
          shuffleModeEnabled) {
        if (sequence == null) return [];
        if (!shuffleModeEnabled) return sequence;
        if (shuffleIndices == null) return null;
        if (shuffleIndices.length != sequence.length) return null;
        return shuffleIndices.map((i) => sequence[i]).toList();
      }).whereType<List<IndexedAudioSource>>();

  @override
  Stream<QueueState> get queueState =>
      rx.Rx.combineLatest3<List<MediaItem>,
          PlaybackState,
          List<int>,
          QueueState>(queue, playbackState,
        player.shuffleIndicesStream.whereType<List<int>>(),
            (queue, playbackState, shuffleIndices) =>
            QueueState(
              queue, playbackState.queueIndex,
              playbackState.shuffleMode == AudioServiceShuffleMode.all
                  ? shuffleIndices : null,
              playbackState.repeatMode,
            ),
      ).where((state) =>
      state.shuffleIndices == null ||
          state.queue.length == state.shuffleIndices!.length,
      );

  NeomAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    AppUtilities.logger.t('Starting NeomAudioHandler');

    try {
      startService();

      if(!isFree) {
        if(allowFullAccess) {
          //TODO se agregaran comportamientos
          if(isCaseteElegible) {
            neomStopwatch.start(mediaItem.value?.title ?? '',);
          }
        } else {
          startFreeTrialTimer();
        }
      }
    } catch (e) {
      AppUtilities.logger.e('Error while loading last queue $e');
    }


    ///DEPRECATED if (!jobRunning) refreshJob();
  }

  Future<void> setListeners() async {
    mediaItem.whereType<MediaItem>().listen((item) async {
      if (count != null) {
        count = count! - 1;
        if (count! <= 0) {
          count = null;
          await stop();
        }
      }

      currentMediaItem = item;
      setItemInMediaPlayers();

      if (item.artUri.toString().startsWith(AppConstants.http)) {
        neomStopwatch.start(mediaItem.value?.id ?? '');
        _recentSubject.add([item]);
      }
    });

    rx.Rx.combineLatest4<int?, List<MediaItem>, bool, List<int>?, MediaItem?>(
        player.currentIndexStream, queue, player.shuffleModeEnabledStream,
        player.shuffleIndicesStream,
            (index, queue, shuffleModeEnabled, shuffleIndices) {
          final queueIndex = NeomAudioUtilities.getQueueIndex(player, index);
          return (queueIndex != null && queueIndex < queue.length)
              ? queue[queueIndex] : null;
        }).whereType<MediaItem>().distinct().listen(mediaItem.add);

    player.playbackEventStream.listen(_broadcastState);
    player.shuffleModeEnabledStream.listen((enabled) => _broadcastState(player.playbackEvent));
    player.loopModeStream.listen((event) => _broadcastState(player.playbackEvent));
    player.processingStateStream.listen((state) async {
      AppUtilities.logger.d('Audio Player - Processing Stream: ${state.name}');
      switch (state) {
        case ProcessingState.loading:
          break;
        case ProcessingState.ready:
          if(neomStopwatch.currentReference != (mediaItem.value?.id ?? '')) {
            neomStopwatch.start(mediaItem.value?.id ?? '');
          }
          break;
        case ProcessingState.buffering:
          break;
        case ProcessingState.completed:
          await stop();
          player.seek(Duration.zero, index: 0);
          neomStopwatch.stop();
        case ProcessingState.idle:
          break;
      }
    });

    // Broadcast the current queue.
    _effectiveSequence.map((sequence) =>
        sequence.map((source) => _mediaItemExpando[source]!)
            .toList(),).pipe(queue);

  }

  Future<void> loadLastQueue() async {
    if (playerHiveController.loadStart) {
      await Future.delayed(const Duration(milliseconds: 500)); // Agrega un breve delay para dar tiempo a otros procesos
      final List lastQueueList = playerHiveController.lastQueueList;
      if (lastQueueList.isNotEmpty) {
        final List<MediaItem> lastQueue = lastQueueList.map((e) =>
            MediaItemMapper.fromJSON(e as Map)).toList();

        if (lastQueue.isNotEmpty) {
          try {
            _playlist.addAll(await _itemsToSources(lastQueue));
            await gotoLastIndexAndPosition();
          } catch (e) {
            AppUtilities.logger.e('Error while setting last audiosource ${e.toString()}');
          }
        }
      }
    }
  }

  Future<void> gotoLastIndexAndPosition() async {
    final int lastIndex = playerHiveController.lastIndex;
    final int lastPos = playerHiveController.lastPos;
    if (lastIndex != 0 || lastPos > 0) {
      await player.seek(Duration(seconds: lastPos), index: lastIndex);
    }
  }

  /// Broadcasts the current state to all clients.
  void _broadcastState(PlaybackEvent event) {
    try {
      final playing = player.playing;
      bool liked = false;
      if (mediaItem.value != null) {
        liked = PlaylistHiveController().checkPlaylist(
            AppHiveBox.favoriteItems.name, mediaItem.value!.id);
      }
      final queueIndex = NeomAudioUtilities.getQueueIndex(
          player, event.currentIndex);

      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            if (liked) MediaControl.rewind else
              MediaControl.fastForward,
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else
              MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          systemActions: NeomAudioUtilities.mediaActions,
          androidCompactActionIndices: playerHiveController.preferredCompactNotificationButtons,
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[player.processingState]!,
          playing: playing,
          updatePosition: player.position,
          bufferedPosition: player.bufferedPosition,
          speed: player.speed,
          queueIndex: queueIndex,
        ),
      );
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  // void refreshJob() {
  //   jobRunning = true;
  //   while (refreshLinks.isNotEmpty) {
  //     // isolateSendPort?.send(refreshLinks.removeAt(0));
  //   }
  //   jobRunning = false;
  // }

  Future<void> refreshLink(Map newData) async {
    AppUtilities.logger.i(
        'Audio Player refreshLink | received new link for ${newData['title']}');
    final MediaItem newItem = MediaItemMapper.fromJSON(newData);

    AppUtilities.logger.i('player | inserting refreshed item');

    addQueueItem(newItem);
  }

  Future<AudioSource?> _itemToSource(MediaItem mediaItem) async {

    AudioSource? audioSource;
    AppUtilities.logger.d("Moving mediaItem ${mediaItem.title} to audioSource for Music Player ");
    try {


      if (mediaItem.artUri.toString().startsWith('file:')) {
        audioSource = AudioSource.uri(Uri.file(mediaItem.extras!['url'].toString()));
      } else {
        if(playerHiveController.useDownload) {
          AppUtilities.logger.d("Looking for files from downloads");
          final downloadsBox = await AppHiveController().getBox(AppHiveBox.downloads.name);
          if(downloadsBox != null && downloadsBox.containsKey(mediaItem.id)) {
            audioSource = AudioSource.uri(
              Uri.file(downloadsBox.get(mediaItem.id)['path'].toString(),),
              tag: mediaItem.id,
            );
          }
        } else {
          String audioUrl = '';
          if (mediaItem.extras!['url'] != null && mediaItem.extras!['url']
              .toString().isNotEmpty) {
            audioUrl = mediaItem.extras!['url'].toString();
            if (playerHiveController.preferredQuality.isNotEmpty && audioUrl.contains('_96.')) {
              audioUrl = audioUrl.replaceAll(
                  '_96.', "_${playerHiveController.preferredQuality.replaceAll(' kbps', '')}.");
            }
          }

          if (playerHiveController.cacheSong && AppUtilities.isInternal(audioUrl)) {
            audioSource = LockCachingAudioSource(Uri.parse(audioUrl));
          } else {
            audioSource = AudioSource.uri(Uri.parse(audioUrl));
          }
        }
      }

      if(audioSource != null) _mediaItemExpando[audioSource] = mediaItem;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return audioSource;
  }

  Future<List<AudioSource>> _itemsToSources(List<MediaItem> mediaItems) async {
    final List<AudioSource> sources = [];

    try {
      for (final element in mediaItems) {
        AudioSource? src = await _itemToSource(element);
        if (src != null) sources.add(src);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return sources;
  }

  @override
  Future<void> onTaskRemoved() async {
    final bool stopForegroundService = PlayerHiveController()
        .stopForegroundService;
    if (stopForegroundService) {
      await stop();
    }
  }

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    switch (parentMediaId) {
      case AudioService.recentRootId:
        return _recentSubject.value;
      default:
        return queue.value;
    }
  }

  @override
  rx.ValueStream<Map<String, dynamic>> subscribeToChildren(
      String parentMediaId) {
    switch (parentMediaId) {
      case AudioService.recentRootId:
        final stream = _recentSubject.map((_) => <String, dynamic>{});
        return _recentSubject.hasValue
            ? stream.shareValueSeeded(<String, dynamic>{})
            : stream.shareValue();
      default:
        return Stream.value(queue.value)
            .map((_) => <String, dynamic>{})
            .shareValue();
    }
  }

  void startService() async {
    if(player.playing) return;

    AppUtilities.logger.t('Starting AudioPlayer Service');
    // if (player.playing) player.dispose();
    player = AudioPlayer();
    await loadLastQueue();
    await player.setAudioSource(_playlist, preload: false);
    //TODO Recordar si es necesario
    // speed.debounceTime(const Duration(milliseconds: 250)).listen((speed) {
    //   playbackState.add(playbackState.value.copyWith(speed: speed));
    // });
    await setListeners();
  }

  Future<void> addLastQueue(List<MediaItem> queue) async {

    if (queue.isNotEmpty) {
      AppUtilities.logger.d('Saving last queue');
      final lastQueue = queue.map((item) {
        return MediaItemMapper.toJSON(item);
      }).toList();
      playerHiveController.setLastQueue(lastQueue);
    }
  }

  Future<void> skipToMediaItem(String id, {int index = 0}) async {
    AppUtilities.logger.t('skipToMediaItem $id');

    if (queue.value.indexWhere((item) => item.id == id) >= 0) {
      index = queue.value.indexWhere((item) => item.id == id);
      AppUtilities.logger.t(
          'SkipToMediaItem: mediaItem found in queue with Index $index');
    }

    player.seek(Duration.zero,
      index: player.shuffleModeEnabled && index != 0 ? player
          .shuffleIndices![index] : index,
    );

  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    AppUtilities.logger.d('addQueueItem');
    AudioSource? res = await _itemToSource(mediaItem);
    if (res != null) {
      await _playlist.add(res);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    AppUtilities.logger.d('addQueueItems');
    await _playlist.addAll(await _itemsToSources(mediaItems));
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    AppUtilities.logger.d('insertQueueItem');
    AudioSource? res = await _itemToSource(mediaItem);
    if (res != null) {
      await _playlist.insert(index, res);
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    AppUtilities.logger.d(
        "Updating Music Player Queue with ${newQueue.length} items");
    try {
      await _playlist.clear();
      final List<AudioSource> sources = await _itemsToSources(newQueue);
      await _playlist.addAll(sources);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    AppUtilities.logger.d('updateMediaItem');
    final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    _mediaItemExpando[player.sequence![index]] = mediaItem;
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    AppUtilities.logger.d('removeQueueItem');
    final index = queue.value.indexOf(mediaItem);
    await _playlist.removeAt(index);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    AppUtilities.logger.d('removeQueueItemAt at index: $index');
    await _playlist.removeAt(index);
  }

  @override
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    AppUtilities.logger.d(
        'removeQueueItemAt from index: $currentIndex to $newIndex');
    await _playlist.move(currentIndex, newIndex);
  }

  @override
  Future<void> skipToNext() async {
    AppUtilities.logger.d('skipToNext');
    //TODO Agregar stopwatch CASETE

    final index = queue.value.indexWhere((item) =>
    item.id == currentMediaItem!.id);
    if (queue.value.length >= index + 1) {
      MediaItem nextMedia = queue.value.elementAt(index + 1);
      currentMediaItem = nextMedia;
      setItemInMediaPlayers();
    }
    //TODO Agregar stopwatch CASETE
    player.seekToNext();
  }

  /// This is called when the user presses the "like" button.
  @override
  Future<void> fastForward() async {
    AppUtilities.logger.d('');
    if (mediaItem.value?.id != null) {
      PlaylistHiveController().addItemToPlaylist(
          AppHiveBox.favoriteItems.name, mediaItem.value!);
      _broadcastState(player.playbackEvent);
    }
  }

  @override
  Future<void> rewind() async {
    AppUtilities.logger.d('rewind');
    if (mediaItem.value?.id != null) {
      PlaylistHiveController().removeLiked(mediaItem.value!.id);
      _broadcastState(player.playbackEvent);
    }
  }

  int currentDuration = 0;
  @override
  Future<void> skipToPrevious() async {
    AppUtilities.logger.d('skipToPrevious');
    //TODO Agregar stopwatch CASETE
    neomStopwatch.start(mediaItem.value?.title ?? '');


    if (playerHiveController.resetOnSkip) {
      if ((player.position.inSeconds) <= 2) {
        AppUtilities.logger.d('skipToPrevious');

        final index = queue.value.indexWhere((item) =>
        item.id == currentMediaItem!.id);
        if (queue.value.isNotEmpty && (index - 1 >= 0)) {
          MediaItem previousMedia = queue.value.elementAt(index - 1);
          currentMediaItem = previousMedia;
          setItemInMediaPlayers();
        }
        //TODO Agregar stopwatch CASETE
        player.seekToPrevious();
      } else {
        AppUtilities.logger.d('Reset currentitem');
        player.seek(Duration.zero);
      }
    } else {
      player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.children.length) return;
    player.seek(Duration.zero,
      index: player.shuffleModeEnabled ? player.shuffleIndices![index] : index,
    );
  }

  @override
  Future<void> play() async {
    AppUtilities.logger.d('NeomAudioHandler Dispose and Play');

    try {
      if (currentMediaItem != null) {
        // if (player.audioSource == null) {
        //   AudioSource? audioSource = await _itemToSource(currentMediaItem!);
        //   if (audioSource != null) await player.setAudioSource(audioSource);
        // }

        if (player.audioSource == null || currentMediaItem?.id != mediaItem.value?.id) {
          AudioSource? audioSource = await _itemToSource(currentMediaItem!);
          if (audioSource != null) await player.setAudioSource(audioSource);
        }

        setItemInMediaPlayers();
        Get.find<MediaPlayerController>().setIsLoadingAudio(false);
        await player.play();
        neomStopwatch.start(mediaItem.value?.id ?? '');
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }


  @override
  Future<void> pause() async {
    AppUtilities.logger.d('Pause');

    await player.pause();
    neomStopwatch.stop();
    addLastQueue(queue.value);

    await playerHiveController.setLastIndexAndPos(player.currentIndex, player.position.inSeconds);
  }

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    AppUtilities.logger.d('Stopping player');
    neomStopwatch.stop();
    await player.stop();
    await playbackState.firstWhere((state) =>
    state.processingState == AudioProcessingState.idle,);

    AppUtilities.logger.t(
        'Caching last index ${player.currentIndex} and position ${player
            .position.inSeconds}');

    await addLastQueue(queue.value);
    AppHiveController().setLastIndexPos(lastIndex: player.currentIndex, lastPos: player.position.inSeconds);
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    AppUtilities.logger.d('CustomAction $name called');

    switch (name) {
      case 'skipToMediaItem':
        await skipToMediaItem(extras!['id'].toString(),
            index: extras['index'] != null ? int.parse(
                extras['index'].toString()) : 0);
      case 'fastForward':
        try {
          const stepInterval = Duration(seconds: 10);
          Duration newPosition = player.position + stepInterval;
          if (newPosition < Duration.zero) newPosition = Duration.zero;
          if (newPosition > player.duration!) newPosition = player.duration!;
          await player.seek(newPosition);
        } catch (e) {
          AppUtilities.logger.e('Error in fastForward ${e.toString()}');
        }
      case 'rewind':
        try {
          const stepInterval = Duration(
              seconds: AudioPlayerConstants.rewindSeconds);
          Duration newPosition = player.position - stepInterval;
          if (newPosition < Duration.zero) newPosition = Duration.zero;
          if (newPosition > player.duration!) newPosition = player.duration!;
          await player.seek(newPosition);
        } catch (e) {
          AppUtilities.logger.e('Error in rewind ${e.toString()}');
        }
      case 'refreshLink':
        if (extras?['newData'] != null) {
          await refreshLink(extras!['newData'] as Map);
        }
      case 'sleepTimer':
        _sleepTimer?.cancel();
        if (extras?['time'] != null && extras!['time'].runtimeType == int &&
            extras['time'] > 0 as bool) {
          _sleepTimer = Timer(Duration(minutes: extras['time'] as int), () async {
            await stop();
          });
        }
      case 'sleepCounter':
        if (extras?['count'] != null &&
            extras!['count'].runtimeType == int &&
            extras['count'] > 0 as bool) {
          count = extras['count'] as int;
        }
      default:
        break;
    }

    return super.customAction(name, extras);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    if (enabled) {
      await player.shuffle();
    }
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
    await player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    await player.setLoopMode(LoopMode.values[repeatMode.index]);
  }

  @override
  Future<void> setSpeed(double speed) async {
    this.speed.add(speed);
    await player.setSpeed(speed);
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume.add(volume);
    await player.setVolume(volume);
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch (button) {
      case MediaButton.media:
        _handleMediaActionPressed();
      case MediaButton.next:
        await skipToNext();
      case MediaButton.previous:
        await skipToPrevious();
    }
  }

  late rx.BehaviorSubject<int> _tappedMediaActionNumber;
  Timer? _timer;

  void _handleMediaActionPressed() async {
    if (_timer == null) {
      _tappedMediaActionNumber = rx.BehaviorSubject.seeded(1);
      _timer = Timer(const Duration(milliseconds: 800), () {
        final tappedNumber = _tappedMediaActionNumber.value;
        switch (tappedNumber) {
          case 1:
            if (playbackState.value.playing) {
              pause();
            } else {
              play();
            }
          case 2:
            skipToNext();
          case 3:
            skipToPrevious();
          default:
            break;
        }
        _tappedMediaActionNumber.close();
        _timer!.cancel();
        _timer = null;
      });
    } else {
      final current = _tappedMediaActionNumber.value;
      _tappedMediaActionNumber.add(current + 1);
    }
  }

  void setItemInMediaPlayers() {
    //TODO Agregar stopwatch CASETE
    AppUtilities.logger.w('StopWatch LOG');

    if (currentMediaItem != null) {
      if (Get.isRegistered<MiniPlayerController>()) {
        Get.find<MiniPlayerController>().setMediaItem(currentMediaItem!);
      } else {
        Get.put(MiniPlayerController()).setMediaItem(currentMediaItem!);
      }

      if (Get.isRegistered<MediaPlayerController>()) {
        Get.find<MediaPlayerController>().setMediaItem(item: currentMediaItem!);
      } else {
        Get.put(MediaPlayerController()).setMediaItem(item: currentMediaItem!);
      }
    }

    AudioPlayerStats.addRecentlyPlayed(MediaItemMapper.toAppMediaItem(currentMediaItem!));
  }

  Future<void> trackCaseteSession() async {
    if(!isCaseteElegible || currentDuration < AudioPlayerConstants.minDuration) {
      neomStopwatch.stop();
      AppUtilities.logger.w("The audio was opened less than ${AudioPlayerConstants.minDuration}s to track casete.");
      return;
    }

    String itemName =  mediaItem.value?.title ?? '';
    String orderId = '';

    if(isAuthor) {
    orderId = await WooOrdersApi.createSessionOrder(userController.user, itemName, currentDuration);
    }

    CaseteSession caseteSession = CaseteSession(
    id: orderId,
    createdTime: DateTime.now().millisecondsSinceEpoch,
    ownerId: currentMediaItem?.artist ?? '',
    itemId: currentMediaItem?.id ??'',
    itemName: itemName,
    readerId: userController.user.email,
    totalDuration: caseteSessionDuration,
    totalPages: casetePerSession,
    casete: averageCasete,
    );


    await CaseteSessionFirestore().insert(caseteSession, isAuthor: isAuthor);

    AppUtilities.logger.i("Number of pages read in session: $averageCasete for $itemName");


  }

  Future<void> startFreeTrialTimer() async {
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) async {

      int dailyTrialUsage = await CaseteTrialUsageManager().getDailyTrialUsage();

      if(dailyTrialUsage >= AudioPlayerConstants.maxDurationTrial) {
        allowFreeTrial = false;
      } else if(player.playing) {
        CaseteTrialUsageManager().increaseDailyTrialUsage(10);
      }

    });
    AppUtilities.logger.d('Time is active: ${_timer?.isActive}');
  }

}
