import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

import '../../../utils/constants/audio_player_translation_constants.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColor.main50,
        appBar: AppBarChild(title: AppTranslationConstants.stats.tr,),
        body: FutureBuilder(
          future: AppHiveController().openHiveBox(AppHiveBox.stats.name),
          builder: (BuildContext context, AsyncSnapshot<Box> snapshot,) {
            int songsPlayed = snapshot.data?.length ?? 0;

            Map mostPlayed = {};
            if(snapshot.data != null) {
              mostPlayed = snapshot.data?.get('mostPlayed', defaultValue: {}) as Map;
            }
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
                        Text(AudioPlayerTranslationConstants.mediaItemsPlayed.tr),
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
                        Text(AudioPlayerTranslationConstants.mostPlayedMediaItem.tr),
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
