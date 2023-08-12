import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/ui/widgets/drawer.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/drawer/settings/about.dart';
import 'package:neom_music_player/ui/drawer/settings/app_ui.dart';
import 'package:neom_music_player/ui/drawer/settings/download.dart';
import 'package:neom_music_player/ui/drawer/settings/music_playback.dart';
import 'package:neom_music_player/ui/drawer/settings/others.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';

class NewSettingsPage extends StatefulWidget {
  final Function? callback;
  const NewSettingsPage({this.callback});

  @override
  State<NewSettingsPage> createState() => _NewSettingsPageState();
}

class _NewSettingsPageState extends State<NewSettingsPage>
    with AutomaticKeepAliveClientMixin<NewSettingsPage> {
  final TextEditingController controller = TextEditingController();
  final ValueNotifier<String> searchQuery = ValueNotifier<String>('');
  final List sectionsToShow = Hive.box(AppHiveConstants.settings).get(
    'sectionsToShow',
    defaultValue: ['Home', 'Top Charts', 'YouTube', 'Library'],
  ) as List;

  @override
  void dispose() {
    controller.dispose();
    searchQuery.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => sectionsToShow.contains('Settings');

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GradientContainer(
      child: Scaffold(
        backgroundColor: AppColor.main75,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColor.main75,
          centerTitle: true,
          leading: sectionsToShow.contains('Settings')
              ? homeDrawer(
                  context: context,
                  padding: const EdgeInsets.only(left: 15.0),
                )
              : null,
          title: Text(
            PlayerTranslationConstants.settings.tr,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).iconTheme.color,
          ),
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
                          onPressed: () {
                            controller.clear();
                            searchQuery.value = '';
                          },
                          icon: const Icon(Icons.close_rounded),
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
        'onTap': AppUIPage(
          callback: widget.callback,
        ),
        'isThreeLine': true,
        'items': [
          PlayerTranslationConstants.playerScreenBackground.tr,
          PlayerTranslationConstants.miniButtons.tr,
          // PlayerTranslationConstants.useDenseMini.tr,
          PlayerTranslationConstants.blacklistedHomeSections.tr,
          PlayerTranslationConstants.changeOrder.tr,
          PlayerTranslationConstants.compactNotificationButtons.tr,
          PlayerTranslationConstants.showPlaylists.tr,
          PlayerTranslationConstants.showLast.tr,
          PlayerTranslationConstants.navTabs.tr,
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
          PlayerTranslationConstants.downLyrics.tr,
        ]
      },
      {
        'title': PlayerTranslationConstants.others.tr,
        'icon': Icons.miscellaneous_services_rounded,
        'onTap': const OthersPage(),
        'isThreeLine': true,
        'items': [
          PlayerTranslationConstants.lang.tr,
          PlayerTranslationConstants.includeExcludeFolder.tr,
          PlayerTranslationConstants.minAudioLen.tr,
          PlayerTranslationConstants.liveSearch.tr,
          PlayerTranslationConstants.useDown.tr,
          PlayerTranslationConstants.getLyricsOnline.tr,
          PlayerTranslationConstants.supportEq.tr,
          PlayerTranslationConstants.stopOnClose.tr,
          PlayerTranslationConstants.checkUpdate.tr,
          PlayerTranslationConstants.useProxy.tr,
          PlayerTranslationConstants.proxySet.tr,
          PlayerTranslationConstants.clearCache.tr,
          PlayerTranslationConstants.shareLogs.tr,
        ]
      },
      {
        'title': PlayerTranslationConstants.about.tr,
        'icon': Icons.info_outline_rounded,
        'onTap': const AboutPage(),
        'isThreeLine': false,
        'items': [
          PlayerTranslationConstants.version.tr,
          PlayerTranslationConstants.shareApp.tr,
          PlayerTranslationConstants.contactUs.tr,
          PlayerTranslationConstants.likedWork.tr,
          PlayerTranslationConstants.donateGpay.tr,
          PlayerTranslationConstants.joinTg.tr,
          PlayerTranslationConstants.moreInfo.tr,
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
