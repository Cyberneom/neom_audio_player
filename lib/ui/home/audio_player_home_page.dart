import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/ui/widgets/right_side_company_logo.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/utils/enums/subscription_status.dart';

import '../../utils/constants/audio_player_translation_constants.dart';
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
        builder: (controller) {
          return SafeArea(
            child: Scaffold(
              drawer: const AudioPlayerDrawer(),
              backgroundColor: AppFlavour.getBackgroundColor(),
              body: Container(
                decoration: AppTheme.appBoxDecoration,
                child: Obx(()=> controller.isLoading.value ? const AppCircularProgressIndicator() : Stack(
                  children: [
                    NestedScrollView(
                      physics: const BouncingScrollPhysics(),
                      controller: controller.scrollController,
                      headerSliverBuilder: (BuildContext context, bool innerBoxScrolled,) {
                        return [
                          SliverAppBar(
                            leading: audioPlayerHomeDrawer(context: context,),
                            title: Text(
                              (controller.userServiceImpl.userSubscription?.status == SubscriptionStatus.active)
                                  ? CommonTranslationConstants.activeSubscription.tr : '',
                              style: TextStyle(
                                color: Colors.white.withAlpha(204),
                                fontWeight: FontWeight.bold,
                                fontSize: 18
                              ),
                            ),
                            actions: const [RightSideCompanyLogo()],
                            backgroundColor: AppColor.getMain(),
                            elevation: 10,
                            toolbarHeight: 45,
                          ),
                          SliverAppBar(
                            leading: controller.showSearchBarLeading.value ? audioPlayerHomeDrawer(context: context,) : null,
                            automaticallyImplyLeading: false,
                            pinned: true,
                            backgroundColor: AppColor.getMain(),
                            elevation: 0,
                            toolbarHeight: 45,
                            title: Align(
                              alignment: Alignment.centerRight,
                              child: AnimatedBuilder(
                                animation: controller.scrollController,
                                builder: (context, child) {
                                  return GestureDetector(
                                    child: AnimatedContainer(
                                      width: (!controller.scrollController.hasClients || controller.scrollController.positions.length > 1)
                                          ? MediaQuery.of(context).size.width
                                          : max(MediaQuery.of(context).size.width - controller.scrollController.offset.roundToDouble(),
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
                                          Icon(Icons.search,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                          const SizedBox(width: 10.0,),
                                          Text(
                                            AudioPlayerTranslationConstants.searchText.tr,
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
