import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import '../../../neom_player_invoker.dart';
import '../../widgets/empty_screen.dart';
import '../../widgets/gradient_containers.dart';
import '../../widgets/image_card.dart';
import '../../widgets/like_button.dart';
import '../../../utils/constants/app_hive_constants.dart';
import '../../../utils/constants/music_player_route_constants.dart';
import '../../../utils/constants/player_translation_constants.dart';

class RecentlyPlayed extends StatefulWidget {
  @override
  _RecentlyPlayedState createState() => _RecentlyPlayedState();
}

class _RecentlyPlayedState extends State<RecentlyPlayed> {
  Map<String, AppMediaItem> _songs = {};
  bool added = false;

  Future<void> getSongs() async {
    List recentSongs = await Hive.box(AppHiveConstants.cache).get('recentSongs', defaultValue: []) as List;
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

    return GradientContainer(
      child: Scaffold(
        backgroundColor: AppColor.main75,
        appBar: AppBar(
          title: Text(PlayerTranslationConstants.lastSession.tr),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                Hive.box(AppHiveConstants.cache).put('recentSongs', []);
                setState(() {
                  _songs = {};
                });
              },
              tooltip: PlayerTranslationConstants.clearAll.tr,
              icon: const Icon(Icons.clear_all_rounded),
            ),
          ],
        ),
        body: _songs.isEmpty
            ? TextButton(onPressed: ()=>Navigator.pushNamed(context, MusicPlayerRouteConstants.home),
            child: emptyScreen(
                context, 3,
                PlayerTranslationConstants.nothingTo.tr, 15,
                PlayerTranslationConstants.showHere.tr, 50.0,
                PlayerTranslationConstants.playSomething.tr, 23.0,
              ),
        ) : ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          shrinkWrap: true,
          itemCount: _songs.length,
          itemExtent: 70.0,
          itemBuilder: (context, index) {
            final AppMediaItem item = _songs.values.elementAt(index);
            return _songs.isEmpty
                ? const SizedBox()
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
                Hive.box(AppHiveConstants.cache).put('recentSongs', _songs);
                },
              child: ListTile(
                leading: imageCard(imageUrl: item.imgUrl,),
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
                  NeomPlayerInvoker.init(
                    appMediaItems: _songs.values.toList(),
                    index: index,
                  );
                  },
              ),
            );
            },
        ),
      ),
    );
  }
}