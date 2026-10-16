import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_core/app_properties.dart';
import '../../neom_audio_handler.dart';

class NeomAudioProvider {
  static final NeomAudioProvider _instance = NeomAudioProvider._internal();
  factory NeomAudioProvider() => _instance;
  NeomAudioProvider._internal();

  static bool _isInitialized = false;
  static Completer<void>? _initCompleter;
  static NeomAudioHandler? audioHandler;

  Future<NeomAudioHandler> getAudioHandler({
    bool restoreLastQueue = true,
  }) async {
    if (!_isInitialized) {
      if (_initCompleter == null) {
        _initCompleter = Completer<void>();
        try {
          await _initialize(restoreLastQueue: restoreLastQueue);
          _isInitialized = true;
          _initCompleter!.complete();
        } catch (e, st) {
          _initCompleter!.completeError(e, st);
          _initCompleter = null;
          rethrow;
        }
      } else {
        await _initCompleter!.future;
      }
      if (audioHandler == null) {
        throw Exception("Failed to initialize NeomAudioHandler");
      }
    }
    return audioHandler!;
  }

  Future<void> _initialize({required bool restoreLastQueue}) async {
    if (kIsWeb) {
      // On web, create the handler directly — AudioService.init() is
      // mobile-only (foreground service / notification).  The handler
      // itself (just_audio + BaseAudioHandler) works fine on web.
      audioHandler = NeomAudioHandler(restoreLastQueue: restoreLastQueue);
    } else {
      audioHandler = await AudioService.init(
        builder: () => NeomAudioHandler(restoreLastQueue: restoreLastQueue),
        config: AudioServiceConfig(
          androidNotificationChannelId:
              AppProperties.getNotificationChannelId(),
          androidNotificationChannelName:
              AppProperties.getNotificationChannelName(),
          androidNotificationIcon: AppProperties.getNotificationIcon(),
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: true,
          notificationColor: Colors.grey[900],
        ),
      );
    }

    if (audioHandler != null && !Sint.isRegistered<NeomAudioHandler>()) {
      Sint.put<NeomAudioHandler>(audioHandler!, permanent: true);
    }
  }
}
