import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_itemlists/itemlists/ui/widgets/app_item_widgets.dart';

import 'package:neom_media_player/utils/constants/player_translation_constants.dart';
import '../../home/widgets/search_page.dart';
import '../../widgets/empty_screen.dart';
import '../../widgets/playlist_head.dart';
import '../playlist_player_page.dart';

class SongsPageTab extends StatelessWidget {

  final List<AppMediaItem> appMediaItems;
  final String playlistName;
  final Function(AppMediaItem item) onDelete;
  final ScrollController scrollController;

  const SongsPageTab({
    super.key,
    required this.appMediaItems,
    required this.onDelete,
    required this.playlistName,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {    
    return Container(child: appMediaItems.isEmpty
      ? TextButton(
      onPressed: ()=> Navigator.push(context, MaterialPageRoute(
          builder: (context) => const SearchPage(fromHome: true, autofocus: true,),
        ),
      ),
      child: emptyScreen(context, 3,
        PlayerTranslationConstants.nothingTo.tr, 15.0,
        PlayerTranslationConstants.showHere.tr, 50,
        PlayerTranslationConstants.addSomething.tr, 23.0,),)
        : Column(
      children: [
        PlaylistHead(songsList: appMediaItems,),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 10),
            shrinkWrap: true,
            itemCount: appMediaItems.length,
            itemExtent: 70.0,
            itemBuilder: (context, index) {
              AppMediaItem item = appMediaItems[index];
              return ValueListenableBuilder(
                valueListenable: selectMode,
                builder: (context, value, child) {
                  return createCoolMediaItemTile(context, item,);
                },
              );
            },
          ),
        ),
      ],
    ),
    );
  }

}
