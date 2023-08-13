import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_music_player/ui/drawer/settings/widgets/music_playback.dart';
import 'package:neom_music_player/ui/drawer/settings/widgets/music_player_interface_page.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/drawer/settings/widgets/download.dart';
import 'package:neom_music_player/ui/drawer/settings/widgets/others.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';

class MusicPlayerSettingsPage extends StatefulWidget {
  final Function? callback;
  const MusicPlayerSettingsPage({this.callback});

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

    return GradientContainer(
      child: Scaffold(
        backgroundColor: AppColor.main75,
        resizeToAvoidBottomInset: false,

        appBar: AppBar(
          title: Text(
            PlayerTranslationConstants.settings.tr,
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            _searchBar(context),
            Expanded(child: _settingsItem(context)),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return Card(
      color: AppTheme.canvasColor50(context),
      margin: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          10.0,
        ),
      ),
      elevation: 2.0,
      child: SizedBox(
        height: 55.0,
        child: Center(
          child: ValueListenableBuilder(
            valueListenable: searchQuery,
            builder: (BuildContext context, String query, Widget? child) {
              return TextField(
                controller: controller,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      width: 1.5,
                      color: Colors.transparent,
                    ),
                  ),
                  fillColor: Theme.of(context).colorScheme.secondary,
                  prefixIcon: const Icon(CupertinoIcons.search),
                  suffixIcon: query.trim() != ''
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            controller.clear();
                            searchQuery.value = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  hintText: PlayerTranslationConstants.search.tr,
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                onChanged: (_) {
                  searchQuery.value = controller.text.trim();
                },
              );
            },
          ),
        ),
      ),
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
        ]
      },
      {
        'title': PlayerTranslationConstants.musicPlayback.tr,
        'icon': Icons.music_note_rounded,
        'onTap': MusicPlaybackPage(
          callback: widget.callback,
        ),
        'isThreeLine': true,
        'items': [
          PlayerTranslationConstants.musicLang.tr,
          PlayerTranslationConstants.streamQuality.tr,
          PlayerTranslationConstants.chartLocation.tr,
          PlayerTranslationConstants.streamWifiQuality.tr,
          PlayerTranslationConstants.ytStreamQuality.tr,
          PlayerTranslationConstants.loadLast.tr,
          PlayerTranslationConstants.resetOnSkip.tr,
          PlayerTranslationConstants.enforceRepeat.tr,
          PlayerTranslationConstants.autoplay.tr,
          PlayerTranslationConstants.cacheSong.tr,
        ]
      },
      {
        'title': PlayerTranslationConstants.down.tr,
        'icon': Icons.download_done_rounded,
        'onTap': const DownloadPage(),
        'isThreeLine': true,
        'items': [
          PlayerTranslationConstants.downQuality.tr,
          PlayerTranslationConstants.downLocation.tr,
          PlayerTranslationConstants.downFilename.tr,
          PlayerTranslationConstants.ytDownQuality.tr,
          PlayerTranslationConstants.createAlbumFold.tr,
          PlayerTranslationConstants.createYtFold.tr,
        ]
      },
      {
        'title': PlayerTranslationConstants.others.tr,
        'icon': Icons.miscellaneous_services_rounded,
        'onTap': const OthersPage(),
        'isThreeLine': true,
        'items': [
          PlayerTranslationConstants.includeExcludeFolder.tr,
          PlayerTranslationConstants.minAudioLen.tr,
          PlayerTranslationConstants.liveSearch.tr,
          PlayerTranslationConstants.useDown.tr,
          PlayerTranslationConstants.getLyricsOnline.tr,
          PlayerTranslationConstants.supportEq.tr,
          PlayerTranslationConstants.stopOnClose.tr,
          PlayerTranslationConstants.checkUpdate.tr,
          PlayerTranslationConstants.clearCache.tr,
          PlayerTranslationConstants.shareLogs.tr,
        ]
      },
    ];

    final List<Map> searchOptions = [];
    for (final Map e in settingsList) {
      for (final item in e['items'] as List) {
        searchOptions.add({'title': item, 'route': e['onTap']});
      }
    }

    final bool isRotated =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
              isThreeLine: !isRotated &&
                  (settingsList[index]['isThreeLine'] as bool? ?? false),
              onTap: () {
                searchQuery.value = '';
                controller.text = '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        settingsList[index]['onTap'] as Widget,
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
            return const SizedBox();
          },
        ),
      ],
    );
  }

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
