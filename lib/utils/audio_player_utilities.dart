import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';
import 'package:neom_commons/neom_commons.dart';

import '../domain/use_cases/neom_audio_handler.dart';
import '../ui/widgets/textinput_dialog.dart';
import 'constants/audio_player_route_constants.dart';

class AudioPlayerUtilities {

  static List<Widget> getAudioPlayerPages() {
    return AudioPlayerRouteConstants.audioPlayerPages;
  }

  static bool isOwnMediaItem(AppMediaItem appMediaItem) {
    final bool isOwnMediaItem = appMediaItem.url.contains(AppFlavour.getHubName())
        || appMediaItem.url.contains(AppFlavour.getStorageServerName())
        || appMediaItem.mediaSource == AppMediaSource.internal;

    return isOwnMediaItem;
  }

  static void showSpeedSliderDialog({
    required BuildContext context,
    required String title,
    required int divisions,
    required double min,
    required double max,
    required NeomAudioHandler? audioHandler,
    String valueSuffix = '',
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.main75,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: StreamBuilder<double>(
          stream: audioHandler?.speed,
          builder: (context, snapshot) {
            double value = snapshot.data ?? audioHandler?.speed.value ?? 0;
            if (value > max) value = max;
            if (value < min) value = min;

            return SizedBox(
              height: 100.0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.minus),
                        onPressed: (audioHandler?.speed.value ?? 0) > min ? () {
                          audioHandler?.setSpeed(audioHandler.speed.value - 0.1);
                        } : null,
                      ),
                      Text(
                        '${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                        style: const TextStyle(
                          fontFamily: 'Fixed',
                          fontWeight: FontWeight.bold,
                          fontSize: 24.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.plus),
                        onPressed: (audioHandler?.speed.value ?? 0) < max ? () {
                          audioHandler?.setSpeed(audioHandler.speed.value + 0.1);
                        } : null,
                      ),
                    ],
                  ),
                  Slider(
                    inactiveColor: Theme.of(context).iconTheme.color!.withOpacity(0.4),
                    activeColor: Theme.of(context).iconTheme.color,
                    divisions: divisions,
                    min: min,
                    max: max,
                    value: value,
                    onChanged: audioHandler?.setSpeed,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static void showPopup({
    required BuildContext context,
    required Widget child,
    double radius = 20.0,
    Color? backColor,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          backgroundColor: AppColor.main75,
          content: Stack(
            children: [
              GestureDetector(onTap: () => Navigator.pop(context)),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Card(
                  elevation: 0.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  clipBehavior: Clip.antiAlias,
                  color: backColor,
                  child: child,
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Card(
                  elevation: 15.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Map<String, List<Itemlist>> categorizePlaylistsByTags(List<Itemlist> itemLists) {
    Map<String, List<Itemlist>> categorizedItems = {};

    for (var item in itemLists) {
      for (var tag in item.tags ?? []) {
        if (!categorizedItems.containsKey(tag)) {
          categorizedItems[tag] = [];
        }
        categorizedItems[tag]!.add(item);
      }
    }

    return categorizedItems;
  }

  static Map<String, List<AppReleaseItem>> categorizeReleaseItems(List<AppReleaseItem> releaseItems, {
        bool byTags = false,
        List<String> forbiddenList = const ['emxi lecturas', 'libro digital', 'libro físico']
      }) {
    final Map<String, List<AppReleaseItem>> categorizedItems = {};

    for (final item in releaseItems) {
      // Selecciona la lista de claves según el modo: tags o categorías
      final List<String> keys = byTags ? (item.tags ?? []) : (item.categories);
      for (final key in keys) {
        if (forbiddenList.contains(key.toLowerCase())) continue;
        categorizedItems.putIfAbsent(key, () => []);
        categorizedItems[key]!.add(item);
      }
    }

    return categorizedItems;
  }

}
