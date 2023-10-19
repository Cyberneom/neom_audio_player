import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/data/implementations/spotify_hive_controller.dart';
import 'package:neom_music_player/ui/drawer/music_player_drawer.dart';
import 'package:neom_music_player/ui/spotify/top_page.dart';
import 'package:neom_music_player/ui/widgets/custom_physics.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
// import 'package:neom_music_player/utils/helpers/countrycodes.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';


class SpotifyTopPage extends StatefulWidget {
  final PageController pageController;
  const SpotifyTopPage({super.key, required this.pageController});

  @override
  _SpotifyTopPageState createState() => _SpotifyTopPageState();
}

class _SpotifyTopPageState extends State<SpotifyTopPage>
    with AutomaticKeepAliveClientMixin<SpotifyTopPage> {
  final ValueNotifier<bool> localFetchFinished = ValueNotifier<bool>(false);

  @override
  bool get wantKeepAlive => true;

  SpotifyHiveController spotifyHiveController = Get.put(SpotifyHiveController());

  @override
  Widget build(BuildContext cntxt) {
    super.build(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isRotated = MediaQuery.of(context).size.height < screenWidth;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColor.main75,
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: const Icon(Icons.my_location_rounded),
                onPressed: () async {
                  await spotifyHiveController.changeCountry(context: context);
                  setState(() {});
                },
              ),
            ),
          ],
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(
                child: Text(PlayerTranslationConstants.local.tr,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),
              Tab(
                child: Text(PlayerTranslationConstants.global.tr,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),
            ],
          ),
          title: Text(PlayerTranslationConstants.spotifyCharts.tr,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColor.main75,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: isRotated ? null : homeDrawer(context: context),
        ),
        body: NotificationListener(
          onNotification: (overscroll) {
            if (overscroll is OverscrollNotification &&
                overscroll.overscroll != 0 &&
                overscroll.dragDetails != null) {
              widget.pageController.animateToPage(
                overscroll.overscroll < 0 ? 0 : 2,
                curve: Curves.ease,
                duration: const Duration(milliseconds: 150),
              );
            }
            return true;
          },
          child: TabBarView(
            physics: const CustomPhysics(),
            children: [
              ValueListenableBuilder(
                valueListenable: Hive.box(AppHiveConstants.settings).listenable(),
                builder: (BuildContext context, Box box, Widget? widget) {
                  return TopPage(
                    type: box.get('region', defaultValue: 'Mexico').toString(),
                  );
                },
              ),
              const TopPage(type: 'Global'),
            ],
          ),
        ),
      ),
    );
  }
}
