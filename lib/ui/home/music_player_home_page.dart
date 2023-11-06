import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';

import '../../to_delete/music_player_drawer.dart';
import '../../to_delete/search/search_page.dart';
import '../../utils/constants/player_translation_constants.dart';
import '../widgets/music_player_widgets.dart';
import 'music_player_home_content.dart';
import 'music_player_home_controller.dart';

class MusicPlayerHomePage extends StatelessWidget {

  const MusicPlayerHomePage({super.key,});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MusicPlayerHomeController>(
        id: AppPageIdConstants.musicPlayerHome,
        init: MusicPlayerHomeController(),
        builder: (_) {
          return Scaffold(
            drawer: MusicPlayerDrawer(),
            backgroundColor: AppColor.main50,
            body: Container(
              decoration: AppTheme.appBoxDecoration,
              child: Stack(
                children: [
                  NestedScrollView(
                    physics: const BouncingScrollPhysics(),
                    controller: _.scrollController,
                    headerSliverBuilder: (BuildContext context,
                        bool innerBoxScrolled,) {
                      return [
                        SliverAppBar(
                          leading: homeDrawer(context: context,),
                          actions: [
                            GestureDetector(
                                child: Container(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Image.asset(
                                    AppAssets.logoCompanyWhite,
                                    height: 50,
                                    width: 120,
                                  ),
                                ),
                                onTap: () async {
                                  AppUtilities.showAlert(context, message: "${AppTranslationConstants.version.tr} "
                                      "${AppFlavour.appVersion}${kDebugMode ? " - Dev Mode" : ""}");
                                }
                            )
                          ],
                          backgroundColor: AppColor.main75,
                          elevation: 10,
                          toolbarHeight: 55,
                        ),
                        SliverAppBar(
                          leading: _.showSearchBarLeading.value ? homeDrawer(context: context,) : null,
                          automaticallyImplyLeading: false,
                          pinned: true,
                          backgroundColor: AppColor.main75,
                          elevation: 0,
                          toolbarHeight: 55,
                          title: Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedBuilder(
                              animation: _.scrollController,
                              builder: (context, child) {
                                return GestureDetector(
                                  child: AnimatedContainer(
                                    width: (!_.scrollController.hasClients || _.scrollController.positions.length > 1)
                                        ? MediaQuery.of(context).size.width
                                        : max(MediaQuery.of(context).size.width - _.scrollController.offset.roundToDouble(),
                                      MediaQuery.of(context).size.width - (55),
                                    ),
                                    height: 55.0,
                                    duration: const Duration(milliseconds: 500,),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                        Icon(CupertinoIcons.search,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 10.0,),
                                        Text(
                                          PlayerTranslationConstants.searchText.tr,
                                          style: TextStyle(fontSize: 16.0,
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
                ],),
            ),
          );
        },
    );
  }
}
