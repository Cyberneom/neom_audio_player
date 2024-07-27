import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';

import '../../../utils/constants/player_translation_constants.dart';
import 'widgets/music_playback_settings_page.dart';
import 'widgets/music_player_interface_page.dart';
import 'widgets/others.dart';

class MusicPlayerSettingsPage extends StatefulWidget {
  final Function? callback;
  const MusicPlayerSettingsPage({super.key, this.callback});

  @override
  State<MusicPlayerSettingsPage> createState() => _MusicPlayerSettingsPageState();
}

class _MusicPlayerSettingsPageState extends State<MusicPlayerSettingsPage> {
  final TextEditingController controller = TextEditingController();
  final ValueNotifier<String> searchQuery = ValueNotifier<String>('');

  @override
  void dispose() {
    controller.dispose();
    searchQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: AppColor.main50,
        resizeToAvoidBottomInset: false,

        appBar: AppBarChild(title: PlayerTranslationConstants.settings.tr,),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: Column(
            children: [
              ///APPLY WHEN MORE OPTIONS ARE ADDED
              // _searchBar(context),
              Expanded(child: _settingsItem(context)),
            ],
          ),
        )
    );
  }

  Widget _settingsItem(BuildContext context) {
    final List<Map<String, dynamic>> settingsList = [
      {
        'title': PlayerTranslationConstants.ui.tr,
        'icon': Icons.design_services_rounded,
        'onTap': MusicPlayerInterfacePage(
          callback: widget.callback,
        ),
        'isThreeLine': true,
        'items': [
          PlayerTranslationConstants.miniButtons.tr,
          PlayerTranslationConstants.changeOrder.tr,
          PlayerTranslationConstants.compactNotificationButtons.tr,
          PlayerTranslationConstants.showPlaylists.tr,
          PlayerTranslationConstants.showLast.tr,
          PlayerTranslationConstants.enableGesture.tr,
          PlayerTranslationConstants.useLessDataImage.tr,
        ],
      },
      {
        'title': PlayerTranslationConstants.musicPlayback.tr,
        'icon': Icons.music_note_rounded,
        'onTap': MusicPlaybackSettingsPage(
          callback: widget.callback,
        ),
        'isThreeLine': true,
        'items': [
          PlayerTranslationConstants.musicLang.tr,
          PlayerTranslationConstants.streamQuality.tr,
          PlayerTranslationConstants.chartLocation.tr,
          PlayerTranslationConstants.streamWifiQuality.tr,
          /// PlayerTranslationConstants.ytStreamQuality.tr,
          PlayerTranslationConstants.loadLast.tr,
          PlayerTranslationConstants.resetOnSkip.tr,
          PlayerTranslationConstants.enforceRepeat.tr,
          PlayerTranslationConstants.autoplay.tr,
          PlayerTranslationConstants.cacheMediaItem.tr,
        ],
      },
      ///DOWNLOAD IN PROGRESS
      // {
      //   'title': PlayerTranslationConstants.downloads.tr,
      //   'icon': Icons.download_done_rounded,
      //   'onTap': const DownloadSettingsPage(),
      //   'isThreeLine': true,
      //   'items': [
      //     PlayerTranslationConstants.downQuality.tr,
      //     PlayerTranslationConstants.downLocation.tr,
      //     PlayerTranslationConstants.downFilename.tr,
      //     PlayerTranslationConstants.ytDownQuality.tr,
      //     PlayerTranslationConstants.createAlbumFold.tr,
      //     PlayerTranslationConstants.createYtFold.tr,
      //   ],
      // },
      {
        'title': PlayerTranslationConstants.others.tr,
        'icon': Icons.miscellaneous_services_rounded,
        'onTap': const OthersPage(),
        'isThreeLine': true,
        'items': [
          PlayerTranslationConstants.getLyricsOnline.tr,
          PlayerTranslationConstants.stopOnClose.tr,
          PlayerTranslationConstants.clearCache.tr,
          // PlayerTranslationConstants.useDown.tr,
          // PlayerTranslationConstants.includeExcludeFolder.tr,
          // PlayerTranslationConstants.minAudioLen.tr,
          // PlayerTranslationConstants.supportEq.tr,
          // PlayerTranslationConstants.liveSearch.tr,
          // PlayerTranslationConstants.checkUpdate.tr,
          // PlayerTranslationConstants.shareLogs.tr,
        ],
      },
    ];

    final List<Map> searchOptions = [];
    for (final Map e in settingsList) {
      for (final item in e['items'] as List) {
        searchOptions.add({'title': item, 'route': e['onTap']});
      }
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
            vertical: 15.0,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: settingsList.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: SizedBox.square(
                dimension: 40,
                child: Icon(settingsList[index]['icon'] as IconData),
              ),
              title: Text(settingsList[index]['title'].toString()),
              subtitle: Text(
                (settingsList[index]['items'] as List).take(3).join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: (settingsList[index]['isThreeLine'] as bool? ?? false),
              onTap: () {
                searchQuery.value = '';
                controller.text = '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => settingsList[index]['onTap'] as Widget,
                  ),
                );
              },
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: searchQuery,
          builder: (BuildContext context, String query, Widget? child) {
            if (query != '') {
              final List<Map> results = _getSearchResults(searchOptions, query);
              return _searchSuggestions(context, results);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  ///APPLY WHEN MORE OPTIONS ARE ADDED
  // Widget _searchBar(BuildContext context) {
  //   return Card(
  //     color: AppTheme.canvasColor50(context),
  //     margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(10.0,),
  //     ),
  //     elevation: 2.0,
  //     child: SizedBox(
  //       height: 50.0,
  //       child: Center(
  //         child: ValueListenableBuilder(
  //           valueListenable: searchQuery,
  //           builder: (BuildContext context, String query, Widget? child) {
  //             return TextField(
  //               controller: controller,
  //               textAlignVertical: TextAlignVertical.center,
  //               decoration: InputDecoration(
  //                 focusedBorder: const UnderlineInputBorder(
  //                   borderSide: BorderSide(
  //                     width: 1.5,
  //                     color: Colors.transparent,
  //                   ),
  //                 ),
  //                 fillColor: Theme.of(context).colorScheme.secondary,
  //                 prefixIcon: const Icon(CupertinoIcons.search),
  //                 suffixIcon: query.trim() != ''
  //                     ? IconButton(
  //                         icon: const Icon(Icons.close_rounded),
  //                         onPressed: () {
  //                           controller.clear();
  //                           searchQuery.value = '';
  //                         },
  //                       )
  //                     : null,
  //                 border: InputBorder.none,
  //                 hintText: PlayerTranslationConstants.search.tr,
  //               ),
  //               keyboardType: TextInputType.text,
  //               textInputAction: TextInputAction.search,
  //               onChanged: (_) {
  //                 searchQuery.value = controller.text.trim();
  //               },
  //             );
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }

  List<Map> _getSearchResults(
    List<Map> searchOptions,
    String query,
  ) {
    final List<Map> options = query != ''
        ? searchOptions
            .where(
              (element) =>
                  element['title'].toString().toLowerCase().contains(query),
            )
            .toList()
        : List.empty();
    return options;
  }

  Widget _searchSuggestions(
    BuildContext context,
    List<Map> options,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 18.0,
        vertical: 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          10.0,
        ),
      ),
      elevation: 8.0,
      child: SizedBox(
        height: options.length * 70,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 10, top: 10),
          physics: const BouncingScrollPhysics(),
          itemCount: options.length,
          itemExtent: 70,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Text(options[index]['title'].toString()),
              onTap: () {
                searchQuery.value = '';
                controller.text = '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => options[index]['route'] as Widget,
                    settings: RouteSettings(
                      arguments: options[index]['title'],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
