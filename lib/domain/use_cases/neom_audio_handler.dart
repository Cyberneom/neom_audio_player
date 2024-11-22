import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:rxdart/rxdart.dart' as rx;

import '../../data/implementations/app_hive_controller.dart';
import '../../data/implementations/playlist_hive_controller.dart';
import '../../ui/player/media_player_controller.dart';
import '../../ui/player/miniplayer_controller.dart';
import '../../utils/audio_player_stats.dart';
import '../../utils/audio_player_utilities.dart';
import '../../utils/constants/app_hive_constants.dart';
import '../../utils/constants/audio_player_constants.dart';
import '../../utils/helpers/media_item_mapper.dart';
import '../../utils/neom_audio_utilities.dart';
import '../entities/queue_state.dart';
import 'isolate_service.dart';
import 'neom_audio_service.dart';

class NeomAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler implements NeomAudioService {

  int? count;
  Timer? _sleepTimer;

  AudioPlayer player = AudioPlayer();
  MediaItem? currentMediaItem;

  final _playlist = ConcatenatingAudioSource(children: []);

  String connectionType = AudioPlayerConstants.wifi;

  Box? downloadsBox = AppHiveController().getBox(AppHiveConstants.downloads);
  final List<String> refreshLinks = [];
  bool jobRunning = false;

  String preferredQuality = '';
  String preferredWifiQuality = '';
  String preferredMobileQuality = '';
  List<int> preferredCompactNotificationButtons = [1, 2, 3];
  bool resetOnSkip = true;
  bool cacheSong = true;
  bool recommend = true;
  bool loadStart = true;
  bool useDownload = true;
  bool stopForegroundService = true;
  
  final rx.BehaviorSubject<List<MediaItem>> _recentSubject = rx.BehaviorSubject.seeded(<MediaItem>[]);

  @override
  final rx.BehaviorSubject<double> volume = rx.BehaviorSubject.seeded(1.0);
  @override
  final rx.BehaviorSubject<double> speed = rx.BehaviorSubject.seeded(1.0);
  final _mediaItemExpando = Expando<MediaItem>();

  Stream<List<IndexedAudioSource>> get _effectiveSequence => rx.Rx.combineLatest3<List<IndexedAudioSource>?,
              List<int>?, bool, List<IndexedAudioSource>?>(player.sequenceStream, player.shuffleIndicesStream,
      player.shuffleModeEnabledStream, (sequence, shuffleIndices, shuffleModeEnabled) {
        if (sequence == null) return [];
        if (!shuffleModeEnabled) return sequence;
        if (shuffleIndices == null) return null;
        if (shuffleIndices.length != sequence.length) return null;
        return shuffleIndices.map((i) => sequence[i]).toList();
      }).whereType<List<IndexedAudioSource>>();

  @override
  Stream<QueueState> get queueState => rx.Rx.combineLatest3<List<MediaItem>, PlaybackState, List<int>,
      QueueState>(queue, playbackState, player.shuffleIndicesStream.whereType<List<int>>(),
        (queue, playbackState, shuffleIndices) => QueueState(
          queue, playbackState.queueIndex,
          playbackState.shuffleMode == AudioServiceShuffleMode.all
              ? shuffleIndices : null,
          playbackState.repeatMode,
        ),
      ).where((state) => state.shuffleIndices == null ||
          state.queue.length == state.shuffleIndices!.length,
      );

  NeomAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    AppUtilities.logger.t('Starting NeomAudioHandler');

