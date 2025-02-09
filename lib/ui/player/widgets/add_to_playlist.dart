import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';
import 'package:neom_itemlists/itemlists/ui/search/app_media_item_search_controller.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class AddToPlaylist {
  // Box settingsBox = Hive.box(AppHiveBox.settings.name);
  // List playlistNames = Hive.box(AppHiveBox.settings.name).get('playlistNames', defaultValue: [AppHiveBox.favoriteItems.name]) as List;
  // Map playlistDetails = Hive.box(AppHiveBox.settings.name).get('playlistDetails', defaultValue: {}) as Map;

  Future<void> addToPlaylist(BuildContext context, AppMediaItem appMediaItem, {bool fromSearch = false, bool goHome = true}) async {

    List<Itemlist> itemlists = []; ///GET INFO FROM CONTROLLER
    ProfileType type = ProfileType.general; ///GET INFO FROM CONTROLLER
    AppMediaItemSearchController searchController;

    try {
      // Check if the controller is active
      if (Get.isRegistered<AppMediaItemSearchController>()) {
        searchController = Get.find<AppMediaItemSearchController>();
      } else {
        searchController = Get.put(AppMediaItemSearchController());
      }
      itemlists = searchController.itemlists.values.toList();
      itemlists.removeWhere((element) => !element.isModifiable);

      if(itemlists.isEmpty) return;
      searchController.setSelectedItemlist(itemlists.first.id);
      type = searchController.profile.type;
      searchController.appMediaItem = appMediaItem;

      itemlists.length > 1 ? Alert(
        context: context,
        style: AlertStyle(
          backgroundColor: AppColor.main75,
          titleStyle: const TextStyle(color: Colors.white),
        ),
        title: type == ProfileType.artist ? AppTranslationConstants.appItemPrefs.tr
            : AppTranslationConstants.playlistToChoose.tr,
        content: Column(
          children: <Widget>[
            if(type == ProfileType.artist) Obx(()=>
                DropdownButton<String>(
                  items: AppItemState.values.map((AppItemState itemState) {
                    return DropdownMenuItem<String>(
                        value: itemState.name,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(itemState.name.tr),
                            if(itemState.value != 0) const Text(' - '),
                            if (itemState.value == 0) const SizedBox.shrink() else RatingBar(
                              initialRating: itemState.value.toDouble(),
                              minRating: 1,
                              ignoreGestures: true,
                              direction: Axis.horizontal,
                              allowHalfRating: false,
                              itemCount: 5,
                              ratingWidget: RatingWidget(
                                full: CoreUtilities.ratingImage(AppAssets.heart),
                                half: CoreUtilities.ratingImage(AppAssets.heartHalf),
                                empty: CoreUtilities.ratingImage(AppAssets.heartBorder),
                              ),
                              itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
                              itemSize: 12,
                              onRatingUpdate: (rating) {
                                AppUtilities.logger.i('New Rating set to $rating');
                              },
                            ),
                          ],
                        ),
                    );
                  }).toList(),
                  onChanged: (String? newState) {
                    searchController.setAppItemState(EnumToString.fromString(AppItemState.values, newState!) ?? AppItemState.noState);
                  },
                  value: CoreUtilities.getItemState(searchController.appItemState.value).name,
                  alignment: Alignment.center,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 20,
                  elevation: 16,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: AppColor.getMain(),
                  underline: Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                ),
            ) else const SizedBox.shrink(),
            if (itemlists.length > 1) Obx(()=> DropdownButton<String>(
              items: itemlists.map((itemlist) =>
                  DropdownMenuItem<String>(
                    value: itemlist.id,
                    child: Center(
                      child: Text(
                        itemlist.name.length > AppConstants.maxItemlistNameLength
                            ? '${itemlist.name.substring(0,AppConstants.maxItemlistNameLength)}...'
                            : itemlist.name,
                      ),
                    ),
                  ),
              ).toList(),
              onChanged: (String? selectedItemlist) {
                searchController.setSelectedItemlist(selectedItemlist!);
              },
              value: searchController.itemlistId.value,
              icon: const Icon(Icons.arrow_downward),
              alignment: Alignment.center,
              iconSize: 20,
              elevation: 16,
              style: const TextStyle(color: Colors.white),
              dropdownColor: AppColor.main75,
              underline: Container(
                height: 1,
                color: Colors.grey,
              ),),
            ) else Column(
              children: [
                AppTheme.heightSpace10,
                Center(
                    child: Text(itemlists.first.name.length > AppConstants.maxItemlistNameLength
                        ? '${itemlists.first.name.substring(0,AppConstants.maxItemlistNameLength)}...'
                        : itemlists.first.name, style: const TextStyle(fontSize: 15,),),
                ),
              ],
            ),
          ],
        ),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            child: Obx(()=> searchController.isLoading.value ? const Center(child: CircularProgressIndicator())
                : Text(AppTranslationConstants.add.tr,
            ),),
            onPressed: () async => {
              if(type == ProfileType.artist)
                searchController.appItemState > 0
                    ? await searchController.addItemlistItem(context, fanItemState: searchController.appItemState.value, goHome: goHome)
                    : AppUtilities.showSnackBar(
                      title: AppTranslationConstants.appItemPrefs.tr,
                      message: MessageTranslationConstants.selectItemStateMsg.tr
                    )
              else
                await searchController.addItemlistItem(context, fanItemState: AppItemState.heardIt.value, goHome: goHome),
            },
          ),
        ],
      ).show() : await searchController.addItemlistItem(context, fanItemState: AppItemState.heardIt.value, goHome: goHome);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

  }

}
