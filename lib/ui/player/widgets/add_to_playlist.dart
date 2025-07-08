import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_commons/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/message_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/itemlist_service.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class AddToPlaylist {

  Future<bool> addToPlaylist(BuildContext context, AppMediaItem appMediaItem, {List<Itemlist>? playlists, bool fromSearch = false, bool goHome = true}) async {

    List<Itemlist> itemlists = []; ///GET INFO FROM CONTROLLER
    ProfileType type = ProfileType.general; ///GET INFO FROM CONTROLLER
    ItemlistService itemlistServiceImpl;

    try {
      itemlistServiceImpl = Get.find<ItemlistService>();

      itemlists = CoreUtilities.filterItemlists(itemlistServiceImpl.getItemlists(), ItemlistType.playlist);
      itemlists.removeWhere((element) => !element.isModifiable);

      if(itemlists.isEmpty) {
        itemlists.add(await itemlistServiceImpl.createBasicItemlist());
      }

      itemlistServiceImpl.setSelectedItemlist(itemlists.first.id);
      type = Get.find<UserController>().profile.type;
      itemlistServiceImpl.setAppMediaItem(appMediaItem);

      itemlists.length > 1 ? Alert(
        context: context,
        style: AlertStyle(
          backgroundColor: AppColor.main75,
          titleStyle: const TextStyle(color: Colors.white),
        ),
        title: type == ProfileType.appArtist ? AppTranslationConstants.appItemPrefs.tr
            : AppTranslationConstants.playlistToChoose.tr,
        content: Column(
          children: <Widget>[
            if(type == ProfileType.appArtist) Obx(()=>
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
                                full: AppUtilities.ratingImage(AppAssets.heart),
                                half: AppUtilities.ratingImage(AppAssets.heartHalf),
                                empty: AppUtilities.ratingImage(AppAssets.heartBorder),
                              ),
                              itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
                              itemSize: 12,
                              onRatingUpdate: (rating) {
                                AppConfig.logger.i('New Rating set to $rating');
                              },
                            ),
                          ],
                        ),
                    );
                  }).toList(),
                  onChanged: (String? newState) {
                    itemlistServiceImpl.setAppItemState(EnumToString.fromString(AppItemState.values, newState!) ?? AppItemState.noState);
                  },
                  value: CoreUtilities.getItemState(itemlistServiceImpl.getItemState()).name,
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
                itemlistServiceImpl.setSelectedItemlist(selectedItemlist!);
              },
              value: itemlistServiceImpl.getSelectedItemlist(),
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
            child: Obx(()=> itemlistServiceImpl.checkIsLoading() ? const Center(child: CircularProgressIndicator())
                : Text(AppTranslationConstants.add.tr,
            ),),
            onPressed: () async => {
              if(type == ProfileType.appArtist)
                itemlistServiceImpl.getItemState() > 0
                    ? await itemlistServiceImpl.addItemlistItem(context, goHome: goHome)
                    : AppUtilities.showSnackBar(
                      title: AppTranslationConstants.appItemPrefs.tr,
                      message: MessageTranslationConstants.selectItemStateMsg.tr
                    )
              else
                await itemlistServiceImpl.addItemlistItem(context, fanItemState: AppItemState.heardIt.value, goHome: goHome),
            },
          ),
        ],
      ).show() : await itemlistServiceImpl.addItemlistItem(context, fanItemState: AppItemState.heardIt.value, goHome: goHome);

    } catch(e) {
      AppConfig.logger.e(e.toString());
      return false;
    }
    return true;
  }

}