    try {
      preferredCompactNotificationButtons = AppHiveController().preferredCompactNotificationButtons;
      preferredMobileQuality = AppHiveController().preferredMobileQuality;
      preferredWifiQuality = AppHiveController().preferredWifiQuality;
      preferredQuality = connectionType == AudioPlayerConstants.wifi ? preferredWifiQuality : preferredMobileQuality;
      cacheSong = AppHiveController().cacheSong;
      useDownload = AppHiveController().useDownload;

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await startService();
      await startBackgroundProcessing();

      speed.debounceTime(const Duration(milliseconds: 250)).listen((speed) {
        playbackState.add(playbackState.value.copyWith(speed: speed));
      });

      mediaItem.whereType<MediaItem>().listen((item) {
        if (count != null) {
          count = count! - 1;
          if (count! <= 0) {
            count = null;
            stop();
          }
        }

        if (item.artUri.toString().startsWith(AppConstants.http)) {
          AudioPlayerStats.addRecentlyPlayed(MediaItemMapper.fromMediaItem(item));
          _recentSubject.add([item]);
        }
      });

      rx.Rx.combineLatest4<int?, List<MediaItem>, bool, List<int>?, MediaItem?>(
          player.currentIndexStream, queue, player.shuffleModeEnabledStream, player.shuffleIndicesStream,
          (index, queue, shuffleModeEnabled, shuffleIndices) {
        final queueIndex = NeomAudioUtilities.getQueueIndex(player, index);
        return (queueIndex != null && queueIndex < queue.length)
            ? queue[queueIndex] : null;
      }).whereType<MediaItem>().distinct().listen(mediaItem.add);

      player.playbackEventStream.listen(_broadcastState);
      player.shuffleModeEnabledStream.listen((enabled) => _broadcastState(player.playbackEvent));
      player.loopModeStream.listen((event) => _broadcastState(player.playbackEvent));
      player.processingStateStream.listen((state) {
        AppUtilities.logger.i('Audio Player - Processing Stream: ${state.name}');
        switch(state) {
          case ProcessingState.loading:
            break;
          case ProcessingState.ready:
            break;
          case ProcessingState.buffering:
            break;
          case ProcessingState.completed:
            stop();
            player.seek(Duration.zero, index: 0);
          case ProcessingState.idle:
            break;
        }
      });

      // Broadcast the current queue.
      _effectiveSequence.map((sequence) => sequence.map((source) => _mediaItemExpando[source]!)
          .toList(),).pipe(queue);

      if (loadStart) {
        final List lastQueueList = AppHiveController().lastQueueList;
        if (lastQueueList.isNotEmpty) {
          final List<MediaItem> lastQueue = lastQueueList.map((e) => MediaItemMapper.fromJSON(e as Map)).toList();
          if (lastQueue.isNotEmpty) {
            try {
              final int lastIndex = AppHiveController().lastIndex;
              final int lastPos = AppHiveController().lastPos;

              await _playlist.addAll(await _itemsToSources(lastQueue));
              await player.setAudioSource(_playlist,);
              if (lastIndex != 0 || lastPos > 0) {
                await player.seek(Duration(seconds: lastPos), index: lastIndex);
              }
            } catch (e) {
              AppUtilities.logger.e('Error while setting last audiosource ${e.toString()}');
            }
          }
        }
      }
    } catch (e) {
      AppUtilities.logger.e('Error while loading last queue $e');
    }

