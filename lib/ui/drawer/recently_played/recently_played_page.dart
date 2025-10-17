import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/images/neom_image_card.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

import '../../../audio_player_invoker.dart';
import '../../../utils/constants/audio_player_route_constants.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../widgets/empty_screen.dart';
import '../../widgets/like_button.dart';

class RecentlyPlayedPage extends StatefulWidget {
  const RecentlyPlayedPage({super.key});

  @override
  RecentlyPlayedPageState createState() => RecentlyPlayedPageState();
}

class RecentlyPlayedPageState extends State<RecentlyPlayedPage> {
  Map<String, AppMediaItem> _songs = {};
  bool added = false;

  Future<void> getSongs() async {
    List recentSongs = await Hive.box(AppHiveBox.player.name).get('recentSongs', defaultValue: []) as List;
    if(recentSongs.isNotEmpty) {
      for (final element in recentSongs) {
        AppMediaItem recentMediaItem = AppMediaItem.fromJSON(element);
        _songs[recentMediaItem.id] = recentMediaItem;
      }
    }
    added = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!added) {
      getSongs();
    }

    return Scaffold(
        backgroundColor: AppColor.main50,
        appBar: AppBarChild(
          title: CommonTranslationConstants.lastSession.tr,
          actionWidgets: [
            IconButton(
              onPressed: () {
                Hive.box(AppHiveBox.player.name).put('recentSongs', []);
                setState(() {
                  _songs = {};
                });
              },
              tooltip: AudioPlayerTranslationConstants.clearAll.tr,
              icon: const Icon(Icons.clear_all_rounded),
            ),
          ],
        ),
        body: _songs.isEmpty ? TextButton(
          child: emptyScreen(
            context, 3,
            AudioPlayerTranslationConstants.nothingTo.tr, 16,
            AudioPlayerTranslationConstants.showHere.tr, 45.0,
            AudioPlayerTranslationConstants.playSomething.tr, 26.0,
          ),
          onPressed: ()=> Navigator.pushNamed(context, AudioPlayerRouteConstants.home),
        ) : ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          shrinkWrap: true,
          itemCount: _songs.length,
          itemExtent: 70.0,
          itemBuilder: (context, index) {
            final AppMediaItem item = _songs.values.elementAt(index);
            return _songs.isEmpty
                ? const SizedBox.shrink()
                : Dismissible(
              key: Key(item.id),
              direction: DismissDirection.endToStart,
              background: const ColoredBox(
                color: Colors.redAccent,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.0,),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.delete_outline_rounded),
                    ],
                  ),
                ),
              ),
              onDismissed: (direction) {
                _songs.remove(item.id);
                setState(() {});
                Hive.box(AppHiveBox.player.name).put(AppHiveConstants.recentSongs, _songs);
                },
              child: ListTile(
                leading: NeomImageCard(imageUrl: item.imgUrl,),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ///DEPRECATED
                    // DownloadButton(
                    //   data: _songs[index] as Map,
                    //   icon: 'download',
                    // ),
                    LikeButton(appMediaItem: item,),
                  ],
                ),
                title: Text(item.name,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(item.artist,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Get.find<AudioPlayerInvoker>().init(
                    appMediaItems: _songs.values.toList(),
                    index: index,
                  );
                  },
              ),
            );
            },

      ),
    );
  }
}
