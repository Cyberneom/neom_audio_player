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

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/ui/player/audioplayer.dart';

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