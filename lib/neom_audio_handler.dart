import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sint/sint.dart';
import 'package:just_audio/just_audio.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/data/implementations/neom_stopwatch.dart';
import 'package:neom_core/domain/model/casete/casete_session.dart';
import 'package:neom_core/domain/repository/casete_session_repository.dart';
import 'package:neom_core/domain/use_cases/audio_handler_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';
import 'package:neom_core/utils/enums/user_role.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'data/implementations/casete_hive_controller.dart';
import 'data/implementations/player_hive_controller.dart';
import 'data/implementations/playlist_hive_controller.dart';
import 'domain/models/queue_state.dart';
import 'ui/player/audio_player_controller.dart';
import 'ui/player/miniplayer_controller.dart';
import 'utils/audio_player_stats.dart';
import 'utils/constants/audio_player_constants.dart';
import 'utils/mappers/media_item_mapper.dart';
import 'utils/neom_audio_utilities.dart';

class NeomAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler implements AudioHandlerService {

  int? count;
  Timer? _sleepTimer;

  AudioPlayer player = AudioPlayer();
  MediaItem? currentMediaItem;

  String connectionType = AppTranslationConstants.wifi;

  final List<String> refreshLinks = [];
  bool jobRunning = false;

  PlayerHiveController playerHiveController =  PlayerHiveController();

  bool stopForegroundService = true;

  final rx.BehaviorSubject<List<MediaItem>> _recentSubject = rx.BehaviorSubject
      .seeded(<MediaItem>[]);

  final userServiceImpl = Sint.find<UserService>();
  final neomStopwatch =  NeomStopwatch();

  int caseteSessionDuration = 0; //Seconds per session
  int casetePerSession = 0; //Pages per session
  int averageCasete = 0;
  bool isCaseteElegible = true;
  bool isFree = false;
  bool allowFullAccess = true;
  bool allowFreeTrial = true;
  bool _stoppedByVideo = false;

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
    AppConfig.logger.t('Starting NeomAudioHandler');

