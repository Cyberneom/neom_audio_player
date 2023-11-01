import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/user_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/itemlist_owner.dart';
import 'package:neom_commons/core/utils/enums/spotify_search_type.dart';
import 'package:neom_music_player/data/api_services/spotify/spotify_api_calls.dart';
import 'package:spotify/spotify.dart' as spotify;

class SpotifyInternalController extends GetxController {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  Itemlist currentItemlist = Itemlist();

  final RxMap<String, Itemlist> _spotifyItemlists = <String, Itemlist>{}.obs;
  Map<String, Itemlist> get spotifyItemlists => _spotifyItemlists;
  set spotifyItemlists(Map<String, Itemlist> spotifyItemlists) => _spotifyItemlists.value = spotifyItemlists;

  final RxList<spotify.Playlist> _spotifyPlaylists = <spotify.Playlist>[].obs;
  List<spotify.Playlist> get spotifyPlaylists => _spotifyPlaylists;
  set spotifyPlaylists(List<spotify.Playlist> spotifyPlaylists) => _spotifyPlaylists.value = spotifyPlaylists;

  final RxList<spotify.PlaylistSimple> _spotifyPlaylistSimples = <spotify.PlaylistSimple>[].obs;
  List<spotify.PlaylistSimple> get spotifyPlaylistSimples => _spotifyPlaylistSimples;
  set spotifyPlaylistSimples(List<spotify.PlaylistSimple> spotifyPlaylistSimples) => _spotifyPlaylistSimples.value = spotifyPlaylistSimples;

  AppProfile profile = AppProfile();

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  TextEditingController newItemlistNameController = TextEditingController();
  TextEditingController newItemlistDescController = TextEditingController();

  bool outOfSync = false;
  bool spotifyAvailable = true;

  RxString itemName = ''.obs;
  RxInt itemNumber = 0.obs;
  int totalItemsToSynch = 0;

  @override
  Future<void> onInit() async {
    super.onInit();
    logger.d('');

    try {
      profile = userController.profile;
      userController.itemlistOwner = ItemlistOwner.profile;
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  Future<void> onReady() async {
    super.onReady();
    try {
      if(AppFlavour.appInUse == AppInUse.g && !Platform.isIOS) {
        await getSpotifyToken();
        if (userController.user!.spotifyToken.isNotEmpty
            && userController.profile.lastSpotifySync < DateTime
                .now().subtract(const Duration(days: 30))
                .millisecondsSinceEpoch
        ) {
          logger.d('Spotify Last Sync was more than 30 days');
          outOfSync = true;
        } else {
          logger.i('Spotify Last Sync in scope');
        }
      }
    } catch (e) {
      logger.e(e.toString());
      Get.snackbar(
          MessageTranslationConstants.spotifySynchronization.tr,
          e.toString(),
          snackPosition: SnackPosition.bottom,
      );
      spotifyAvailable = false;
    }
    isLoading = false;
    update([AppPageIdConstants.itemlist]);
  }

  Future<void> getSpotifyToken() async {
    logger.d('Getting SpotifyToken');
    String spotifyToken = await SpotifyApiCalls.getSpotifyToken();

    if(spotifyToken.isNotEmpty) {
      logger.i('Spotify access token is: $spotifyToken');
      userController.user!.spotifyToken = spotifyToken;
      await UserFirestore().updateSpotifyToken(userController.user!.id, spotifyToken);
    }

  }

  Future<void> searchItemlist() async {

    logger.d('Start ${newItemlistNameController.text} and ${newItemlistDescController.text}');

    Get.back();

    try {
      if(newItemlistNameController.text.isNotEmpty) {
        await Get.toNamed(AppRouteConstants.playlistSearch,
            arguments: [
              SpotifySearchType.playlist,
              newItemlistNameController.text,],
        );
      } else {
        Get.snackbar(
            MessageTranslationConstants.searchPlaylist.tr,
            MessageTranslationConstants.missingPlaylistName.tr,
            snackPosition: SnackPosition.bottom,);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.itemlist]);
  }

  Future<void> synchronizeSpotifyPlaylists() async {
    logger.i('Getting Spotify Information with token: ${userController.user!.spotifyToken}');

    isLoading = true;
    update([AppPageIdConstants.itemlist]);

    spotify.User spotifyUser = await SpotifyApiCalls.getUserProfile(spotifyToken: userController.user!.spotifyToken);

    try {
      if(spotifyUser.id?.isNotEmpty ?? false) {
        spotifyPlaylistSimples =  await SpotifyApiCalls.getUserPlaylistSimples(spotifyToken: userController.user!.spotifyToken, userId: spotifyUser.id!);

        for (var playlist in spotifyPlaylistSimples) {
          if(playlist.id?.isNotEmpty ?? false) {
            spotifyItemlists[playlist.id!] = Itemlist.mapPlaylistSimpleToItemlist(playlist);
          }
        }

        Get.toNamed(AppRouteConstants.spotifyPlaylists);
      }
    } catch(e) {
      logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.itemlist]);
  }


  Future<void> gotoPlaylistSongs(Itemlist itemlist) async {

    spotify.Playlist spotifyPlaylist = spotify.Playlist();

    try {
      spotify.PlaylistSimple playlistSimple = spotifyPlaylistSimples.where((element) => element.href == itemlist.href).first;

      if(playlistSimple.id?.isNotEmpty ?? false) {
        spotifyPlaylist = await SpotifyApiCalls.getPlaylist(spotifyToken: userController.user!.spotifyToken, playlistId: playlistSimple.id!);
      }

      if(spotifyPlaylist.href?.isNotEmpty ?? false) {
        itemlist.appMediaItems = AppMediaItem.mapTracksToSongs(spotifyPlaylist.tracks!);
        logger.d('${itemlist.appMediaItems?.length ?? 0} songs were mapped from ${spotifyPlaylist.name}');
      }
    } catch (e) {
      logger.e(e.toString());
    }

    await Get.toNamed(AppRouteConstants.listItems, arguments: [itemlist, true]);
    update([AppPageIdConstants.itemlist, AppPageIdConstants.itemlistItem]);

  }

}
