import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sint/sint.dart';
import 'package:neom_sound/neom_sound.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/data/implementations/neom_stopwatch.dart';
import 'package:neom_core/domain/model/casete/casete_session.dart';
import 'package:neom_core/domain/repository/casete_session_repository.dart';
import 'package:neom_core/domain/use_cases/audio_handler_service.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/media_player_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';
import 'package:neom_core/utils/enums/user_role.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:neom_sound/data/implementations/equalizer_controller.dart';
import 'package:neom_sound/domain/use_cases/equalizer_service.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'data/implementations/android_equalizer_bridge.dart';
import 'data/implementations/casete_hive_controller.dart';
import 'data/implementations/player_hive_controller.dart';
import 'data/implementations/playlist_hive_controller.dart';
import 'domain/models/queue_state.dart';
import 'utils/audio_player_stats.dart';
import 'utils/audio_quality_swap.dart';
import 'utils/constants/audio_player_constants.dart';
import 'utils/mappers/media_item_mapper.dart';
import 'utils/media_url_resolver_registry.dart';
import 'utils/neom_audio_utilities.dart';
import 'utils/playback_access_policy.dart';
import 'utils/playback_error_recovery.dart';

/// Central audio handler for the Open Neom audio module.
///
/// Wraps a single [AudioPlayer] (from `just_audio`) under the
/// [BaseAudioHandler] / [QueueHandler] / [SeekHandler] mixins so that
/// playback survives the foreground service, the lock-screen notification,
/// headset buttons, wearables and Android Auto via the `audio_service`
/// package.
///
/// **Single-player invariant.** This class owns exactly one set-once player
/// instance, constructed in the body of [NeomAudioHandler] (a
/// mutually-exclusive `kIsWeb` branch picks the appropriate constructor —
/// with or without [AndroidEqualizer]). Track switches always go through
/// `setAudioSource(s)` on that single player, which atomically
/// stops the previous source before the new one starts. The
/// `single_player_invariant_test.dart` suite enforces this guarantee at
/// build time so two tracks can never play on top of each other.
///
/// Register it as a fenix singleton in your root binding:
/// ```dart
/// Bind.lazyPut(() => NeomAudioHandler(), fenix: true);
/// Bind.lazyPut<AudioHandlerService>(() => Sint.find<NeomAudioHandler>(), fenix: true);
/// ```
class NeomAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements AudioHandlerService {
  static final likeControl = MediaControl(
    androidIcon: 'drawable/ic_action_like',
    label: 'Like',
    action: MediaAction.fastForward,
  );
  static final unlikeControl = MediaControl(
    androidIcon: 'drawable/ic_action_unlike',
    label: 'Unlike',
    action: MediaAction.rewind,
  );

  int? count;
  Timer? _sleepTimer;
  final RxBool isLoadingAudio = false.obs;
  Timer? _caseteBeaconTimer;
  String? _currentCaseteSessionId;
  bool _casetePersistenceWasAllowed = false;
  bool? _lastPersonalAccessAllowed;
  final Rxn<DateTime> sleepTimerEndTime = Rxn<DateTime>();

  AndroidEqualizer? _androidEqualizer;
  late final AudioPlayer player;
  MediaItem? currentMediaItem;

  String connectionType = AppTranslationConstants.wifi;

  final List<String> refreshLinks = [];
  bool jobRunning = false;

  PlayerHiveController playerHiveController = PlayerHiveController();
  final PlaylistHiveController _playlistHiveController =
      PlaylistHiveController();
  bool _currentItemLiked = false;

  bool stopForegroundService = true;

  final rx.BehaviorSubject<List<MediaItem>> _recentSubject =
      rx.BehaviorSubject.seeded(<MediaItem>[]);

  UserService get userServiceImpl => Sint.find<UserService>();
  final neomStopwatch = NeomStopwatch();

  int caseteSessionDuration = 0; //Seconds per session
  int casetePerSession = 0; //Pages per session
  int averageCasete = 0;
  bool isCaseteElegible = true;
  bool isFree = false;
  // Fail closed until the central gate resolves the current session and
  // subscription. These public fields remain as live UI-compatible mirrors.
  bool allowFullAccess = false;
  bool allowFreeTrial = false;
  bool _stoppedByVideo = false;

  @override
  final rx.BehaviorSubject<double> volume = rx.BehaviorSubject.seeded(1.0);
  @override
  final rx.BehaviorSubject<double> speed = rx.BehaviorSubject.seeded(1.0);
  final _mediaItemExpando = Expando<MediaItem>();
  final List<StreamSubscription> _subscriptions = [];

  // Playback error recovery state. The decision policy lives in the pure
  // [PlaybackErrorRecovery] class; the fields below are the wiring state:
  // re-entrancy guard (error bursts coalesce into [_pendingPlaybackError]),
  // connectivity-resume watcher, and snackbar throttling.
  final PlaybackErrorRecovery _errorRecovery = PlaybackErrorRecovery();
  bool _recoveringFromError = false;
  Object? _pendingPlaybackError;
  bool _awaitingConnectivity = false;
  StreamSubscription? _connectivitySubscription;
  DateTime _lastRecoverySnackAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Fresh-URL resolvers registered by modules (expired signed URLs, rotated
  /// CDN links…). Consulted by the recovery flow before a track is retried.
  final MediaUrlResolverRegistry urlResolverRegistry =
      MediaUrlResolverRegistry();

  @override
  void registerUrlResolver(String owner, MediaUrlResolver resolver) =>
      urlResolverRegistry.register(owner, resolver);

  @override
  void unregisterUrlResolver(String owner) =>
      urlResolverRegistry.unregister(owner);

  Stream<List<IndexedAudioSource>> get _effectiveSequence =>
      rx.Rx.combineLatest3<
            List<IndexedAudioSource>?,
            List<int>?,
            bool,
            List<IndexedAudioSource>?
          >(
            player.sequenceStream,
            player.shuffleIndicesStream,
            player.shuffleModeEnabledStream,
            (sequence, shuffleIndices, shuffleModeEnabled) {
              if (sequence == null) return [];
              if (!shuffleModeEnabled) return sequence;
              if (shuffleIndices == null) return null;
              if (shuffleIndices.length != sequence.length) return null;
              return shuffleIndices.map((i) => sequence[i]).toList();
            },
          )
          .whereType<List<IndexedAudioSource>>();

  Stream<QueueState> get queueState =>
      rx.Rx.combineLatest3<
            List<MediaItem>,
            PlaybackState,
            List<int>,
            QueueState
          >(
            queue,
            playbackState,
            player.shuffleIndicesStream.whereType<List<int>>(),
            (queue, playbackState, shuffleIndices) => QueueState(
              queue,
              playbackState.queueIndex,
              playbackState.shuffleMode == AudioServiceShuffleMode.all
                  ? shuffleIndices
                  : null,
              playbackState.repeatMode,
            ),
          )
          .where(
            (state) =>
                state.shuffleIndices == null ||
                state.queue.length == state.shuffleIndices!.length,
          );

  NeomAudioHandler() {
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      _androidEqualizer = AndroidEqualizer();
      final pipeline = AudioPipeline(androidAudioEffects: [_androidEqualizer!]);
      player = AudioPlayer(audioPipeline: pipeline);
    } else {
      player = AudioPlayer();
    }
    _init();
  }

