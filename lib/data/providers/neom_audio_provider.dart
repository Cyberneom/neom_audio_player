import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';

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
        androidNotificationChannelId: 'com.gigmeout.letsgig.channel.audio',
        androidNotificationChannelName: 'Gigmeout',
        androidNotificationIcon: 'drawable/ic_stat_music_note',
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