    player.setAudioSource(_playlist, preload: false);
    if (!jobRunning) refreshJob();

  }

  /// Broadcasts the current state to all clients.
  void _broadcastState(PlaybackEvent event) {

    try {
      final playing = player.playing;
      bool liked = false;
      if (mediaItem.value != null) {
        liked = PlaylistHiveController().checkPlaylist(AppHiveConstants.favoriteSongs, mediaItem.value!.id);
      }
      final queueIndex = NeomAudioUtilities.getQueueIndex(player, event.currentIndex);

      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            if (liked) MediaControl.rewind else MediaControl.fastForward,
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          systemActions: NeomAudioUtilities.mediaActions,
          androidCompactActionIndices: preferredCompactNotificationButtons,
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
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  void refreshJob() {
    jobRunning = true;
    while (refreshLinks.isNotEmpty) {
      isolateSendPort?.send(refreshLinks.removeAt(0));
    }
    jobRunning = false;
  }

  Future<void> refreshLink(Map newData) async {
    AppUtilities.logger.i('Audio Player refreshLink | received new link for ${newData['title']}');
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
        if (downloadsBox != null && downloadsBox!.containsKey(mediaItem.id) && useDownload) {
          audioSource = AudioSource.uri(
            Uri.file((downloadsBox!.get(mediaItem.id) as Map)['path'].toString(),),
            tag: mediaItem.id,
          );
        } else {
          String audioUrl = '';
          if(mediaItem.extras!['url'] != null && mediaItem.extras!['url'].toString().isNotEmpty) {
            audioUrl = mediaItem.extras!['url'].toString();
            if(preferredQuality.isNotEmpty && audioUrl.contains('_96.')) {
              audioUrl = audioUrl.replaceAll('_96.', "_${preferredQuality.replaceAll(' kbps', '')}.");
            }
          }

          if (cacheSong && AudioPlayerUtilities.isInternal(audioUrl)) {
            audioSource = LockCachingAudioSource(Uri.parse(audioUrl));
          } else {
            audioSource = AudioSource.uri(Uri.parse(audioUrl));
          }
        }
      }
      _mediaItemExpando[audioSource] = mediaItem;
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    return audioSource;
  }

  Future<List<AudioSource>> _itemsToSources(List<MediaItem> mediaItems) async {
    final List<AudioSource> sources = [];

    try {
      for (final element in mediaItems) {
        final AudioSource? src = await _itemToSource(element);
        if(src != null) sources.add(src);
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }
    return sources;
  }

  @override
  Future<void> onTaskRemoved() async {
    final bool stopForegroundService = AppHiveController().stopForegroundService;
    if (stopForegroundService) {
      await stop();
    }
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
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
  rx.ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
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

  Future<void> startService() async {
    AppUtilities.logger.t('Starting AudioPlayer Service');
    if(player.playing) player.dispose();
    player = AudioPlayer();
  }

  Future<void> addLastQueue(List<MediaItem> queue) async {
    if (queue.isNotEmpty) {
      AppUtilities.logger.d('Saving last queue');
      final lastQueue = queue.map((item) {
        return MediaItemMapper.toJSON(item);
      }).toList();
      Hive.box(AppHiveConstants.cache).put(AppHiveConstants.lastQueue, lastQueue);
    }
  }

  Future<void> skipToMediaItem(String id, {int index = 0}) async {
    AppUtilities.logger.t('skipToMediaItem $id');

    if(queue.value.indexWhere((item) => item.id == id) >= 0) {
      index = queue.value.indexWhere((item) => item.id == id);
      AppUtilities.logger.t('SkipToMediaItem: mediaItem found in queue with Index $index');
    }

    player.seek(Duration.zero, index: player.shuffleModeEnabled && index != 0 ? player.shuffleIndices![index] : index,
    );
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    AppUtilities.logger.d('addQueueItem');
    final res = await _itemToSource(mediaItem);
    if (res  != null) {
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
    final res = await _itemToSource(mediaItem);
    if (res != null) {
      await _playlist.insert(index, res);
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    AppUtilities.logger.d("Updating Music Player Queue with ${newQueue.length} items");
    try {
      await _playlist.clear();
      final List<AudioSource> sources = await _itemsToSources(newQueue);
      await _playlist.addAll(sources);
    } catch(e) {
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
    AppUtilities.logger.d('removeQueueItemAt from index: $currentIndex to $newIndex');
    await _playlist.move(currentIndex, newIndex);
  }

  @override
  Future<void> skipToNext() async {
    AppUtilities.logger.d('skipToNext');

    final index = queue.value.indexWhere((item) => item.id == currentMediaItem!.id);
    if(queue.value.length >= index+1) {
      MediaItem nextMedia = queue.value.elementAt(index+1);
      currentMediaItem = nextMedia;

      if(Get.isRegistered<MiniPlayerController>()) {
        Get.find<MiniPlayerController>().setMediaItem(nextMedia);
      } else {
        Get.put(MiniPlayerController()).setMediaItem(nextMedia);
      }

      if(Get.isRegistered<MediaPlayerController>()) {
        Get.find<MediaPlayerController>().setMediaItem(nextMedia);
      } else {
        Get.put(MediaPlayerController()).setMediaItem(nextMedia);
      }

    }

    player.seekToNext();
  }

  /// This is called when the user presses the "like" button.
  @override
  Future<void> fastForward() async {
    AppUtilities.logger.d('');
    if (mediaItem.value?.id != null) {
      PlaylistHiveController().addItemToPlaylist(AppHiveConstants.favoriteSongs, mediaItem.value!);
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

  @override
  Future<void> skipToPrevious() async {
    AppUtilities.logger.d('skipToPrevious');

    resetOnSkip = Hive.box(AppHiveConstants.settings).get(AppHiveConstants.resetOnSkip, defaultValue: true) as bool;
    if (resetOnSkip) {
      if ((player.position.inSeconds) <= 2) {
        AppUtilities.logger.d('skipToPrevious');

        final index = queue.value.indexWhere((item) => item.id == currentMediaItem!.id);
        if(queue.value.isNotEmpty && (index-1 >= 0)) {
          MediaItem previousMedia = queue.value.elementAt(index-1);
          currentMediaItem = previousMedia;

          if(Get.isRegistered<MiniPlayerController>()) {
            Get.find<MiniPlayerController>().setMediaItem(previousMedia);
          } else {
            Get.put(MiniPlayerController()).setMediaItem(previousMedia);
          }

          if(Get.isRegistered<MediaPlayerController>()) {
            Get.find<MediaPlayerController>().setMediaItem(previousMedia);
          } else {
            Get.put(MediaPlayerController()).setMediaItem(previousMedia);
          }

        }

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
    player.seek(Duration.zero, index: player.shuffleModeEnabled ? player.shuffleIndices![index] : index,
    );
  }

  @override
  Future<void> play() async {
    AppUtilities.logger.d('NeomAudioHandler Dispose and Play');

    try {
      if(currentMediaItem != null) {
        if(Get.isRegistered<MiniPlayerController>()) {
          Get.find<MiniPlayerController>().setMediaItem(currentMediaItem!);
        } else {
          Get.put(MiniPlayerController()).setMediaItem(currentMediaItem!);
        }

        if(Get.isRegistered<MediaPlayerController>()) {
          Get.find<MediaPlayerController>().setMediaItem(currentMediaItem!);
        } else {
          Get.put(MediaPlayerController()).setMediaItem(currentMediaItem!);
        }
      }

      await player.play();
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }
  }


  @override
  Future<void> pause() async {
    await player.pause();
    addLastQueue(queue.value);
    Hive.box(AppHiveConstants.cache).put(AppHiveConstants.lastIndex, player.currentIndex);
    Hive.box(AppHiveConstants.cache).put(AppHiveConstants.lastPos, player.position.inSeconds);
  }

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    AppUtilities.logger.d('Stopping player');
    await player.stop();
    await playbackState.firstWhere((state) => state.processingState == AudioProcessingState.idle,);

    AppUtilities.logger.t('Caching last index ${player.currentIndex} and position ${player.position.inSeconds}');
    await Hive.box(AppHiveConstants.cache).put(AppHiveConstants.lastIndex, player.currentIndex);
    await Hive.box(AppHiveConstants.cache).put(AppHiveConstants.lastPos, player.position.inSeconds);
    await addLastQueue(queue.value);

  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    AppUtilities.logger.d('CustomAction $name called');

    switch(name) {
      case 'skipToMediaItem':
        await skipToMediaItem(extras!['id'].toString(), index: extras['index'] != null ? int.parse(extras['index'].toString()) : 0);
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
          const stepInterval = Duration(seconds: AudioPlayerConstants.rewindSeconds);
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
          _sleepTimer = Timer(Duration(minutes: extras['time'] as int), () {
            stop();
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

    void _handleMediaActionPressed() {
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

}
