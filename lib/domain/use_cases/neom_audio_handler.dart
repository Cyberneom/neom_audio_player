/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:get/get.dart' as getx;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/implementations/app_hive_controller.dart';
import '../../data/implementations/playlist_hive_controller.dart';
import '../../ui/player/miniplayer_controller.dart';
import '../../utils/constants/app_hive_constants.dart';
import '../../utils/constants/music_player_constants.dart';
import '../../utils/helpers/media_item_mapper.dart';
import '../../utils/music_player_stats.dart';
import '../../utils/neom_audio_utilities.dart';
import '../entities/queue_state.dart';
import 'isolate_service.dart';
import 'neom_audio_service.dart';

class NeomAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler implements NeomAudioService {

  int? count;
  Timer? _sleepTimer;

  AudioPlayer _player = AudioPlayer();
  MediaItem? currentMediaItem;
  final _playlist = ConcatenatingAudioSource(children: []);

  String connectionType = MusicPlayerConstants.wifi;

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

  final BehaviorSubject<List<MediaItem>> _recentSubject = BehaviorSubject.seeded(<MediaItem>[]);

  @override
  final BehaviorSubject<double> volume = BehaviorSubject.seeded(1.0);
  @override
  final BehaviorSubject<double> speed = BehaviorSubject.seeded(1.0);
  final _mediaItemExpando = Expando<MediaItem>();

  Stream<List<IndexedAudioSource>> get _effectiveSequence => Rx.combineLatest3<List<IndexedAudioSource>?,
              List<int>?, bool, List<IndexedAudioSource>?>(_player.sequenceStream, _player.shuffleIndicesStream,
      _player.shuffleModeEnabledStream, (sequence, shuffleIndices, shuffleModeEnabled) {
        if (sequence == null) return [];
        if (!shuffleModeEnabled) return sequence;
        if (shuffleIndices == null) return null;
        if (shuffleIndices.length != sequence.length) return null;
        return shuffleIndices.map((i) => sequence[i]).toList();
      }).whereType<List<IndexedAudioSource>>();

  @override
  Stream<QueueState> get queueState =>
      Rx.combineLatest3<List<MediaItem>, PlaybackState, List<int>, QueueState>(
        queue, playbackState, _player.shuffleIndicesStream.whereType<List<int>>(),
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
    AppUtilities.logger.i('Starting audio service');

    try {

      preferredCompactNotificationButtons = AppHiveController().preferredCompactNotificationButtons;
      preferredMobileQuality = AppHiveController().preferredMobileQuality;
      preferredWifiQuality = AppHiveController().preferredWifiQuality;
      preferredQuality = connectionType == MusicPlayerConstants.wifi ? preferredWifiQuality : preferredMobileQuality;
      cacheSong = AppHiveController().cacheSong;
      useDownload = AppHiveController().useDownload;

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await startService();
      await startBackgroundProcessing();

      speed.debounceTime(const Duration(milliseconds: 250)).listen((speed) {
        playbackState.add(playbackState.value!.copyWith(speed: speed));
      });

      mediaItem.whereType<MediaItem>().listen((item) {
        if (count != null) {
          count = count! - 1;
          if (count! <= 0) {
            count = null;
            stop();
          }
        }

        if (item.artUri.toString().startsWith('http')) {
          MusicPlayerStats.addRecentlyPlayed(MediaItemMapper.fromMediaItem(item));
          _recentSubject.add([item]);

          ///VERIFY IF NEEDED
          // if (recommend && item.extras!['autoplay'] as bool) {
          //   final List<MediaItem> mediaQueue = queue.value!;
          //   final int index = mediaQueue.indexOf(item);
          //   if ((mediaQueue.length - index) < 3) {
          //     AppUtilities.logger.i('Less than 3 songs remaining, this would add more songs');
          //   }
          // }
        }
      });

      Rx.combineLatest4<int?, List<MediaItem>, bool, List<int>?, MediaItem?>(
          _player.currentIndexStream, queue, _player.shuffleModeEnabledStream, _player.shuffleIndicesStream,
          (index, queue, shuffleModeEnabled, shuffleIndices) {
        final queueIndex = NeomAudioUtilities.getQueueIndex(_player, index);
        return (queueIndex != null && queueIndex < queue.length)
            ? queue[queueIndex] : null;
      }).whereType<MediaItem>().distinct().listen(mediaItem.add);

      _player.playbackEventStream.listen(_broadcastState);
      _player.shuffleModeEnabledStream.listen((enabled) => _broadcastState(_player.playbackEvent));
      _player.loopModeStream.listen((event) => _broadcastState(_player.playbackEvent));
      _player.processingStateStream.listen((state) {
        AppUtilities.logger.i('Music Player - Processing Stream: ${state.name}');
        switch(state) {
          case ProcessingState.loading:
            break;
          case ProcessingState.ready:
            break;
          case ProcessingState.buffering:
            break;
          case ProcessingState.completed:
            stop();
            _player.seek(Duration.zero, index: 0);
          case ProcessingState.idle:
            break;
        }
      });

      // Broadcast the current queue.
      _effectiveSequence.map((sequence) => sequence.map((source) => _mediaItemExpando[source]!)
          .toList(),).pipe(queue);
      if (loadStart) {
        final List lastQueueList = AppHiveController().lastQueueList;
        final int lastIndex = AppHiveController().lastIndex;
        final int lastPos = AppHiveController().lastPos;

        if (lastQueueList.isNotEmpty && lastQueueList.first['genre'] != 'YouTube') {
          final List<MediaItem> lastQueue = lastQueueList.map((e) => MediaItemMapper.fromJSON(e as Map)).toList();
          if (lastQueue.isEmpty) {
            await _player.setAudioSource(_playlist, preload: false);
          } else {
            try {
              await _playlist.addAll(await _itemsToSources(lastQueue));
              await _player.setAudioSource(_playlist,);
              if (lastIndex != 0 || lastPos > 0) {
                await _player.seek(Duration(seconds: lastPos), index: lastIndex);
              }
            } catch (e) {
              AppUtilities.logger.e('Error while setting last audiosource ${e.toString()}');
              await _player.setAudioSource(_playlist, preload: false);
            }
          }
        } else {
          await _player.setAudioSource(_playlist, preload: false);
        }
      } else {
        await _player.setAudioSource(_playlist, preload: false);
      }
    } catch (e) {
      AppUtilities.logger.e('Error while loading last queue $e');
      await _player.setAudioSource(_playlist, preload: false);
    }
    if (!jobRunning) {
      refreshJob();
    }
  }

