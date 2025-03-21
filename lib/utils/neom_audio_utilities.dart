import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../data/providers/neom_audio_provider.dart';
import '../domain/use_cases/neom_audio_handler.dart';

class NeomAudioUtilities {

  static Future<NeomAudioHandler?> getAudioHandler() async {
    NeomAudioHandler? audioHandler;

    try {
      if (!GetIt.I.isRegistered<NeomAudioHandler>()) {
        if(await registerAudioHandler()) {
          audioHandler = GetIt.I.get<NeomAudioHandler>();
        } else {
          AppUtilities.logger.w("AudioHandler not registered");
        }
      } else {
        audioHandler = GetIt.I.get<NeomAudioHandler>();
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return audioHandler;
  }

  static Future<bool> registerAudioHandler() async {
    AppUtilities.logger.d("registerAudioHandler");

    try {
      final NeomAudioHandler audioHandler = await NeomAudioProvider().getAudioHandler();
      GetIt.I.registerSingleton<NeomAudioHandler>(audioHandler);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }
    return true;
  }

  static int? getQueueIndex(AudioPlayer player, int? currentIndex) {
    final effectiveIndices = player.effectiveIndices ?? [];
    final shuffleIndicesInv = List.filled(effectiveIndices.length, 0);
    for (var i = 0; i < effectiveIndices.length; i++) {
      shuffleIndicesInv[effectiveIndices[i]] = i;
    }
    return (player.shuffleModeEnabled &&
        ((currentIndex ?? 0) < shuffleIndicesInv.length))
        ? shuffleIndicesInv[currentIndex ?? 0]
        : currentIndex;
  }

  static const Set<MediaAction> mediaActions = {MediaAction.seek,MediaAction.seekForward,MediaAction.seekBackward};

  static List<AppMediaItem> sortSongs(List<AppMediaItem> appMediaItems, {required int sortVal, required int order}) {
    switch (sortVal) {
      case 0:
        appMediaItems.sort((a, b) => a.name.toUpperCase().compareTo(b.name.toUpperCase()),);
      case 1:
        appMediaItems.sort((a, b) => a.releaseDate.toString().toUpperCase()
              .compareTo(b.releaseDate.toString().toUpperCase()),);
      case 2:
        appMediaItems.sort((a, b) => a.album.toUpperCase().compareTo(b.album.toUpperCase()),);
      case 3:
        appMediaItems.sort((a, b) => a.artist.toUpperCase().compareTo(b.artist.toUpperCase()),);
      case 4:
        appMediaItems.sort((a, b) => a.duration.toString().toUpperCase().compareTo(b.duration.toString().toUpperCase()),);
      default:
        appMediaItems.sort((b, a) => a.releaseDate.toString().toUpperCase().compareTo(b.releaseDate.toString().toUpperCase()),);
        break;
    }

    if (order == 1) {
      appMediaItems = appMediaItems.reversed.toList();
    }

    return appMediaItems;
  }

}
