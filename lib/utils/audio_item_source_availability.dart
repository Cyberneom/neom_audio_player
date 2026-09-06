import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/playable_item.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

/// Prefer the complete stream; legacy catalogues may only have a preview.
String audioItemSource(PlayableItem item) {
  final stream = item.streamUrl.trim();
  return stream.isNotEmpty ? stream : item.previewUrl.trim();
}

bool isRemoteAudioSource(String source) {
  final uri = Uri.tryParse(source.trim());
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

bool isAudioPlaybackItem(PlayableItem item) {
  if (item.isAudioContent) return true;
  if (item.mediaType != null || item.isBookContent) return false;
  final path = Uri.tryParse(audioItemSource(item))?.path.toLowerCase() ?? '';
  return const [
    '.mp3',
    '.wav',
    '.m4a',
    '.aac',
    '.ogg',
    '.flac',
  ].any(path.endsWith);
}

/// Whether a catalogue item is known to have no source for the player.
///
/// This UI check does not initialize playback or open personal storage. Native
/// playback may resolve a download by id, so leave that existing resolution
/// path intact when the download box has not been opened yet.
bool hasNoAudioSource(PlayableItem item) {
  final source = audioItemSource(item);
  if (kIsWeb) return !isRemoteAudioSource(source);
  if (source.isNotEmpty) return false;

  if (item is AppReleaseItem &&
      (item.previewUrl.trim().isNotEmpty ||
          (item.localPath?.trim().isNotEmpty ?? false))) {
    return false;
  }
  if (item is AppMediaItem && (item.path?.trim().isNotEmpty ?? false)) {
    return false;
  }

  // Guest playback cannot use personal downloads, and web has no local files.
  if (kIsWeb || !AppConfig.instance.canPersistUserActivity) return true;

  if (!Hive.isBoxOpen(AppHiveBox.downloads.name)) return false;
  final download = Hive.box(AppHiveBox.downloads.name).get(item.id);
  return download is! Map ||
      (download['path']?.toString().trim().isEmpty ?? true);
}
