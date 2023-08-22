import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_music_player/ui/drawer/music_player_drawer.dart';
import 'package:neom_music_player/ui/home/music_player_home_content.dart';
import 'package:neom_music_player/ui/home/music_player_home_controller.dart';
import 'package:neom_music_player/ui/widgets/drawer.dart';
import 'package:neom_music_player/ui/Search/search_page.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:get/get.dart';

class MusicPlayerHomePage extends StatefulWidget {
  const MusicPlayerHomePage({
    super.key,
  });

  @override
  State<MusicPlayerHomePage> createState() => _MusicPlayerHomePageState();
}

class _MusicPlayerHomePageState extends State<MusicPlayerHomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool rotated = MediaQuery.of(context).size.height < screenWidth;
    return GetBuilder<MusicPlayerHomeController>(
        id: "musicPlayerHome",
        builder: (_) {
          return Container(
            decoration: AppTheme.appBoxDecoration,
            child: Stack(
            children: [
              NestedScrollView(
                physics: const BouncingScrollPhysics(),
                controller: _scrollController,
                headerSliverBuilder: (BuildContext context,
                    bool innerBoxScrolled,) {
                  return <Widget>[
                    SliverAppBar(
                      expandedHeight: 35,
                      backgroundColor: AppColor.main75,
                      elevation: 10,
                      toolbarHeight: 70,
                      automaticallyImplyLeading: false,
                      flexibleSpace: LayoutBuilder(
                        builder: (BuildContext context,
                            BoxConstraints constraints,) {
                          return FlexibleSpaceBar(
                            // collapseMode: CollapseMode.parallax,
                            background: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  child: Image.asset(
                                    AppAssets.logoCompanyWhite,
                                    height: 70,
                                    width: 150,
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      pinned: true,
                      backgroundColor: AppColor.main75,
                      elevation: 0,
                      stretch: true,
                      toolbarHeight: 65,
                      title: Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedBuilder(
                          animation: _scrollController,
                          builder: (context, child) {
                            return GestureDetector(
                              child: AnimatedContainer(
                                width: (!_scrollController.hasClients || _scrollController.positions.length > 1)
                                    ? MediaQuery.of(context).size.width : max(MediaQuery.of(context).size.width -
                                    _scrollController.offset.roundToDouble(),
                                  MediaQuery.of(context).size.width - (rotated ? 0 : 75),),
                                height: 55.0,
                                duration: const Duration(milliseconds: 150,),
                                padding: const EdgeInsets.all(2.0),
                                // margin: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0,),
                                  color: AppColor.main75,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 5.0,
                                      offset: Offset(1.5, 1.5),
                                      // shadow direction: bottom right
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 10.0,),
                                    Icon(CupertinoIcons.search,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 10.0,),
                                    Text(
                                      PlayerTranslationConstants.searchText.tr,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Theme.of(context).textTheme.bodySmall!.color,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () =>
                                  Navigator.push(context,
                                    MaterialPageRoute(
                                      builder: (context) => const SearchPage(
                                        query: '', fromHome: true, autofocus: true,
                                      ),
                                    ),
                                  ),
                            );
                          },
                        ),
                      ),
                    ),
                  ];
                },
                body: MusicPlayerHomeContent(),
              ),
              if (!rotated)
                homeDrawer(
                  context: context,
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                )
            ],),
          );
        });
  }
}