  Future<void> _init() async {
    AppConfig.logger.t('Starting NeomAudioHandler');

    try {
      startService();
      // The handler is created before RootBinding in some hosts. Never grant
      // access merely because UserService has not been registered yet; each
      // playback entry point resolves the current entitlement dynamically.
      startFreeTrialTimer();
      startCaseteBeaconTimer();

      // Connect the EqualizerController to the native AndroidEqualizer
      if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
        _connectEqualizer();
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_audio_player',
        operation: '_init',
      );
    }
  }

  /// Bridge the EqualizerController to the native AndroidEqualizer.
  void _connectEqualizer() {
    if (_androidEqualizer == null) return;
    try {
      final eqController = Sint.find<EqualizerService>();
      if (eqController is EqualizerController) {
        eqController.attachBridge(AndroidEqualizerBridge(_androidEqualizer!));
        AppConfig.logger.d(
          'EqualizerController attached to native AndroidEqualizer',
        );
      }
    } catch (e, st) {
      AppConfig.logger.w(
        'EqualizerController not registered yet, EQ bridge skipped',
      );
    }
  }

  Future<void> setListeners() async {
    AppConfig.logger.d('Setting AudioHandler Listeners');

    // Cancel previous subscriptions to prevent duplicates on re-init
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    _subscriptions.add(
      mediaItem.whereType<MediaItem>().listen((item) async {
        if (count != null) {
          count = count! - 1;
          if (count! <= 0) {
            count = null;
            await stop();
          }
        }

        currentMediaItem = item;
        _currentItemLiked = await _playlistHiveController.checkPlaylist(
          AppHiveBox.favoriteItems.name,
          item.id,
        );
        setItemInMediaPlayers();

        neomStopwatch.start(ref: item.id);

        if (AppConfig.instance.canPersistUserActivity &&
            item.artUri.toString().startsWith(CoreConstants.http)) {
          _recentSubject.add([item]);
        }
      }),
    );

    _subscriptions.add(
      rx.Rx.combineLatest4<int?, List<MediaItem>, bool, List<int>?, MediaItem?>(
        player.currentIndexStream,
        queue,
        player.shuffleModeEnabledStream,
        player.shuffleIndicesStream,
        (index, queue, shuffleModeEnabled, shuffleIndices) {
          final queueIndex = NeomAudioUtilities.getQueueIndex(player, index);
          return (queueIndex != null && queueIndex < queue.length)
              ? queue[queueIndex]
              : null;
        },
      ).whereType<MediaItem>().distinct().listen(mediaItem.add),
    );

    _subscriptions.add(player.playbackEventStream.listen(_broadcastState));
    _subscriptions.add(
      player.shuffleModeEnabledStream.listen(
        (enabled) => _broadcastState(player.playbackEvent),
      ),
    );
    _subscriptions.add(
      player.loopModeStream.listen(
        (event) => _broadcastState(player.playbackEvent),
      ),
    );

    // Playback error recovery: without this listener a dead URL or a network
    // drop left the user in silence. Errors funnel into _handlePlaybackError,
    // which retries the track, auto-skips it, or pauses with feedback.
    // NOTE: errorStream is a PublishSubject (single-subscription) — re-init
    // is safe because setListeners() cancels every previous subscription.
    _subscriptions.add(
      player.errorStream.listen((error) {
        _handlePlaybackError(error);
      }),
    );

    _subscriptions.add(
      player.processingStateStream.listen((state) async {
        AppConfig.logger.d('Audio Player - Processing Stream: ${state.name}');
        switch (state) {
          case ProcessingState.loading:
            break;
          case ProcessingState.ready:
            // Healthy playback reached: recovery budgets reset so a transient
            // blip does not poison the session, and any connectivity-resume
            // watcher becomes obsolete.
            _errorRecovery.reset();
            _awaitingConnectivity = false;
            _connectivitySubscription?.cancel();
            _connectivitySubscription = null;
            if (neomStopwatch.currentReference != (mediaItem.value?.id ?? '')) {
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
      }),
    );

    // Broadcast the current queue.
    _subscriptions.add(
      _effectiveSequence
          .map(
            (sequence) =>
                sequence.map((source) => _mediaItemExpando[source]!).toList(),
          )
          .listen(queue.add),
    );

    _setupAudioSessionListeners();
  }

  // ---------------------------------------------------------------------------
  // Audio session: interruptions and headphone unplug
  // ---------------------------------------------------------------------------

  /// Volume to restore after a transient duck (e.g. a navigation prompt).
  double _volumeBeforeDuck = 1.0;

  /// Whether playback was paused *by an interruption* (as opposed to the user),
  /// so it can be resumed when the interruption ends.
  bool _pausedByInterruption = false;

  /// Reacts to the OS audio session: phone calls, other apps taking focus, and
  /// headphones being unplugged.
  ///
  /// Neither `just_audio` nor `audio_service` do this for you — without it a
  /// call plays over the music and unplugging headphones blasts the track
  /// through the speaker, which is the behaviour every music app is judged on.
  Future<void> _setupAudioSessionListeners() async {
    if (kIsWeb) return; // browsers manage focus themselves
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Headphones/Bluetooth disconnected → pause, never blast the speaker.
      _subscriptions.add(
        session.becomingNoisyEventStream.listen((_) {
          if (player.playing) {
            _pausedByInterruption = false; // user must resume deliberately
            pause();
            AppConfig.logger.d('AudioSession: became noisy — paused playback');
          }
        }),
      );

      // Calls / other apps grabbing focus.
      _subscriptions.add(
        session.interruptionEventStream.listen((event) {
          if (event.begin) {
            switch (event.type) {
              case AudioInterruptionType.duck:
                _volumeBeforeDuck = player.volume;
                player.setVolume(_volumeBeforeDuck * 0.3);
              case AudioInterruptionType.pause:
              case AudioInterruptionType.unknown:
                if (player.playing) {
                  _pausedByInterruption = true;
                  pause();
                }
            }
          } else {
            switch (event.type) {
              case AudioInterruptionType.duck:
                player.setVolume(_volumeBeforeDuck);
              case AudioInterruptionType.pause:
                // Resume only what we paused, and only for transient events.
                if (_pausedByInterruption) {
                  _pausedByInterruption = false;
                  play();
                }
              case AudioInterruptionType.unknown:
                // Focus may be gone for good — stay paused.
                _pausedByInterruption = false;
            }
          }
        }),
      );
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'setupAudioSession',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Playback authorization
  // ---------------------------------------------------------------------------

  /// Resolves the current entitlement at the moment of the transport action.
  ///
  /// This must stay dynamic: the handler can outlive login/logout and is also
  /// constructed before RootBinding in some hosts. A missing service therefore
  /// means "not ready", never full access.
  Future<PlaybackAccessDecision> _resolvePlaybackAccess(
    PlaybackRequestOrigin origin,
  ) async {
    final config = AppConfig.instance;
    final isAuthenticated = config.canPersistUserActivity;

    var authStatus = config.authStatus;
    final hasLoginService = Sint.isRegistered<LoginService>();
    if (hasLoginService) {
      try {
        authStatus = Sint.find<LoginService>().getAuthStatus();
      } catch (e, st) {
        NeomErrorLogger.recordErrorLight(
          e,
          st,
          module: 'neom_audio_player',
          operation: 'resolvePlaybackAuthStatus',
        );
      }
    }

    // loggedIn without canPersistUserActivity means Firebase or the local user
    // is still loading. It must not be downgraded to a guest entitlement.
    final isSessionReady =
        isAuthenticated ||
        (hasLoginService && authStatus == AuthStatus.notLoggedIn);

    var hasFullSubscription = false;
    if (isAuthenticated && Sint.isRegistered<UserService>()) {
      try {
        hasFullSubscription =
            userServiceImpl.subscriptionLevel.value >
            SubscriptionLevel.freemium.value;
      } catch (e, st) {
        NeomErrorLogger.recordErrorLight(
          e,
          st,
          module: 'neom_audio_player',
          operation: 'resolvePlaybackSubscription',
        );
      }
    }

    var hasActiveTrial = false;
    if (!isFree && isSessionReady && !hasFullSubscription) {
      try {
        final dailyTrialUsage = await CaseteTrialUsageManager()
            .getDailyTrialUsage();
        final limit = isAuthenticated
            ? AudioPlayerConstants.trialDuration
            : AudioPlayerConstants.guestTrialDuration;
        hasActiveTrial = dailyTrialUsage < limit;
      } catch (e, st) {
        // Quota storage being unavailable cannot turn into unlimited playback.
        NeomErrorLogger.recordErrorLight(
          e,
          st,
          module: 'neom_audio_player',
          operation: 'resolvePlaybackTrial',
        );
      }
    }

    allowFullAccess = hasFullSubscription;
    allowFreeTrial = hasActiveTrial;

    return PlaybackAccessPolicy.evaluate(
      PlaybackAccessSnapshot(
        isSessionReady: isSessionReady,
        isAuthenticated: isAuthenticated,
        hasFullSubscription: hasFullSubscription,
        hasActiveTrial: hasActiveTrial,
        isPubliclyFree: isFree,
      ),
      origin: origin,
    );
  }

  /// Single gate used by every path capable of starting or continuing audio.
  Future<PlaybackAccessDecision> _authorizePlayback(
    PlaybackRequestOrigin origin, {
    bool showFeedback = true,
  }) async {
    PlaybackAccessDecision decision;
    try {
      await enforcePersonalStateBoundary();
      decision = await _resolvePlaybackAccess(origin);
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'authorizePlayback',
      );
      decision = const PlaybackAccessDecision.deny(
        PlaybackAccessReason.sessionNotReady,
      );
    }

    if (decision.allowed) return decision;

    // A denied transport request must also stop audio that was already active;
    // returning alone would let a skip/recovery request leave it playing.
    if (player.playing) await pause();
    isLoadingAudio.value = false;

    if (!showFeedback) return decision;
    switch (decision.reason) {
      case PlaybackAccessReason.guestTrialExhausted:
        if (Sint.context != null) {
          AuthGuard.showGuestModal(Sint.context!);
        }
      case PlaybackAccessReason.freemiumTrialExhausted:
        AppUtilities.showSnackBar(
          title: AppTranslationConstants.trialEnded.tr,
          message: AppTranslationConstants.trialEndedMessage.tr,
        );
      case PlaybackAccessReason.sessionNotReady:
        AppConfig.logger.d(
          'Playback blocked while authentication/entitlement is resolving.',
        );
      case PlaybackAccessReason.publicContent:
      case PlaybackAccessReason.fullSubscription:
      case PlaybackAccessReason.activeTrial:
        break;
    }
    return decision;
  }

  // ---------------------------------------------------------------------------
  // Playback error recovery
  // ---------------------------------------------------------------------------

  /// Central funnel for every playback failure (dead URL, network drop,
  /// undecodable media). Decides via [PlaybackErrorRecovery] whether to retry
  /// the same track, skip it, or give up — and arms a connectivity watcher
  /// when the failure coincides with being offline.
  ///
  /// Re-entrant safe: error bursts (a failing load often emits several events)
  /// coalesce into [_pendingPlaybackError] and are processed sequentially.
  Future<void> _handlePlaybackError(Object error) async {
    final access = await _authorizePlayback(
      PlaybackRequestOrigin.recovery,
      showFeedback: false,
    );
    if (!access.allowed) return;

    if (_recoveringFromError) {
      _pendingPlaybackError = error;
      return;
    }
    _recoveringFromError = true;
    try {
      final itemId = currentMediaItem?.id ?? mediaItem.value?.id ?? '';
      NeomErrorLogger.recordErrorLight(
        error,
        StackTrace.current,
        module: 'neom_audio_player',
        operation: 'playbackError',
      );

      final queueItems = queue.value;
      final currentIndex = queueItems.indexWhere((item) => item.id == itemId);
      final hasNext = currentIndex >= 0 && currentIndex + 1 < queueItems.length;

      final action = _errorRecovery.registerError(itemId, hasNext: hasNext);
      AppConfig.logger.w(
        'Playback error on "$itemId" '
        '(item attempt ${_errorRecovery.sameItemErrors}, '
        'total ${_errorRecovery.totalAttempts}) -> ${action.name}',
      );

      switch (action) {
        case PlaybackRecoveryAction.retrySame:
          if (_errorRecovery.sameItemErrors == 1) {
            _showRecoverySnack(AppTranslationConstants.playbackErrorRetrying);
          }
          // Small linear backoff before re-attempting the failing source.
          await Future.delayed(
            Duration(seconds: _errorRecovery.sameItemErrors),
          );
          // Before blindly reloading the same (possibly stale) URL, ask
          // registered resolvers for a fresh one — or bypass the quality
          // swap when the swapped variant is what 404s.
          var reloaded = await _tryResolveFreshUrl(itemId);
          reloaded = reloaded || await _reloadCurrentItem();
          if (!reloaded) {
            // The reload failed synchronously (no new stream error will fire);
            // feed it back so escalation keeps moving.
            _pendingPlaybackError ??= Exception('Reload failed for $itemId');
          }
          break;
        case PlaybackRecoveryAction.skipNext:
          _showRecoverySnack(AppTranslationConstants.playbackErrorSkipped);
          await skipToNext();
          break;
        case PlaybackRecoveryAction.giveUp:
          _showRecoverySnack(AppTranslationConstants.playbackErrorStopped);
          _errorRecovery.reset();
          if (!await _isOnline()) {
            // Offline: resume automatically as soon as connectivity returns.
            _awaitingConnectivity = true;
            _watchConnectivityForResume();
          }
          await pause();
          break;
      }
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: '_handlePlaybackError',
      );
    } finally {
      _recoveringFromError = false;
      final pending = _pendingPlaybackError;
      _pendingPlaybackError = null;
      if (pending != null) {
        unawaited(Future.microtask(() => _handlePlaybackError(pending)));
      }
    }
  }

  /// Attempts to obtain a FRESH URL for the failing item and rebuild its
  /// audio source in place. Two paths:
  ///
  /// 1. Registered [MediaUrlResolver]s (modules with a source-specific
  ///    refresh path: expired signed URLs, rotated CDN links…).
  /// 2. Built-in quality-swap bypass: when the configured preferred quality
  ///    rewrote `_96.` to a variant that does not exist server-side, retry
  ///    the original baseline file with [AudioQualitySwap.noSwapFlag] set.
  ///
  /// Returns true when a fresh source was built and playback restarted.
  Future<bool> _tryResolveFreshUrl(String itemId) async {
    final initialAccess = await _authorizePlayback(
      PlaybackRequestOrigin.recovery,
      showFeedback: false,
    );
    if (!initialAccess.allowed) return false;

    try {
      final matches = queue.value.where((e) => e.id == itemId);
      final item = matches.isNotEmpty
          ? matches.first
          : (currentMediaItem?.id == itemId ? currentMediaItem : null);
      if (item == null) return false;

      final extras = item.extras ?? <String, dynamic>{};
      Map<String, dynamic> newExtras;

      final freshUrl = await urlResolverRegistry.resolveFreshUrl(
        itemId,
        extras,
      );
      if (freshUrl != null) {
        AppConfig.logger.i('Fresh URL resolved for "$itemId"');
        newExtras = {...extras, 'url': freshUrl};
      } else {
        final originalUrl = extras['url']?.toString() ?? '';
        final preferredQuality = AppConfig.instance.canPersistUserActivity
            ? playerHiveController.preferredQuality
            : '';
        final canBypassSwap =
            extras[AudioQualitySwap.noSwapFlag] != true &&
            AudioQualitySwap.wouldSwap(originalUrl, preferredQuality);
        if (!canBypassSwap) return false;
        AppConfig.logger.w(
          'Quality-swapped URL failed for "$itemId" — '
          'retrying the original baseline file',
        );
        newExtras = {...extras, AudioQualitySwap.noSwapFlag: true};
      }

      final updated = item.copyWith(extras: newExtras);
      final source = await _itemToSource(updated);
      if (source == null) return false;

      final index = queue.value.indexWhere((e) => e.id == itemId);
      final sequenceLength = player.audioSource?.sequence.length ?? 0;
      if (index >= 0 && index < sequenceLength) {
        // Replace the source IN PLACE so queue order and position survive.
        await player.removeAudioSourceAt(index);
        await player.insertAudioSource(index, source);
        if (currentMediaItem?.id == itemId) currentMediaItem = updated;
        await player.seek(Duration.zero, index: index);
        final access = await _authorizePlayback(
          PlaybackRequestOrigin.recovery,
          showFeedback: false,
        );
        if (!access.allowed) return false;
        await player.play();
        return true;
      }
      if (currentMediaItem?.id == itemId) {
        currentMediaItem = updated;
        await player.setAudioSource(source);
        final access = await _authorizePlayback(
          PlaybackRequestOrigin.recovery,
          showFeedback: false,
        );
        if (!access.allowed) return false;
        await player.play();
        return true;
      }
      return false;
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: '_tryResolveFreshUrl',
      );
      return false;
    }
  }

  /// Re-attempts the current track. When the item is part of a loaded queue
  /// this re-seeks the current index, which forces just_audio to reload that
  /// segment; when the sequence is empty (the item never became a source)
  /// a fresh standalone source is built. Returns false when the reload could
  /// not even be attempted (caller must keep escalating).
  Future<bool> _reloadCurrentItem() async {
    final initialAccess = await _authorizePlayback(
      PlaybackRequestOrigin.recovery,
      showFeedback: false,
    );
    if (!initialAccess.allowed) return false;

    try {
      final item = currentMediaItem;
      if (item == null) return false;

      if (player.audioSource == null ||
          (player.audioSource?.sequence.isEmpty ?? true)) {
        final source = await _itemToSource(item);
        if (source == null) return false;
        await player.setAudioSource(source);
        final access = await _authorizePlayback(
          PlaybackRequestOrigin.recovery,
          showFeedback: false,
        );
        if (!access.allowed) return false;
        await player.play();
        return true;
      }

      await player.seek(Duration.zero, index: player.currentIndex ?? 0);
      final access = await _authorizePlayback(
        PlaybackRequestOrigin.recovery,
        showFeedback: false,
      );
      if (!access.allowed) return false;
      await player.play();
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: '_reloadCurrentItem',
      );
      return false;
    }
  }

  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: '_isOnline',
      );
      // Fail-open: assume online so recovery does not stall on platforms
      // where the connectivity plugin is unavailable.
      return true;
    }
  }

  /// One-shot watcher that reloads the failed track once connectivity returns.
  /// Rearmed on every offline give-up; cancelled when playback becomes ready.
  void _watchConnectivityForResume() {
    if (_connectivitySubscription != null) return;
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) async {
        final online = !results.contains(ConnectivityResult.none);
        if (online && _awaitingConnectivity && currentMediaItem != null) {
          _awaitingConnectivity = false;
          AppConfig.logger.i(
            'Connectivity restored — resuming playback recovery',
          );
          await _reloadCurrentItem();
        }
      },
      onError: (Object e, StackTrace st) {
        NeomErrorLogger.recordErrorLight(
          e,
          st,
          module: 'neom_audio_player',
          operation: '_watchConnectivityForResume',
        );
      },
    );
  }

  /// Throttled user feedback: error storms must not queue dozens of snackbars.
  void _showRecoverySnack(String messageKey) {
    final now = DateTime.now();
    if (now.difference(_lastRecoverySnackAt).inSeconds < 4) return;
    _lastRecoverySnackAt = now;
    AppUtilities.showSnackBar(
      title: AppTranslationConstants.error,
      message: messageKey,
    );
  }

  Future<void> loadLastQueue() async {
    AppConfig.logger.d('Loading last queue from Hive');

    final canPersist = AppConfig.instance.canPersistUserActivity;
    _lastPersonalAccessAllowed = canPersist;
    await playerHiveController.init();
    if (!canPersist) {
      AppConfig.logger.d(
        'Guest or unloaded user; cached queue restoration skipped.',
      );
      return;
    }

    if (playerHiveController.loadStart) {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Agrega un breve delay para dar tiempo a otros procesos
      final List lastQueueList = playerHiveController.lastQueueList;
      if (lastQueueList.isNotEmpty) {
        final List<MediaItem> lastQueue = lastQueueList
            .map((e) => MediaItemMapper.fromJSON(e as Map))
            .toList();

        if (lastQueue.isNotEmpty) {
          try {
            List<AudioSource> sources = await _itemsToSources(lastQueue);
            await player.setAudioSources(sources);
            await gotoLastIndexAndPosition();
          } catch (e, st) {
            NeomErrorLogger.recordError(
              e,
              st,
              module: 'neom_audio_player',
              operation: 'loadLastQueue',
            );
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
  Timer? _broadcastDebounceTimer;
  bool? _lastBroadcastPlaying;

  void _broadcastState(PlaybackEvent event) {
    final playing = player.playing;
    // Bypass debounce for play/pause changes (needs immediate UI feedback)
    if (_lastBroadcastPlaying != playing) {
      _broadcastDebounceTimer?.cancel();
      _broadcastDebounceTimer = null;
      _lastBroadcastPlaying = playing;
      _doBroadcastState(event);
      return;
    }
    // Debounce other rapid calls (e.g. buffering updates)
    _broadcastDebounceTimer?.cancel();
    _broadcastDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      _doBroadcastState(event);
    });
  }

  void _doBroadcastState(PlaybackEvent event) {
    try {
      final playing = player.playing;
      bool liked = _currentItemLiked;
      final queueIndex = NeomAudioUtilities.getQueueIndex(
        player,
        event.currentIndex,
      );

      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            if (liked) unlikeControl else likeControl,
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          systemActions: NeomAudioUtilities.mediaActions,
          androidCompactActionIndices:
              playerHiveController.preferredCompactNotificationButtons,
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
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: '_doBroadcastState',
      );
    }
  }

  Future<void> refreshLink(Map newData) async {
    AppConfig.logger.i(
      'Audio Player refreshLink | received new link for ${newData['title']}',
    );
    final MediaItem newItem = MediaItemMapper.fromJSON(newData);

    final index = queue.value.indexWhere((e) => e.id == newItem.id);
    final sequenceLength = player.audioSource?.sequence.length ?? 0;
    if (index >= 0 && index < sequenceLength) {
      // Replace the stale source IN PLACE (previously this appended a
      // duplicate at the end of the queue, leaving the dead one behind).
      final source = await _itemToSource(newItem);
      if (source != null) {
        AppConfig.logger.i('player | replacing refreshed item at index $index');
        await player.removeAudioSourceAt(index);
        await player.insertAudioSource(index, source);
        return;
      }
    }

    AppConfig.logger.i('player | inserting refreshed item');
    addQueueItem(newItem);
  }

  Future<AudioSource?> _itemToSource(MediaItem mediaItem) async {
    AudioSource? audioSource;
    AppConfig.logger.d(
      "Moving mediaItem ${mediaItem.title} to audioSource for Music Player ",
    );
    try {
      if (mediaItem.artUri.toString().startsWith('file:')) {
        audioSource = AudioSource.uri(
          Uri.file(mediaItem.extras!['url'].toString()),
        );
      } else {
        // Offline-first resolution: a valid downloaded file wins. When the
        // entry is stale (file deleted, zero-length, corrupted partial) the
        // Hive record is removed and playback FALLS BACK to the network —
        // previously any missing/offline entry left audioSource null and the
        // track died in silence.
        bool offlineResolved = false;
        final canUsePersonalPlaybackState =
            AppConfig.instance.canPersistUserActivity;
        if (canUsePersonalPlaybackState && playerHiveController.useDownload) {
          AppConfig.logger.d("Looking for files from downloads");
          final downloadsBox = await AppHiveController().getBox(
            AppHiveBox.downloads.name,
          );
          if (downloadsBox.containsKey(mediaItem.id)) {
            final path = downloadsBox.get(mediaItem.id)['path'].toString();
            final file = File(path);
            if (path.isNotEmpty && file.existsSync() && file.lengthSync() > 0) {
              audioSource = AudioSource.uri(Uri.file(path), tag: mediaItem.id);
              offlineResolved = true;
            } else {
              AppConfig.logger.w(
                'Stale download entry for ${mediaItem.title} '
                '(path: $path) — removing it and falling back to network',
              );
              await downloadsBox.delete(mediaItem.id);
            }
          }
        }
        if (!offlineResolved) {
          String audioUrl = '';
          if (mediaItem.extras!['url'] != null &&
              mediaItem.extras!['url'].toString().isNotEmpty) {
            audioUrl = mediaItem.extras!['url'].toString();
            // The quality rewrite may point to a variant that does not exist
            // server-side; the recovery flow sets noQualitySwap on the item
            // to retry the original baseline file.
            if (mediaItem.extras?[AudioQualitySwap.noSwapFlag] != true) {
              audioUrl = AudioQualitySwap.apply(
                audioUrl,
                canUsePersonalPlaybackState
                    ? playerHiveController.preferredQuality
                    : '',
              );
            }
          }

          if (!kIsWeb &&
              canUsePersonalPlaybackState &&
              playerHiveController.cacheSong &&
              CoreUtilities.isInternal(audioUrl)) {
            audioSource = LockCachingAudioSource(Uri.parse(audioUrl));
          } else {
            audioSource = AudioSource.uri(Uri.parse(audioUrl));
          }
        }
      }

      if (audioSource != null) {
        _mediaItemExpando[audioSource] = mediaItem;
      } else {
        AppConfig.logger.w('No audio source created for ${mediaItem.title}');
      }
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: '_itemToSource',
      );
    }

    return audioSource;
  }

  Future<AudioSource?> _itemToSourceWithRetry(
    MediaItem mediaItem, {
    int maxRetries = 2,
  }) async {
    AudioSource? source = await _itemToSource(mediaItem);
    int attempt = 0;
    while (source == null && attempt < maxRetries) {
      attempt++;
      AppConfig.logger.w('Retry $attempt/$maxRetries for ${mediaItem.title}');
      await Future.delayed(const Duration(seconds: 1));
      source = await _itemToSource(mediaItem);
    }
    if (source == null) {
      AppConfig.logger.e(
        'Failed to create audio source for ${mediaItem.title} after $maxRetries retries',
      );
    }
    return source;
  }

  Future<List<AudioSource>> _itemsToSources(List<MediaItem> mediaItems) async {
    final List<AudioSource> sources = [];

    try {
      for (final element in mediaItems) {
        AudioSource? src = await _itemToSource(element);
        if (src != null) sources.add(src);
      }
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: '_itemsToSources',
      );
    }
    return sources;
  }

  @override
  Future<void> onTaskRemoved() async {
    final bool stopForegroundService =
        PlayerHiveController().stopForegroundService;
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
  rx.ValueStream<Map<String, dynamic>> subscribeToChildren(
    String parentMediaId,
  ) {
    switch (parentMediaId) {
      case AudioService.recentRootId:
        final stream = _recentSubject.map((_) => <String, dynamic>{});
        return _recentSubject.hasValue
            ? stream.shareValueSeeded(<String, dynamic>{})
            : stream.shareValue();
      default:
        return Stream.value(
          queue.value,
        ).map((_) => <String, dynamic>{}).shareValue();
    }
  }

  void startService() async {
    if (player.playing) return;

    AppConfig.logger.d('Starting AudioPlayer Service');
    await player.setAudioSources([]);
    await loadLastQueue();
    await setListeners();
  }

  /// Clears in-memory playback when the app crosses the guest/auth boundary.
  /// This prevents both exposing an authenticated queue to a guest and later
  /// attributing a guest queue to a newly signed-in account.
  Future<void> enforcePersonalStateBoundary() async {
    final canPersist = AppConfig.instance.canPersistUserActivity;
    final sessionChanged =
        _lastPersonalAccessAllowed != null &&
        _lastPersonalAccessAllowed != canPersist;
    _lastPersonalAccessAllowed = canPersist;

    // Refresh/reset settings before any new queue is materialized. Without
    // this, a handler reused after logout could still read the previous
    // account's download/cache preferences even after its queue was cleared.
    await playerHiveController.init();

    if (!sessionChanged) return;

    await player.stop();
    await player.setAudioSources([]);
    currentMediaItem = null;
    mediaItem.add(null);
    queue.add(const <MediaItem>[]);
    _recentSubject.add(const <MediaItem>[]);
    _currentItemLiked = false;
    neomStopwatch.reset();
    AppConfig.logger.d(
      'Cleared audio state after crossing the guest/auth boundary.',
    );
  }

  Future<void> addLastQueue(List<MediaItem> queue) async {
    if (!AppConfig.instance.canPersistUserActivity) return;

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

    final queueIndex = queue.value.indexWhere((item) => item.id == id);
    if (queueIndex >= 0) {
      index = queueIndex;
      AppConfig.logger.t(
        'SkipToMediaItem: mediaItem found in queue with Index $index',
      );
      player.seek(
        Duration.zero,
        index: player.shuffleModeEnabled && index != 0
            ? player.shuffleIndices[index]
            : index,
      );
    } else {
      AppConfig.logger.w('skipToMediaItem: ID $id not found in queue');
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    AppConfig.logger.d('addQueueItem');
    AudioSource? res = await _itemToSource(mediaItem);
    if (res != null) {
      await player.addAudioSource(res);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    AppConfig.logger.d('addQueueItems');
    final newSources = await _itemsToSources(mediaItems);
    if (newSources.isNotEmpty) {
      await player.addAudioSources(newSources);
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    AppConfig.logger.d('insertQueueItem');
    AudioSource? res = await _itemToSource(mediaItem);
    if (res != null) {
      final sequenceLength = player.audioSource?.sequence.length ?? 0;
      if (index <= sequenceLength) {
        await player.insertAudioSource(index, res);
      }
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    AppConfig.logger.d(
      "Updating Music Player Queue with ${newQueue.length} items",
    );
    try {
      final List<AudioSource> sources = await _itemsToSources(newQueue);
      await player.setAudioSources(sources);
      this.queue.add(newQueue);
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'updateQueue',
      );
    }
  }

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    AppConfig.logger.d('updateMediaItem');
    final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    if (index != -1 && index < player.sequence.length) {
      _mediaItemExpando[player.sequence[index]] = mediaItem;
    }
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    AppConfig.logger.d('removeQueueItem');
    final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    if (index != -1) await removeQueueItemAt(index);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    AppConfig.logger.d('removeQueueItemAt at index: $index');
    final sequenceLength = player.audioSource?.sequence.length ?? 0;
    if (index < sequenceLength) {
      await player.removeAudioSourceAt(index);
    }
  }

  @override
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    AppConfig.logger.d('moveQueueItem from index: $currentIndex to $newIndex');
    final sequenceLength = player.audioSource?.sequence.length ?? 0;
    if (currentIndex < sequenceLength && newIndex < sequenceLength) {
      await player.moveAudioSource(currentIndex, newIndex);
    }
  }

  @override
  Future<void> skipToNext() async {
    AppConfig.logger.d('skipToNext');
    final access = await _authorizePlayback(PlaybackRequestOrigin.skipNext);
    if (!access.allowed) return;
    if (currentMediaItem == null) return;

    // Fire-and-forget: el guardado en Firestore no debe bloquear el skip.
    // trackCaseteSession ya captura sus errores internamente.
    unawaited(trackCaseteSession());

    int index = queue.value.indexWhere(
      (item) => item.id == currentMediaItem!.id,
    );
    if (index >= 0 && index + 1 < queue.value.length) {
      MediaItem nextMedia = queue.value.elementAt(index + 1);
      neomStopwatch.start(ref: nextMedia.id);
      currentMediaItem = nextMedia;
      setItemInMediaPlayers();
      await player.seekToNext();
    }
  }

  /// This is called when the user presses the "like" button.
  @override
  Future<void> fastForward() async {
    AppConfig.logger.d('');
    if (!AppConfig.instance.canPersistUserActivity) return;

    if (mediaItem.value?.id != null) {
      await _playlistHiveController.addItemToPlaylist(
        AppHiveBox.favoriteItems.name,
        mediaItem.value!,
      );
      _currentItemLiked = true;
      _broadcastState(player.playbackEvent);
    }
  }

  @override
  Future<void> rewind() async {
    AppConfig.logger.d('rewind');
    if (!AppConfig.instance.canPersistUserActivity) return;

    if (mediaItem.value?.id != null) {
      await _playlistHiveController.removeLiked(mediaItem.value!.id);
      _currentItemLiked = false;
      _broadcastState(player.playbackEvent);
    }
  }

  int currentDuration = 0;
  @override
  Future<void> skipToPrevious() async {
    AppConfig.logger.d('skipToPrevious');
    final access = await _authorizePlayback(PlaybackRequestOrigin.skipPrevious);
    if (!access.allowed) return;
    if (currentMediaItem == null) return;

    // Fire-and-forget: el guardado en Firestore no debe bloquear el skip.
    unawaited(trackCaseteSession());

    if (playerHiveController.resetOnSkip) {
      if ((player.position.inSeconds) <= 2) {
        AppConfig.logger.d('skipToPrevious');

        final index = queue.value.indexWhere(
          (item) => item.id == currentMediaItem!.id,
        );
        if (queue.value.isNotEmpty && (index - 1 >= 0)) {
          MediaItem previousMedia = queue.value.elementAt(index - 1);
          neomStopwatch.start(ref: previousMedia.id);
          currentMediaItem = previousMedia;
          setItemInMediaPlayers();
        }
        // ROADMAP: integrate per-track Casete stopwatch tracking on skipPrevious.
        await player.seekToPrevious();
      } else {
        AppConfig.logger.d('Reset currentitem');
        await player.seek(Duration.zero);
      }
    } else {
      await player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final access = await _authorizePlayback(
      PlaybackRequestOrigin.skipToQueueItem,
    );
    if (!access.allowed) return;
    await _skipToQueueItemAfterAuthorization(
      index,
      origin: PlaybackRequestOrigin.skipToQueueItem,
    );
  }

  Future<void> _skipToQueueItemAfterAuthorization(
    int index, {
    required PlaybackRequestOrigin origin,
  }) async {
    final playlistLength = player.audioSource?.sequence.length ?? 0;
    if (index < 0 || index >= playlistLength) return;
    await player.seek(
      Duration.zero,
      index: player.shuffleModeEnabled ? player.shuffleIndices[index] : index,
    );
    final access = await _authorizePlayback(origin, showFeedback: false);
    if (!access.allowed) return;
    await player.play();
  }

  /// Loads [mediaItem] and starts playback, appending it to the queue when
  /// it is not already there. Required by Jam Session listener sync — the
  /// base implementation in audio_service is a no-op.
  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    AppConfig.logger.d('playMediaItem: ${mediaItem.title}');
    final access = await _authorizePlayback(
      PlaybackRequestOrigin.playMediaItem,
    );
    if (!access.allowed) return;

    var index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    if (index < 0) {
      await addQueueItem(mediaItem);
      // queue.value syncs asynchronously from the player sequence; when it
      // has not caught up yet, fall back to the last appended source.
      index = queue.value.indexWhere((item) => item.id == mediaItem.id);
      if (index < 0) {
        index = (player.audioSource?.sequence.length ?? 1) - 1;
      }
    }
    // Already authorized above; avoid a second quota read while preserving the
    // same central gate for direct skipToQueueItem callers.
    await _skipToQueueItemAfterAuthorization(
      index,
      origin: PlaybackRequestOrigin.playMediaItem,
    );
  }

  @override
  Future<void> play() async {
    AppConfig.logger.d('NeomAudioHandler Dispose and Play');

    try {
      final initialAccess = await _authorizePlayback(
        PlaybackRequestOrigin.play,
      );
      if (!initialAccess.allowed) return;

      if (currentMediaItem != null) {
        isLoadingAudio.value = true;
        if (player.audioSource == null ||
            currentMediaItem!.id != mediaItem.value?.id) {
          AudioSource? audioSource = await _itemToSourceWithRetry(
            currentMediaItem!,
          );
          if (audioSource != null) {
            await player.setAudioSource(audioSource);
          } else {
            AppConfig.logger.w(
              'Unable to play: no audio source for ${currentMediaItem!.title}',
            );
            isLoadingAudio.value = false;
            // Feed the failure into recovery (retry → skip → pause) instead
            // of leaving the user in silence.
            await _handlePlaybackError(
              Exception('No audio source for ${currentMediaItem!.id}'),
            );
            return;
          }
        }

        setItemInMediaPlayers();
        isLoadingAudio.value = false;
        neomStopwatch.start(ref: currentMediaItem!.id);
        if (Sint.isRegistered<MediaPlayerService>()) {
          Sint.find<MediaPlayerService>().muteVideoPlayer();
        }
        // Loading/resolving a source can outlive a logout or subscription
        // transition, so check once more immediately before starting audio.
        final access = await _authorizePlayback(
          PlaybackRequestOrigin.play,
          showFeedback: false,
        );
        if (!access.allowed) return;
        await player.play();
      }
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'play',
      );
    }
  }

  @override
  Future<void> pause() async {
    AppConfig.logger.d('Pause');
    await player.pause();
    // Fire-and-forget: el guardado en Firestore no debe retrasar la pausa.
    unawaited(trackCaseteSession());
    if (currentMediaItem != null) {
      neomStopwatch.pause(ref: currentMediaItem!.id);
    }

    addLastQueue(queue.value);
    await playerHiveController.setLastIndexAndPos(
      player.currentIndex,
      player.position.inSeconds,
    );
  }

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    AppConfig.logger.d('Stopping player');
    unawaited(trackCaseteSession());
    await player.stop();
    if (playbackState.value.processingState != AudioProcessingState.idle) {
      await playbackState
          .firstWhere(
            (state) => state.processingState == AudioProcessingState.idle,
          )
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => playbackState.value,
          );
    }

    AppConfig.logger.t(
      'Caching last index ${player.currentIndex} and position ${player.position.inSeconds}',
    );

    await addLastQueue(queue.value);
    if (AppConfig.instance.canPersistUserActivity) {
      AppHiveController().setLastIndexPos(
        lastIndex: player.currentIndex,
        lastPos: player.position.inSeconds,
      );
    }
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    AppConfig.logger.d('CustomAction $name called');

    switch (name) {
      case 'skipToMediaItem':
        await skipToMediaItem(
          extras!['id'].toString(),
          index: extras['index'] != null
              ? int.parse(extras['index'].toString())
              : 0,
        );
      case 'fastForward':
        try {
          const stepInterval = Duration(seconds: 10);
          Duration newPosition = player.position + stepInterval;
          if (newPosition < Duration.zero) newPosition = Duration.zero;
          if (newPosition > player.duration!) newPosition = player.duration!;
          await player.seek(newPosition);
        } catch (e, st) {
          NeomErrorLogger.recordErrorLight(
            e,
            st,
            module: 'neom_audio_player',
            operation: 'fastForward',
          );
        }
      case 'rewind':
        try {
          const stepInterval = Duration(
            seconds: AudioPlayerConstants.rewindSeconds,
          );
          Duration newPosition = player.position - stepInterval;
          if (newPosition < Duration.zero) newPosition = Duration.zero;
          if (newPosition > player.duration!) newPosition = player.duration!;
          await player.seek(newPosition);
        } catch (e, st) {
          NeomErrorLogger.recordErrorLight(
            e,
            st,
            module: 'neom_audio_player',
            operation: 'rewind',
          );
        }
      case 'refreshLink':
        if (extras?['newData'] != null) {
          await refreshLink(extras!['newData'] as Map);
        }
      case 'sleepTimer':
        _sleepTimer?.cancel();
        if (extras?['time'] != null &&
            extras!['time'].runtimeType == int &&
            extras['time'] > 0 as bool) {
          final minutes = extras['time'] as int;
          sleepTimerEndTime.value = DateTime.now().add(
            Duration(minutes: minutes),
          );
          _sleepTimer = Timer(Duration(minutes: minutes), () async {
            sleepTimerEndTime.value = null;
            await stop();
          });
        } else {
          sleepTimerEndTime.value = null;
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
  Timer? _mediaActionTimer;

  void _handleMediaActionPressed() async {
    if (_mediaActionTimer == null) {
      _tappedMediaActionNumber = rx.BehaviorSubject.seeded(1);
      _mediaActionTimer = Timer(const Duration(milliseconds: 800), () {
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
        _mediaActionTimer?.cancel();
        _mediaActionTimer = null;
      });
    } else {
      final current = _tappedMediaActionNumber.value;
      _tappedMediaActionNumber.add(current + 1);
    }
  }

  Future<void> setItemInMediaPlayers() async {
    // ROADMAP: integrate per-track Casete stopwatch tracking when item changes.
    AppConfig.logger.w('StopWatch started for item ${currentMediaItem?.title}');

    if (currentMediaItem != null && currentMediaItem?.title != 'null') {
      await AudioPlayerStats.addRecentlyPlayed(currentMediaItem!);
    }
  }

  Future<void> trackCaseteSession({bool isPeriodic = false}) async {
    AppConfig.logger.t("CASETE ALG: Tracking casete session.");

    final canPersist = AppConfig.instance.canPersistUserActivity;
    if (!canPersist) {
      neomStopwatch.reset();
      _currentCaseteSessionId = null;
      _casetePersistenceWasAllowed = false;
      AppConfig.logger.d(
        "CASETE ALG: Guest or unloaded user; session not persisted.",
      );
      return;
    }

    // The first tracking tick after guest → authenticated starts a fresh
    // window. Time accumulated while unauthenticated must never be attributed
    // to the newly signed-in account.
    if (!_casetePersistenceWasAllowed) {
      neomStopwatch.reset();
      _currentCaseteSessionId = null;
      _casetePersistenceWasAllowed = true;
      return;
    }

    // 1. Validación de Elegibilidad
    String itemId = currentMediaItem?.id ?? mediaItem.value?.id ?? '';
    if (itemId.isEmpty) return;

    bool isOwner =
        (userServiceImpl.user.email == itemId) ||
        (userServiceImpl.user.releaseItemIds?.contains(itemId) ?? false);

    if (isOwner || !isCaseteElegible) {
      AppConfig.logger.w(
        "CASETE ALG: Owner or not eligible. Session not saved.",
      );
      return;
    }

    int secondsListened = neomStopwatch.elapsed();
    AppConfig.logger.d(
      "CASETE ALG: Checking session. Listened: ${secondsListened}s",
    );

    // 1. Validación de Tiempo Mínimo (El "Tiempo Sensato")
    if (secondsListened < AudioPlayerConstants.minCaseteSeconds) {
      AppConfig.logger.w(
        "CASETE ALG: Audio listened less than ${AudioPlayerConstants.minCaseteSeconds}s. Not saved.",
      );
      return;
    }

    if (!isPeriodic) {
      neomStopwatch
          .reset(); // Solo resetear si es stop/skip para iniciar la siguiente cancion
    }

    String itemName = currentMediaItem?.title ?? mediaItem.value?.title ?? '';
    String ownerId =
        currentMediaItem?.extras?['ownerId'] ??
        mediaItem.value?.extras?['ownerId'] ??
        ''; //

    int createdTime = DateTime.now().millisecondsSinceEpoch;
    if (_currentCaseteSessionId == null) {
      _currentCaseteSessionId = '${itemId}_$createdTime';
    }
    String sessionId = _currentCaseteSessionId!;

    // 3. Creación de la Sesión
    CaseteSession caseteSession = CaseteSession(
      id: sessionId,
      createdTime: createdTime,
      itemId: itemId,
      itemName: itemName,
      ownerEmail: ownerId,
      listenerEmail: userServiceImpl.user.email, // Quien escucha
      casete: secondsListened, // VALOR REAL CALCULADO
      subscriptionLevel:
          userServiceImpl.subscriptionLevel, // Si lo tienes disponible
      isTest:
          kDebugMode || userServiceImpl.user.userRole != UserRole.subscriber,
    );

    try {
      // 4. Guardado en Firestore
      await Sint.find<CaseteSessionRepository>().insert(
        caseteSession,
        isOwner: isOwner,
      );
      AppConfig.logger.i(
        "CASETE ALG: Session saved! $secondsListened seconds for $itemName",
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_audio_player',
        operation: 'trackCaseteSession',
      );
    }

    if (!isPeriodic) {
      _currentCaseteSessionId = null;
    }
  }

  Timer? _freeTrialTimer;

  void startCaseteBeaconTimer() {
    // No-op. Session is persisted at natural session boundaries (pause/skip/stop/completion).
  }

  Future<void> startFreeTrialTimer() async {
    if (_freeTrialTimer?.isActive ?? false) return;

    _freeTrialTimer = Timer.periodic(
      const Duration(seconds: AudioPlayerConstants.minCaseteSeconds),
      (Timer timer) async {
        if (!player.playing) return;

        final access = await _authorizePlayback(
          PlaybackRequestOrigin.trialTimer,
        );
        if (access.reason == PlaybackAccessReason.activeTrial &&
            player.playing) {
          CaseteTrialUsageManager().increaseDailyTrialUsage(
            AudioPlayerConstants.minCaseteSeconds,
          );
        }
      },
    );
    AppConfig.logger.d(
      'Free trial timer is active: ${_freeTrialTimer?.isActive}',
    );
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
