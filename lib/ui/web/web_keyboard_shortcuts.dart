import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sint/sint.dart';

import '../../neom_audio_handler.dart';
import '../player/miniplayer_controller.dart';
import '../../data/implementations/playlist_hive_controller.dart';
import '../../utils/mappers/media_item_mapper.dart';

// ─── Intents ───
class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class SkipNextIntent extends Intent {
  const SkipNextIntent();
}

class SkipPreviousIntent extends Intent {
  const SkipPreviousIntent();
}

class VolumeUpIntent extends Intent {
  const VolumeUpIntent();
}

class VolumeDownIntent extends Intent {
  const VolumeDownIntent();
}

class ToggleLikeIntent extends Intent {
  const ToggleLikeIntent();
}

class ToggleQueueIntent extends Intent {
  const ToggleQueueIntent();
}

// ─── Shortcut map ───
final Map<ShortcutActivator, Intent> webKeyboardShortcuts = {
  const SingleActivator(LogicalKeyboardKey.space): const PlayPauseIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): const SkipNextIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): const SkipPreviousIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowUp, control: true): const VolumeUpIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowDown, control: true): const VolumeDownIntent(),
  const SingleActivator(LogicalKeyboardKey.keyL): const ToggleLikeIntent(),
  const SingleActivator(LogicalKeyboardKey.keyQ): const ToggleQueueIntent(),
};

// ─── Actions ───
Map<Type, Action<Intent>> buildWebKeyboardActions({
  required VoidCallback onToggleQueue,
}) {
  return {
    PlayPauseIntent: CallbackAction<PlayPauseIntent>(
      onInvoke: (_) {
        final handler = Sint.find<NeomAudioHandler>();
        if (handler.playbackState.value.playing) {
          handler.pause();
        } else {
          handler.play();
        }
        return null;
      },
    ),
    SkipNextIntent: CallbackAction<SkipNextIntent>(
      onInvoke: (_) {
        Sint.find<NeomAudioHandler>().skipToNext();
        return null;
      },
    ),
    SkipPreviousIntent: CallbackAction<SkipPreviousIntent>(
      onInvoke: (_) {
        Sint.find<NeomAudioHandler>().skipToPrevious();
        return null;
      },
    ),
    VolumeUpIntent: CallbackAction<VolumeUpIntent>(
      onInvoke: (_) {
        final handler = Sint.find<NeomAudioHandler>();
        final current = handler.player.volume;
        handler.setVolume((current + 0.1).clamp(0.0, 1.0));
        return null;
      },
    ),
    VolumeDownIntent: CallbackAction<VolumeDownIntent>(
      onInvoke: (_) {
        final handler = Sint.find<NeomAudioHandler>();
        final current = handler.player.volume;
        handler.setVolume((current - 0.1).clamp(0.0, 1.0));
        return null;
      },
    ),
    ToggleLikeIntent: CallbackAction<ToggleLikeIntent>(
      onInvoke: (_) {
        final controller = Sint.find<MiniPlayerController>();
        final mediaItem = controller.mediaItem.value;
        if (mediaItem != null) {
          PlaylistHiveController().addMapToPlaylist(
            'favoriteItems',
            MediaItemMapper.toJSON(mediaItem),
          );
        }
        return null;
      },
    ),
    ToggleQueueIntent: CallbackAction<ToggleQueueIntent>(
      onInvoke: (_) {
        onToggleQueue();
        return null;
      },
    ),
  };
}
