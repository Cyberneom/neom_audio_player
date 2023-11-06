import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/implementations/spotify_hive_controller.dart';
import '../../utils/constants/app_hive_constants.dart';
import '../../utils/constants/player_translation_constants.dart';
import '../widgets/empty_screen.dart';
import '../widgets/image_card.dart';

class TopPage extends StatefulWidget {
  final String type;
  const TopPage({super.key, required this.type});
  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage>
    with AutomaticKeepAliveClientMixin<TopPage> {

  SpotifyHiveController spotifyHiveController = Get.put(SpotifyHiveController());

  Future<void> getCachedData(String type) async {
    spotifyHiveController.getCachedData(type);
    setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getCachedData(widget.type);
    spotifyHiveController.scrapData(widget.type);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isGlobal = widget.type == 'Global';
    if ((isGlobal && !spotifyHiveController.globalFetched) || (!isGlobal && !spotifyHiveController.localFetched)) {
      getCachedData(widget.type);
      spotifyHiveController.scrapData(widget.type);
      setState(() {});
    }
    return ValueListenableBuilder(
      valueListenable: isGlobal ? spotifyHiveController.globalFetchFinished : spotifyHiveController.localFetchFinished,
      builder: (BuildContext context, bool value, Widget? child) {
        final List showList = isGlobal ? spotifyHiveController.globalSongs : spotifyHiveController.localSongs;
        return Column(
          children: [
            if (!(Hive.box(AppHiveConstants.settings).get('spotifySigned', defaultValue: false)
                as bool))
              Expanded(
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      spotifyHiveController.scrapData(widget.type, signIn: true);
                    },
                    child: Text(PlayerTranslationConstants.signInSpotify.tr),
                  ),
                ),
              )
            else if (showList.isEmpty)
              Expanded(
                child: value
                    ? emptyScreen(
                        context, 0,
                        ':( ', 100,
                        'ERROR', 60,
                        'Service Unavailable', 20,
                      ) : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                        ],
                      ),
              )
            else
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: showList.length,
                  itemExtent: 70.0,
                  itemBuilder: (context, index) {
                    AppMediaItem appMediaItem = AppMediaItem(
                      name: showList[index]['name'].toString(),
                      imgUrl: showList[index]['image_url_small'].toString(),
                      artist: showList[index]['artist'].toString(),
                      permaUrl: showList[index]['spotifyUrl'].toString(),
                    );
                    return ListTile(
                      leading: imageCard(
                        imageUrl: appMediaItem.imgUrl,
                      ),
                      title: Text(
                        '${index + 1}. ${appMediaItem.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(appMediaItem.artist,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton(
                        color: AppColor.getMain(),
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(15.0),
                          ),
                        ),
                        onSelected: (int? value) async {
                          if (value == 0) {
                            await launchUrl(
                              Uri.parse(appMediaItem.permaUrl),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 0,
                            child: Row(
                              children: [
                                const Icon(Icons.open_in_new_rounded),
                                const SizedBox(width: 10.0),
                                Text(
                                  PlayerTranslationConstants.openInSpotify.tr,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        await launchUrl(
                            Uri.parse(appMediaItem.permaUrl),
                            mode: LaunchMode.externalApplication,
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
