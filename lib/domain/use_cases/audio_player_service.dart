import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';


abstract class AudioPlayerService {

  void initReleaseItem(AppReleaseItem item);
  void initAppMediaItem(AppMediaItem item);
  void clear();
  Future<void> getItemPlaylist();
  void gotoPlaylistPlayer();
  void setMediaItem({MediaItem? item, AppMediaItem? appItem});
  void updateMediaItemValues();
  void toggleLyricsCard();
  void setFlipped(bool value);
  Future<void> sharePopUp();
  void goToTimeline(BuildContext context);
  Future<void> fetchLyrics();
  void goToOwnerProfile();
  bool isOffline();
  void setIsLoadingAudio(bool loading);

}
