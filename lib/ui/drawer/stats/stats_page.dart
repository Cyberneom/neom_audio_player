import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/data/implementations/app_hive_controller.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';

import 'package:neom_commons/core/utils/enums/app_hive_box.dart';import '../../../utils/constants/player_translation_constants.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {

    // Box songsPlayedBox = await AppHiveController().openHiveBox(AppHiveBox.stats.name);
    // int songsPlayed = await AppHiveController().openHiveBox(AppHiveBox.stats.name).length;
    // Map mostPlayed = Hive.box(AppHiveBox.stats.name).get('mostPlayed', defaultValue: {}) as Map;

    return Scaffold(
      backgroundColor: AppColor.main50,
        appBar: AppBarChild(title: PlayerTranslationConstants.stats.tr,),
        body: FutureBuilder(
          future: AppHiveController().openHiveBox(AppHiveBox.stats.name),
          builder: (BuildContext context, AsyncSnapshot<Box> snapshot,) {
            int songsPlayed = snapshot.data?.length ?? 0;
            Map mostPlayed = snapshot.data?.get('mostPlayed', defaultValue: {}) as Map;
            return Container(
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
                        Text(PlayerTranslationConstants.mediaItemsPlayed.tr),
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
                        Text(PlayerTranslationConstants.mostPlayedMediaItem.tr),
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
          );
          }),
    );
  }
}
