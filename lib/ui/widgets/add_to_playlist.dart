import 'package:flutter/material.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_itemlists/itemlists/ui/search/app_media_item_search_controller.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:get/get.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';

class AddToPlaylist {
  // Box settingsBox = Hive.box(AppHiveConstants.settings);
  // List playlistNames = Hive.box(AppHiveConstants.settings).get('playlistNames', defaultValue: [AppHiveConstants.favoriteSongs]) as List;
  // Map playlistDetails = Hive.box(AppHiveConstants.settings).get('playlistDetails', defaultValue: {}) as Map;

  Future<void> addToPlaylist(BuildContext context, AppMediaItem appMediaItem, {fromSearch = false}) async {

    List<Itemlist> itemlists = []; ///GET INFO FROM CONTROLLER
    ProfileType type = ProfileType.fan; ///GET INFO FROM CONTROLLER
    AppMediaItemSearchController searchController;
    try {
      // Check if the controller is active
      if (Get.isRegistered<AppMediaItemSearchController>()) {
        searchController = Get.find<AppMediaItemSearchController>();
      } else {
        searchController = Get.put(AppMediaItemSearchController());
      }
      itemlists = searchController.profile.itemlists!.values.toList();
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
        title: type == ProfileType.instrumentist ? AppTranslationConstants.appItemPrefs.tr
            : AppTranslationConstants.playlistToChoose.tr,
        content: Column(
          children: <Widget>[
            if (type == ProfileType.instrumentist) Obx(()=>
                DropdownButton<String>(
                  items: AppItemState.values.map((AppItemState itemState) {
                    return DropdownMenuItem<String>(
                        value: itemState.name,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(itemState.name.tr),
                            itemState.value == 0 ? Container() : const Text(" - "),
                            if (itemState.value == 0) Container() else RatingBar(
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
                                AppUtilities.logger.i("New Rating set to $rating");
                              },
                            ),
                          ],
                        )
                    );
                  }).toList(),
                  onChanged: (String? newState) {
                    searchController.setAppItemState(EnumToString.fromString(AppItemState.values, newState!) ?? AppItemState.noState);
                  },
                  value: CoreUtilities.getItemState(searchController.appItemState).name,
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
            ) else Container(),
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
              value: searchController.itemlistId,
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
                        : itemlists.first.name, style: TextStyle(fontSize: 15,))
                ),
              ],
            ),
          ],
        ),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            child: Obx(()=>searchController.isLoading ? const Center(child: CircularProgressIndicator())
                : Text(AppTranslationConstants.add.tr,
            )),
            onPressed: () async => {
              if (type == ProfileType.instrumentist) searchController.appItemState > 0 ? await searchController.addItemlistItem(context, fanItemState: searchController.appItemState)
                  : Get.snackbar(AppTranslationConstants.appItemPrefs.tr,
                  MessageTranslationConstants.selectItemStateMsg.tr,
                  snackPosition: SnackPosition.bottom
              ) else await searchController.addItemlistItem(context, fanItemState: AppItemState.heardIt.value)
            },
          )
        ],
      ).show() : await searchController.addItemlistItem(context,
        fanItemState: AppItemState.heardIt.value,);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

  }
}
