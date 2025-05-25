import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../data/providers/neom_audio_provider.dart';
import '../domain/use_cases/neom_audio_handler.dart';

class NeomAudioUtilities {

  static Future<NeomAudioHandler?> getAudioHandler() async {
    NeomAudioHandler? audioHandler;

    try {
      if (!Get.isRegistered<NeomAudioHandler>()) {
        AppUtilities.logger.d("NeomAudioHandler not registered, getting and registering...");

        // Obtener la instancia del AudioHandler de forma asíncrona
        // Reemplaza NeomAudioProvider().getAudioHandler() con tu lógica real para obtener el handler
        audioHandler = await NeomAudioProvider().getAudioHandler();

        if (audioHandler != null) {
          // Registrar la instancia obtenida como un singleton en GetX
          Get.put<NeomAudioHandler>(audioHandler);
          AppUtilities.logger.i("NeomAudioHandler registered successfully with GetX.");
        } else {
          AppUtilities.logger.w("AudioHandler returned null from provider, cannot register.");
        }
      } else {
        AppUtilities.logger.d("NeomAudioHandler is already registered with GetX.");
        audioHandler = Get.find<NeomAudioHandler>();
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return audioHandler;
  }

  static int? getQueueIndex(AudioPlayer player, int? currentIndex) {
    final effectiveIndices = player.effectiveIndices;
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
