import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/firestore/user_firestore.dart';
import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/domain/use_cases/itemlist_service.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_music_player/domain/use_cases/neom_audio_handler.dart';
import 'package:neom_music_player/ui/player/audioplayer.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';


class MiniPlayerController extends GetxController {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  final Rxn<MediaItem> _mediaItem = Rxn<MediaItem>();
  MediaItem? get mediaItem => _mediaItem.value;
  set mediaItem(MediaItem? mediaItem) => _mediaItem.value = mediaItem;
  // final Rx<MediaItem> _itemlists = <Itemlist>.obs;
  // Map<String, Itemlist> get itemlists => _itemlists;
  // set itemlists(Map<String, Itemlist> itemlists) => _itemlists.value = itemlists;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final NeomAudioHandler audioHandler = GetIt.I<NeomAudioHandler>();

  @override
  void onInit() async {
    super.onInit();
    logger.d("");

    try {

    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    try {

    } catch (e) {

    }
    isLoading = false;
    update();
  }


  void clear() {

  }

  void setMediaItem(MediaItem item) {
    AppUtilities.logger.i("Setting new mediaitem)");
    mediaItem = item;
    update();
  }

  StreamBuilder<Duration> positionSlider(double? maxDuration) {
    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data;
        return position == null
            ? const SizedBox()
            : (position.inSeconds.toDouble() < 0.0 ||
            (position.inSeconds.toDouble() > (maxDuration ?? 180.0)))
            ? const SizedBox()
            : SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.secondary,
            inactiveTrackColor: Colors.transparent,
            trackHeight: 0.5,
            thumbColor: Theme.of(context).colorScheme.secondary,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 1.0,
            ),
            overlayColor: Colors.transparent,
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 2.0,
            ),
          ),
          child: Center(
            child: Slider(
              inactiveColor: Colors.transparent,
              // activeColor: Colors.white,
              value: position.inSeconds.toDouble(),
              max: maxDuration ?? 180.0,
              onChanged: (newPosition) {
                audioHandler.seek(
                  Duration(
                    seconds: newPosition.round(),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  ListTile miniplayerTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath,
    required List preferredMiniButtons,
    bool useDense = false,
    bool isLocalImage = false,
    bool isDummy = false,
  }) {
    return ListTile(
      dense: useDense,
      tileColor: AppColor.main75,
      onTap: isDummy ? null
          : () => Navigator.pushNamed(context, '/player'),
      title: Text(
        isDummy ? '¿Estás buscando nueva música?' : title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isDummy ? 'Escucha nuestras recomendaciones' : subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Hero(
        tag: 'currentArtwork',
        child: imageCard(
          elevation: 8,
          boxDimension: useDense ? 40.0 : 50.0,
          localImage: isDummy ? true : isLocalImage,
          imageUrl: isDummy ? AppFlavour.getAppLogoPath() : imagePath,
        ),
      ),
      trailing: isDummy
          ? IconButton(onPressed: () => Get.toNamed(AppRouteConstants.musicPlayerHome), icon: Icon(Icons.arrow_forward_ios))
          : ControlButtons(
        audioHandler,
        miniplayer: true,
        buttons: isLocalImage
            ? ['Like', 'Play/Pause', 'Next']
            : preferredMiniButtons,
      ),
    );
  }



}
