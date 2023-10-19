import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';

class Stats extends StatelessWidget {
  const Stats({super.key});

  int get songsPlayed => Hive.box(AppHiveConstants.stats).length;
  Map get mostPlayed =>
      Hive.box(AppHiveConstants.stats).get('mostPlayed', defaultValue: {}) as Map;

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        appBar: AppBar(
          title: Text(PlayerTranslationConstants.stats.tr),
          centerTitle: true,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        backgroundColor: AppColor.main50,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            children: [
              Card(
                color: AppColor.getMain(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    10.0,
                  ),
                ),
                elevation: 10.0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        songsPlayed.toString(),
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(PlayerTranslationConstants.songsPlayed.tr),
                    ],
                  ),
                ),
              ),
              Card(
                color: AppColor.getMain(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    10.0,
                  ),
                ),
                elevation: 10.0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(PlayerTranslationConstants.mostPlayedSong.tr),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        mostPlayed['title']?.toString() ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