  /// Broadcasts the current state to all clients.
  void _broadcastState(PlaybackEvent event) {

    try {
      final playing = _player.playing;
      bool liked = false;
      if (mediaItem.value != null) {
        liked = PlaylistHiveController().checkPlaylist(AppHiveConstants.favoriteSongs, mediaItem.value!.id);
      }
      final queueIndex = NeomAudioUtilities.getQueueIndex(_player, event.currentIndex);

      playbackState.add(
        playbackState.valueWrapper!.value.copyWith(
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
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
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
    AppUtilities.logger.i('Audio Player | received new link for ${newData['title']}');
    final MediaItem newItem = MediaItemMapper.fromJSON(newData);

    AppUtilities.logger.i('player | inserting refreshed item');
    late AudioSource audioSource;
    if (cacheSong) {
      audioSource = LockCachingAudioSource(
        Uri.parse(newItem.extras!['url'].toString(),),);
    } else {
      audioSource = AudioSource.uri(Uri.parse(newItem.extras!['url'].toString(),),);
    }
    // final index = queue.value.indexWhere((item) => item.id == newItem.id);
    // _mediaItemExpando[audioSource] = newItem;
    // _playlist
    // .removeAt(index)
    // .then((value) =>
    // _playlist.insert(index, audioSource));
    addQueueItem(newItem);
  }

  Future<AudioSource?> _itemToSource(MediaItem mediaItem) async {
    AudioSource? audioSource;

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
          if(mediaItem.extras!['url'] != null
              && mediaItem.extras!['url'].toString().isNotEmpty) {
            audioUrl = mediaItem.extras!['url'].toString();
            audioUrl = audioUrl.replaceAll('_96.', "_${preferredQuality.replaceAll(' kbps', '')}.");
          }

          if (cacheSong) {
            audioSource = LockCachingAudioSource(Uri.parse(audioUrl));
          } else {
            audioSource = AudioSource.uri(Uri.parse(audioUrl));
          }
        }
      }
      if (audioSource != null) {
        _mediaItemExpando[audioSource] = mediaItem;
      }
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
        if(src != null) {
          sources.add(src);
        }
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
        return _recentSubject.value!;
      default:
        return queue.value!;
    }
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
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
    AppUtilities.logger.i('Starting AudioPlayer Service');
    if(_player.playing) _player.dispose();
    _player = AudioPlayer();
  }

  Future<void> addLastQueue(List<MediaItem> queue) async {
    if (queue.isNotEmpty && queue.first.genre != 'YouTube') {
      AppUtilities.logger.i('saving last queue');
      final lastQueue = queue.map((item) {
        return MediaItemMapper.toJSON(item);
      }).toList();
      Hive.box(AppHiveConstants.cache).put('lastQueue', lastQueue);
    }
  }