    try {
      startService();
      allowFullAccess = userServiceImpl.subscriptionLevel.value > SubscriptionLevel.freemium.value;
      if(!isFree && !allowFullAccess) startFreeTrialTimer();

    } catch (e) {
      AppConfig.logger.e('Error while loading last queue $e');
    }

  }

  Future<void> setListeners() async {
    AppConfig.logger.d('Setting AudioHandler Listeners');

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

      neomStopwatch.start(ref: item.id);

      if (item.artUri.toString().startsWith(CoreConstants.http)) {
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
      AppConfig.logger.d('Audio Player - Processing Stream: ${state.name}');
      switch (state) {
        case ProcessingState.loading:
          break;
        case ProcessingState.ready:
          if(neomStopwatch.currentReference != (mediaItem.value?.id ?? '')) {
            neomStopwatch.start(ref: mediaItem.value?.id ?? '');
          } else {
            neomStopwatch.resume();
          }
          break;
        case ProcessingState.buffering:
          neomStopwatch.stop();
          break;
        case ProcessingState.completed:
          await stop();
          player.seek(Duration.zero, index: 0);
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
    AppConfig.logger.d('Loading last queue from Hive');
    
    if (playerHiveController.loadStart) {
      await Future.delayed(const Duration(milliseconds: 500)); // Agrega un breve delay para dar tiempo a otros procesos
      final List lastQueueList = playerHiveController.lastQueueList;
      if (lastQueueList.isNotEmpty) {
        final List<MediaItem> lastQueue = lastQueueList.map((e) =>
            MediaItemMapper.fromJSON(e as Map)).toList();

        if (lastQueue.isNotEmpty) {
          try {
            List<AudioSource> sources = await _itemsToSources(lastQueue);
            await player.setAudioSources(sources);
            await gotoLastIndexAndPosition();
          } catch (e) {
            AppConfig.logger.e('Error while setting last audiosource ${e.toString()}');
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
      AppConfig.logger.e(e.toString());
    }
  }

  Future<void> refreshLink(Map newData) async {
    AppConfig.logger.i(
        'Audio Player refreshLink | received new link for ${newData['title']}');
    final MediaItem newItem = MediaItemMapper.fromJSON(newData);

    AppConfig.logger.i('player | inserting refreshed item');

    addQueueItem(newItem);
  }

  Future<AudioSource?> _itemToSource(MediaItem mediaItem) async {

    AudioSource? audioSource;
    AppConfig.logger.d("Moving mediaItem ${mediaItem.title} to audioSource for Music Player ");
    try {


      if (mediaItem.artUri.toString().startsWith('file:')) {
        audioSource = AudioSource.uri(Uri.file(mediaItem.extras!['url'].toString()));
      } else {
        if(playerHiveController.useDownload) {
          AppConfig.logger.d("Looking for files from downloads");
          final downloadsBox = await AppHiveController().getBox(AppHiveBox.downloads.name);
          if(downloadsBox.containsKey(mediaItem.id)) {
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

          if (playerHiveController.cacheSong && CoreUtilities.isInternal(audioUrl)) {
            audioSource = LockCachingAudioSource(Uri.parse(audioUrl));
          } else {
            audioSource = AudioSource.uri(Uri.parse(audioUrl));
          }
        }
      }

      if(audioSource != null) _mediaItemExpando[audioSource] = mediaItem;
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
      AppConfig.logger.e(e.toString());
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

    AppConfig.logger.d('Starting AudioPlayer Service');
    // if (player.playing) player.dispose();
    player = AudioPlayer();
    await player.setAudioSources([]);
    await loadLastQueue();
    await setListeners();
  }

  Future<void> addLastQueue(List<MediaItem> queue) async {

    if (queue.isNotEmpty) {
      AppConfig.logger.d('Saving last queue');
      final lastQueue = queue.map((item) {
        return MediaItemMapper.toJSON(item);
      }).toList();
      playerHiveController.setLastQueue(lastQueue);
    }
  }

  Future<void> skipToMediaItem(String id, {int index = 0}) async {
    AppConfig.logger.t('skipToMediaItem $id');

    if (queue.value.indexWhere((item) => item.id == id) >= 0) {
      index = queue.value.indexWhere((item) => item.id == id);
      AppConfig.logger.t(
          'SkipToMediaItem: mediaItem found in queue with Index $index');
    }

    player.seek(Duration.zero,
      index: player.shuffleModeEnabled && index != 0 ? player
          .shuffleIndices[index] : index,
    );

  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    AppConfig.logger.d('addQueueItem');
    AudioSource? res = await _itemToSource(mediaItem);
    if (res != null) {
      final currentSources = List<AudioSource>.from(player.audioSource?.sequence ?? []);
      currentSources.add(res);
      await player.setAudioSources(currentSources);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    AppConfig.logger.d('addQueueItems');
    final newSources = await _itemsToSources(mediaItems);
    final currentSources = List<AudioSource>.from(player.audioSource?.sequence ?? []);
    currentSources.addAll(newSources);
    await player.setAudioSources(currentSources);
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    AppConfig.logger.d('insertQueueItem');
    AudioSource? res = await _itemToSource(mediaItem);
    if (res != null) {
      final currentSources = List<AudioSource>.from(player.audioSource?.sequence ?? []);
      if (index <= currentSources.length) {
        currentSources.insert(index, res);
        await player.setAudioSources(currentSources);
      }
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    AppConfig.logger.d(
        "Updating Music Player Queue with ${queue.length} items");
    try {
      final List<AudioSource> sources = await _itemsToSources(queue);
      await player.setAudioSources(sources);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    AppConfig.logger.d('updateMediaItem');
    final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    _mediaItemExpando[player.sequence[index]] = mediaItem;
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    AppConfig.logger.d('removeQueueItem');
    final index = queue.value.indexOf(mediaItem);
    if (index != -1) await removeQueueItemAt(index);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    AppConfig.logger.d('removeQueueItemAt at index: $index');
    final currentSources = List<AudioSource>.from(player.audioSource?.sequence ?? []);
    if (index < currentSources.length) {
      currentSources.removeAt(index);
      await player.setAudioSources(currentSources);
    }
  }

  @override
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    AppConfig.logger.d('removeQueueItemAt from index: $currentIndex to $newIndex');
    final currentSources = List<AudioSource>.from(player.audioSource?.sequence ?? []);
    if (currentIndex < currentSources.length && newIndex < currentSources.length) {
      final item = currentSources.removeAt(currentIndex);
      currentSources.insert(newIndex, item);
      await player.setAudioSources(currentSources);
    }
  }

  @override
  Future<void> skipToNext() async {
    AppConfig.logger.d('skipToNext');

    await trackCaseteSession();

    int index = queue.value.indexWhere((item) => item.id == (currentMediaItem?.id ?? ''));
    if(queue.value.length >= index + 1) {
      MediaItem nextMedia = queue.value.elementAt(index + 1);
      neomStopwatch.start(ref: nextMedia.id);
      currentMediaItem = nextMedia;
      setItemInMediaPlayers();
      player.seekToNext();
    }
  }

  /// This is called when the user presses the "like" button.
  @override
  Future<void> fastForward() async {
    AppConfig.logger.d('');
    if (mediaItem.value?.id != null) {
      PlaylistHiveController().addItemToPlaylist(
          AppHiveBox.favoriteItems.name, mediaItem.value!);
      _broadcastState(player.playbackEvent);
    }
  }

  @override
  Future<void> rewind() async {
    AppConfig.logger.d('rewind');
    if (mediaItem.value?.id != null) {
      PlaylistHiveController().removeLiked(mediaItem.value!.id);
      _broadcastState(player.playbackEvent);
    }
  }

  int currentDuration = 0;
  @override
  Future<void> skipToPrevious() async {
    AppConfig.logger.d('skipToPrevious');

    await trackCaseteSession();

    if(playerHiveController.resetOnSkip) {
      if ((player.position.inSeconds) <= 2) {
        AppConfig.logger.d('skipToPrevious');

        final index = queue.value.indexWhere((item) =>
        item.id == currentMediaItem!.id);
        if (queue.value.isNotEmpty && (index - 1 >= 0)) {
          MediaItem previousMedia = queue.value.elementAt(index - 1);
          neomStopwatch.start(ref: previousMedia.id);
          currentMediaItem = previousMedia;
          setItemInMediaPlayers();
        }
        //TODO Agregar stopwatch CASETE
        player.seekToPrevious();
      } else {
        AppConfig.logger.d('Reset currentitem');
        player.seek(Duration.zero);
      }
    } else {
      player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final playlistLength = player.audioSource?.sequence.length ?? 0;
    if (index < 0 || index >= playlistLength) return;
    player.seek(Duration.zero,
      index: player.shuffleModeEnabled ? player.shuffleIndices[index] : index,
    );
  }

  @override
  Future<void> play() async {
    AppConfig.logger.d('NeomAudioHandler Dispose and Play');

    try {

      if(!allowFullAccess && !allowFreeTrial && AppConfig.instance.isGuestMode) {
        if(Sint.context != null) {
          AuthGuard.showGuestModal(Sint.context!);
        }
        return;
      }

      if(currentMediaItem != null) {
        if (player.audioSource == null || currentMediaItem!.id != mediaItem.value?.id) {
          AudioSource? audioSource = await _itemToSource(currentMediaItem!);
          if(audioSource != null) await player.setAudioSource(audioSource);
        }

        setItemInMediaPlayers();
        Sint.find<AudioPlayerController>().setIsLoadingAudio(false);
        neomStopwatch.start(ref: currentMediaItem!.id);
        await player.play();
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }


  @override
  Future<void> pause() async {
    AppConfig.logger.d('Pause');
    await player.pause();
    await trackCaseteSession();
    if(currentMediaItem != null) {
      neomStopwatch.pause(ref: currentMediaItem!.id);
    }

    addLastQueue(queue.value);
    await playerHiveController.setLastIndexAndPos(player.currentIndex, player.position.inSeconds);
  }

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    AppConfig.logger.d('Stopping player');
    trackCaseteSession();
    await player.stop();
    await playbackState.firstWhere((state) =>
    state.processingState == AudioProcessingState.idle,);

    AppConfig.logger.t(
        'Caching last index ${player.currentIndex} and position ${player
            .position.inSeconds}');

    await addLastQueue(queue.value);
    AppHiveController().setLastIndexPos(lastIndex: player.currentIndex, lastPos: player.position.inSeconds);
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    AppConfig.logger.d('CustomAction $name called');

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
          AppConfig.logger.e('Error in fastForward ${e.toString()}');
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
          AppConfig.logger.e('Error in rewind ${e.toString()}');
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

  Future<void> setItemInMediaPlayers() async {
    //TODO Agregar stopwatch CASETE
    AppConfig.logger.w('StopWatch started for item ${currentMediaItem?.title}');

    if (currentMediaItem != null) {
      if (Sint.isRegistered<MiniPlayerController>()) {
        await Sint.find<MiniPlayerController>().setMediaItem(currentMediaItem!);
      } else {
        await Sint.put(MiniPlayerController()).setMediaItem(currentMediaItem!);
      }

      if (Sint.isRegistered<AudioPlayerController>()) {
        Sint.find<AudioPlayerController>().setMediaItem(item: currentMediaItem!);
      } else {
        Sint.put(AudioPlayerController()).setMediaItem(item: currentMediaItem!);
      }
    }

    await AudioPlayerStats.addRecentlyPlayed(currentMediaItem!);
  }

  Future<void> trackCaseteSession() async {
    AppConfig.logger.t("CASETE ALG: Tracking casete session.");

    // 1. Validación de Elegibilidad
    String itemId = currentMediaItem?.id ?? mediaItem.value?.id ?? '';
    if (itemId.isEmpty) return;

    bool isOwner = (userServiceImpl.user.email == itemId)
        || (userServiceImpl.user.releaseItemIds?.contains(itemId) ?? false);

    if(isOwner || !isCaseteElegible) {
      AppConfig.logger.w("CASETE ALG: Owner or not eligible. Session not saved.");
      return;
    }

    int secondsListened = neomStopwatch.elapsed();
    AppConfig.logger.d("CASETE ALG: Checking session. Listened: ${secondsListened}s");

    // 1. Validación de Tiempo Mínimo (El "Tiempo Sensato")
    if (secondsListened < AudioPlayerConstants.minCaseteSeconds) {
      AppConfig.logger.w("CASETE ALG: Audio listened less than ${AudioPlayerConstants.minCaseteSeconds}s. Not saved.");
      return;
    }

    neomStopwatch.reset(); // Resetear inmediatamente para evitar doble conteo

    String itemName = currentMediaItem?.title ?? mediaItem.value?.title ?? '';
    String ownerId = currentMediaItem?.extras?['ownerId'] ?? mediaItem.value?.extras?['ownerId'] ?? ''; //

    int createdTime = DateTime.now().millisecondsSinceEpoch;
    String sessionId = '${itemId}_$createdTime';

    // 3. Creación de la Sesión
    CaseteSession caseteSession = CaseteSession(
      id: sessionId,
      createdTime: createdTime,
      itemId: itemId,
      itemName: itemName,
      ownerEmail: ownerId,
      listenerEmail: userServiceImpl.user.email, // Quien escucha
      casete: secondsListened, // VALOR REAL CALCULADO
      subscriptionLevel: userServiceImpl.subscriptionLevel, // Si lo tienes disponible
      isTest: kDebugMode || userServiceImpl.user.userRole != UserRole.subscriber
    );

    try {
      // 4. Guardado en Firestore
      await Sint.find<CaseteSessionRepository>().insert(caseteSession, isOwner: isOwner);
      AppConfig.logger.i("CASETE ALG: Session saved! $secondsListened seconds for $itemName");
    } catch (e) {
      AppConfig.logger.e("CASETE ALG: Error saving session: $e");
    }

  }

  Future<void> startFreeTrialTimer() async {
    _timer = Timer.periodic(
        const Duration(seconds: AudioPlayerConstants.minCaseteSeconds),
            (Timer timer) async {
          int dailyTrialUsage = await CaseteTrialUsageManager().getDailyTrialUsage();

          if(AppConfig.instance.isGuestMode && dailyTrialUsage >= AudioPlayerConstants.guestTrialDuration) {
            allowFreeTrial = false;
            if(player.playing) {
              pause();
              timer.cancel(); // <--- AQUÍ SE DETIENE EL TIMER
              _timer = null;  // Opcional: Limpiamos la referencia global
              if(Sint.context != null) {
                AuthGuard.showGuestModal(Sint.context!);
              }
            }
          } else if(dailyTrialUsage >= AudioPlayerConstants.trialDuration) {
            allowFreeTrial = false;
            pause();
            timer.cancel(); // <--- AQUÍ SE DETIENE EL TIMER
            _timer = null;  // Opcional: Limpiamos la referencia global
            AppUtilities.showSnackBar(
              title: AppTranslationConstants.trialEnded.tr,
              message: AppTranslationConstants.trialEndedMessage.tr,
            );
            trackCaseteSession();
          } else if(player.playing) {
            CaseteTrialUsageManager().increaseDailyTrialUsage(AudioPlayerConstants.minCaseteSeconds);
          }
        });
    AppConfig.logger.d('Time is active: ${_timer?.isActive}');
  }

  final RxBool _isPlaying = false.obs;

  @override
  bool get isPlaying => _isPlaying.value = player.playing;

  @override
  bool get stoppedByVideo => _stoppedByVideo;

  @override
  set stoppedByVideo(bool value) {
    _stoppedByVideo = value;
  }



}
