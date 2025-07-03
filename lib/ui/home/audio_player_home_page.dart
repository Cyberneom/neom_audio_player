import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/commons/ui/widgets/right_side_company_logo.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/core/utils/enums/subscription_status.dart';

import 'package:neom_media_player/utils/constants/player_translation_constants.dart';
import '../drawer/audio_player_drawer.dart';
import '../widgets/audio_player_widgets.dart';
import 'audio_player_home_controller.dart';
import 'widgets/audio_player_home_content.dart';
import 'widgets/search_page.dart';

class AudioPlayerHomePage extends StatelessWidget {

  const AudioPlayerHomePage({super.key,});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AudioPlayerHomeController>(
        id: AppPageIdConstants.audioPlayerHome,
        init: AudioPlayerHomeController(),
        builder: (_) {
          return SafeArea(
            child: Scaffold(
              drawer: const AudioPlayerDrawer(),
              backgroundColor: AppColor.main50,
              body: Container(
                decoration: AppTheme.appBoxDecoration75,
                child: Obx(()=> _.isLoading.value ? const AppCircularProgressIndicator() : Stack(
                  children: [
                    NestedScrollView(
                      physics: const BouncingScrollPhysics(),
                      controller: _.scrollController,
                      headerSliverBuilder: (BuildContext context, bool innerBoxScrolled,) {
                        return [
                          SliverAppBar(
                            leading: homeDrawer(context: context,),
                            title: Text(
                              (_.userController.userSubscription?.status == SubscriptionStatus.active)
                                  ? AppTranslationConstants.activeSubscription.tr : '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                                fontSize: 18
                              ),
                            ),
                            actions: const [RightSideCompanyLogo()],
                            backgroundColor: AppColor.main75,
                            elevation: 10,
                            toolbarHeight: 45,
                          ),
                          SliverAppBar(
                            leading: _.showSearchBarLeading.value ? homeDrawer(context: context,) : null,
                            automaticallyImplyLeading: false,
                            pinned: true,
                            backgroundColor: AppColor.main75,
                            elevation: 0,
                            toolbarHeight: 45,
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
                                    onTap: () => Navigator.push(context,
                                      MaterialPageRoute(
                                        builder: (context) => const SearchPage(
                                          fromHome: true, autofocus: true,),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ];
                      },
                      body: const AudioPlayerHomeContent(),
                    ),
                  ],),),
              ),
            ),
          );
        },
    );
  }
}
