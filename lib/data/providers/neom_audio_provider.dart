import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/core/app_flavour.dart';
import '../../domain/use_cases/neom_audio_handler.dart';

class NeomAudioProvider {

  static final NeomAudioProvider _instance = NeomAudioProvider._internal();

  factory NeomAudioProvider() {
    return _instance;
  }

  NeomAudioProvider._internal();

  static bool _isInitialized = false;
  static NeomAudioHandler? audioHandler;

  Future<void> _initialize() async {
    audioHandler = await AudioService.init(
      builder: () => NeomAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: AppFlavour.getNotificationChannelId(),
        androidNotificationChannelName: AppFlavour.getNotificationChannelName(),
        androidNotificationIcon: AppFlavour.getNotificationIcon(),
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false,
        notificationColor: Colors.grey[900],
      ),
    );
  }

  Future<NeomAudioHandler> getAudioHandler() async {
    if (!_isInitialized) {
      await _initialize();
      _isInitialized = true;
    }
    return audioHandler!;
  }

}