  Future<void> skipToMediaItem(String id, {int index = 0}) async {
    AppUtilities.logger.t('skipToMediaItem $id');

    if(queue.valueWrapper!.value.indexWhere((item) => item.id == id) >= 0) {
      index = queue.valueWrapper!.value.indexWhere((item) => item.id == id);
      AppUtilities.logger.t('SkipToMediaItem: mediaItem found in queue with Index $index');
    }

    _player.seek(Duration.zero, index: _player.shuffleModeEnabled && index != 0 ? _player.shuffleIndices![index] : index,
    );
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final res = await _itemToSource(mediaItem);
    if (res  != null) {
      await _playlist.add(res);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    await _playlist.addAll(await _itemsToSources(mediaItems));
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    final res = await _itemToSource(mediaItem);
    if (res != null) {
      await _playlist.insert(index, res);
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
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
    final index = queue.value!.indexWhere((item) => item.id == mediaItem.id);
    _mediaItemExpando[_player.sequence![index]] = mediaItem;
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final index = queue.value!.indexOf(mediaItem);
    await _playlist.removeAt(index);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _playlist.removeAt(index);
  }

  @override
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    await _playlist.move(currentIndex, newIndex);
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  /// This is called when the user presses the "like" button.
  @override
  Future<void> fastForward() async {
    if (mediaItem.value?.id != null) {
      PlaylistHiveController().addItemToPlaylist(AppHiveConstants.favoriteSongs, mediaItem.value!);
      _broadcastState(_player.playbackEvent);
    }
  }

  @override
  Future<void> rewind() async {
    if (mediaItem.value?.id != null) {
      PlaylistHiveController().removeLiked(mediaItem.value!.id);
      _broadcastState(_player.playbackEvent);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    resetOnSkip =
        Hive.box(AppHiveConstants.settings).get('resetOnSkip', defaultValue: false) as bool;
    if (resetOnSkip) {
      if ((_player.position.inSeconds) <= 5) {
        _player.seekToPrevious();
      } else {
        _player.seek(Duration.zero);
      }
    } else {
      _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.children.length) return;
    _player.seek(Duration.zero, index: _player.shuffleModeEnabled ? _player.shuffleIndices![index] : index,
    );
  }

  @override
  Future<void> play() async {
    AppUtilities.logger.d('NeomAudioHandler Dispose and Play');
    try {
      _player.play();
      if(currentMediaItem != null) {
        getx.Get.find<MiniPlayerController>().setMediaItem(currentMediaItem!);
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }
  }


  @override
  Future<void> pause() async {
    _player.pause();
    await Hive.box(AppHiveConstants.cache).put('lastIndex', _player.currentIndex);
    await Hive.box(AppHiveConstants.cache).put('lastPos', _player.position.inSeconds);
    await addLastQueue(queue.value!);
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    AppUtilities.logger.d('stopping player');
    await _player.stop();
    await playbackState.firstWhere((state) => state.processingState == AudioProcessingState.idle,);

    AppUtilities.logger.t('Caching last index ${_player.currentIndex} and position ${_player.position.inSeconds}');
    await Hive.box(AppHiveConstants.cache).put('lastIndex', _player.currentIndex);
    await Hive.box(AppHiveConstants.cache).put('lastPos', _player.position.inSeconds);
    await addLastQueue(queue.valueWrapper!.value);

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
          Duration newPosition = _player.position + stepInterval;
          if (newPosition < Duration.zero) newPosition = Duration.zero;
          if (newPosition > _player.duration!) newPosition = _player.duration!;
          await _player.seek(newPosition);
        } catch (e) {
          AppUtilities.logger.e('Error in fastForward ${e.toString()}');
        }
      case 'rewind':
        try {
          final stepInterval = Duration(seconds: MusicPlayerConstants.rewindSeconds);
          Duration newPosition = _player.position - stepInterval;
          if (newPosition < Duration.zero) newPosition = Duration.zero;
          if (newPosition > _player.duration!) newPosition = _player.duration!;
          await _player.seek(newPosition);
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
    Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
      final enabled = mode == AudioServiceShuffleMode.all;
      if (enabled) {
        await _player.shuffle();
      }
      playbackState.add(playbackState.value!.copyWith(shuffleMode: mode));
      await _player.setShuffleModeEnabled(enabled);
    }

    @override
    Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
      playbackState.add(playbackState.value!.copyWith(repeatMode: repeatMode));
      await _player.setLoopMode(LoopMode.values[repeatMode.index]);
    }

    @override
    Future<void> setSpeed(double speed) async {
      this.speed.add(speed);
      await _player.setSpeed(speed);
    }

    @override
    Future<void> setVolume(double volume) async {
      this.volume.add(volume);
      await _player.setVolume(volume);
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

    late BehaviorSubject<int> _tappedMediaActionNumber;
    Timer? _timer;

    void _handleMediaActionPressed() {
      if (_timer == null) {
        _tappedMediaActionNumber = BehaviorSubject.seeded(1);
        _timer = Timer(const Duration(milliseconds: 800), () {
          final tappedNumber = _tappedMediaActionNumber.value;
          switch (tappedNumber) {
            case 1:
              if (playbackState.value!.playing) {
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
        final current = _tappedMediaActionNumber.valueWrapper!.value;
        _tappedMediaActionNumber.add(current + 1);
      }
    }

}
