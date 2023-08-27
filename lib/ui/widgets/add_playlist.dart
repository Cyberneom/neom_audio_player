import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_itemlists/itemlists/ui/search/app_media_item_search_controller.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_music_player/data/implementations/playlist_hive_controller.dart';
import 'package:neom_music_player/utils/helpers/media_item_mapper.dart';
import 'package:neom_music_player/ui/widgets/collage.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/ui/widgets/textinput_dialog.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/helpers/audio_query.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:get/get.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';
import 'package:neom_itemlists/itemlists/ui/app_media_item/app_media_item_controller.dart';
import 'package:neom_music_player/ui/player/media_player_page.dart';
import 'package:neom_music_player/ui/widgets/copy_clipboard.dart';
import 'package:neom_music_player/ui/widgets/download_button.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/widgets/like_button.dart';
import 'package:neom_music_player/ui/widgets/song_tile_trailing_menu.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddToOffPlaylist {
  OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();

  Future<void> addToOffPlaylist(BuildContext context, int audioId) async {
    List<PlaylistModel> playlistDetails =
        await offlineAudioQuery.getPlaylists();
    showModalBottomSheet(
      isDismissible: true,
      backgroundColor: AppColor.main75,
      context: context,
      builder: (BuildContext context) {
        return BottomGradientContainer(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(PlayerTranslationConstants.createPlaylist.tr),
                  leading: Card(
                    elevation: 0,
                    color: Colors.transparent,
                    child: SizedBox.square(
                      dimension: 50,
                      child: Center(
                        child: Icon(
                          Icons.add_rounded,
                          color: null,
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    showTextInputDialog(
                      context: context,
                      keyboardType: TextInputType.text,
                      title: PlayerTranslationConstants.createNewPlaylist.tr.tr,
                      onSubmitted: (String value, BuildContext context) async {
                        await offlineAudioQuery.createPlaylist(name: value);
                        playlistDetails =
                            await offlineAudioQuery.getPlaylists();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                if (playlistDetails.isEmpty)
                  const SizedBox()
                else
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: playlistDetails.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Card(
                          margin: EdgeInsets.zero,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: QueryArtworkWidget(
                            id: playlistDetails[index].id,
                            type: ArtworkType.PLAYLIST,
                            keepOldArtwork: true,
                            artworkBorder: BorderRadius.circular(7.0),
                            nullArtworkWidget: ClipRRect(
                              borderRadius: BorderRadius.circular(7.0),
                              child: const Image(
                                fit: BoxFit.cover,
                                height: 50.0,
                                width: 50.0,
                                image: AssetImage(AppAssets.musicPlayerCover),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          playlistDetails[index].playlist,
                        ),
                        subtitle: Text(
                          '${playlistDetails[index].numOfSongs} Songs',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          offlineAudioQuery.addToPlaylist(
                            playlistId: playlistDetails[index].id,
                            audioId: audioId,
                          );
                          ShowSnackBar().showSnackBar(
                            context,
                            '${PlayerTranslationConstants.addedTo.tr} ${playlistDetails[index].playlist}',
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
                            itemState.value == 0 ? Container() :
                            RatingBar(
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
