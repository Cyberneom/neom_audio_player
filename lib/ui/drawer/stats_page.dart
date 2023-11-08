import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';

import '../../utils/constants/app_hive_constants.dart';
import '../../utils/constants/player_translation_constants.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  int get songsPlayed => Hive.box(AppHiveConstants.stats).length;
  Map get mostPlayed => Hive.box(AppHiveConstants.stats).get('mostPlayed', defaultValue: {}) as Map;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.main50,
        appBar: AppBarChild(title: PlayerTranslationConstants.stats.tr,),
        body: Container(
          decoration: AppTheme.boxDecoration,
          width: AppTheme.fullWidth(context),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Card(
                color: AppColor.getMain(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0,),
                ),
                elevation: 10.0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(songsPlayed.toString(),
                        style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold,
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
        )
    );
  }
}
