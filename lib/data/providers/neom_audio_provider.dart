import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:neom_core/app_properties.dart';
import '../../neom_audio_handler.dart';

class NeomAudioProvider {

  static final NeomAudioProvider _instance = NeomAudioProvider._internal();
  factory NeomAudioProvider() => _instance;
  NeomAudioProvider._internal();

  static bool _isInitialized = false;
  static NeomAudioHandler? audioHandler;

  Future<NeomAudioHandler> getAudioHandler() async {
    if (!_isInitialized) {
      await _initialize();
      if(audioHandler == null) {
        throw Exception("Failed to initialize NeomAudioHandler");
      }
    }
    return audioHandler!;
  }

  Future<void> _initialize() async {
    audioHandler = await AudioService.init(
      builder: () => NeomAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: AppProperties.getNotificationChannelId(),
        androidNotificationChannelName: AppProperties.getNotificationChannelName(),
        androidNotificationIcon: AppProperties.getNotificationIcon(),
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
        notificationColor: Colors.grey[900],
      ),
    );

    _isInitialized = true;
  }

}
