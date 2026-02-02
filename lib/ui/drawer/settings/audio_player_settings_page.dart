import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

import '../../../utils/constants/audio_player_translation_constants.dart';
import 'widgets/music_playback_settings_page.dart';
import 'widgets/music_player_interface_page.dart';
import 'widgets/others.dart';

class AudioPlayerSettingsPage extends StatefulWidget {
  final Function? callback;
  const AudioPlayerSettingsPage({super.key, this.callback});

  @override
  State<AudioPlayerSettingsPage> createState() => _AudioPlayerSettingsPageState();
}

class _AudioPlayerSettingsPageState extends State<AudioPlayerSettingsPage> {
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
        backgroundColor: AppFlavour.getBackgroundColor(),
        resizeToAvoidBottomInset: false,
        appBar: AppBarChild(title: AppTranslationConstants.settings.tr,),
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
        'title': AudioPlayerTranslationConstants.ui.tr,
        'icon': Icons.design_services_rounded,
        'onTap': MusicPlayerInterfacePage(
          callback: widget.callback,
        ),
        'isThreeLine': true,
        'items': [
          AudioPlayerTranslationConstants.miniButtons.tr,
          AudioPlayerTranslationConstants.changeOrder.tr,
          AudioPlayerTranslationConstants.compactNotificationButtons.tr,
          AudioPlayerTranslationConstants.showPlaylists.tr,
          AudioPlayerTranslationConstants.showLast.tr,
          AudioPlayerTranslationConstants.enableGesture.tr,
          AudioPlayerTranslationConstants.useLessDataImage.tr,
        ],
      },
      {
        'title': AudioPlayerTranslationConstants.musicPlayback.tr,
        'icon': Icons.music_note_rounded,
        'onTap': MusicPlaybackSettingsPage(
          callback: widget.callback,
        ),
        'isThreeLine': true,
        'items': [
          // AudioPlayerTranslationConstants.musicLang.tr,
          AudioPlayerTranslationConstants.streamQuality.tr,
          // AudioPlayerTranslationConstants.chartLocation.tr,
          AudioPlayerTranslationConstants.streamWifiQuality.tr,
          /// AudioPlayerTranslationConstants.ytStreamQuality.tr,
          AudioPlayerTranslationConstants.loadLast.tr,
          AudioPlayerTranslationConstants.resetOnSkip.tr,
          AudioPlayerTranslationConstants.enforceRepeat.tr,
          // AudioPlayerTranslationConstants.autoplay.tr,
          AudioPlayerTranslationConstants.cacheMediaItem.tr,
        ],
      },
      ///DOWNLOAD IN PROGRESS
      // {
      //   'title': AudioPlayerTranslationConstants.downloads.tr,
      //   'icon': Icons.download_done_rounded,
      //   'onTap': const DownloadSettingsPage(),
      //   'isThreeLine': true,
      //   'items': [
      //     AudioPlayerTranslationConstants.downQuality.tr,
      //     AudioPlayerTranslationConstants.downLocation.tr,
      //     AudioPlayerTranslationConstants.downFilename.tr,
      //     AudioPlayerTranslationConstants.ytDownQuality.tr,
      //     AudioPlayerTranslationConstants.createAlbumFold.tr,
      //     AudioPlayerTranslationConstants.createYtFold.tr,
      //   ],
      // },
      {
        'title': AppTranslationConstants.others.tr.capitalize,
        'icon': Icons.miscellaneous_services_rounded,
        'onTap': const OthersPage(),
        'isThreeLine': true,
        'items': AppConfig.instance.appInUse == AppInUse.g ? [
          AudioPlayerTranslationConstants.getLyricsOnline.tr,
          AudioPlayerTranslationConstants.stopOnClose.tr,
          AudioPlayerTranslationConstants.clearCache.tr,
          // AudioPlayerTranslationConstants.useDown.tr,
          // AudioPlayerTranslationConstants.includeExcludeFolder.tr,
          // AudioPlayerTranslationConstants.minAudioLen.tr,
          // AudioPlayerTranslationConstants.supportEq.tr,
          // AudioPlayerTranslationConstants.checkUpdate.tr,
          // AudioPlayerTranslationConstants.shareLogs.tr,
        ] : [ AudioPlayerTranslationConstants.stopOnClose.tr,
          AudioPlayerTranslationConstants.clearCache.tr,
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
  //                 prefixIcon: const Icon(Icons.search),
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
  //                 hintText: AudioPlayerTranslationConstants.search.tr,
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
