import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_music_player/to_delete/search/search_page.dart';
import 'package:neom_music_player/ui/drawer/music_player_drawer.dart';
import 'package:neom_music_player/ui/home/music_player_home_content.dart';
import 'package:neom_music_player/ui/home/music_player_home_controller.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';

class MusicPlayerHomePage extends StatelessWidget {

  const MusicPlayerHomePage({super.key,});

  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool rotated = MediaQuery.of(context).size.height < screenWidth;
    return GetBuilder<MusicPlayerHomeController>(
        id: AppPageIdConstants.musicPlayerHome,
        init: MusicPlayerHomeController(),
        builder: (_) {
          return Container(
            decoration: AppTheme.appBoxDecoration,
            child: Stack(
            children: [
              NestedScrollView(
                physics: const BouncingScrollPhysics(),
                controller: _.scrollController,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Image.asset(
                                    AppAssets.logoCompanyWhite,
                                    height: 70,
                                    width: 150,
                                  ),
                                ),
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
                          animation: _.scrollController,
                          builder: (context, child) {
                            return GestureDetector(
                              child: AnimatedContainer(
                                width: (!_.scrollController.hasClients || _.scrollController.positions.length > 1)
                                    ? MediaQuery.of(context).size.width : max(MediaQuery.of(context).size.width -
                                    _.scrollController.offset.roundToDouble(),
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
                                    ),
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
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => const SearchPage(
                                      query: '', fromHome: true, autofocus: true,
                                    ),
                                  ),),
                            );
                          },
                        ),
                      ),
                    ),
                  ];
                },
                body: Obx(()=> _.isLoading.value ? Container() : MusicPlayerHomeContent()),
              ),
              if (!rotated)
                homeDrawer(
                  context: context,
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                ),
            ],),
          );
        },);
  }
}
