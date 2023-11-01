import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'gradient_containers.dart';
import 'snackbar.dart';
import 'textinput_dialog.dart';
import '../../utils/constants/player_translation_constants.dart';
import '../../utils/helpers/audio_query.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
                  leading: const Card(
                    elevation: 0,
                    color: Colors.transparent,
                    child: SizedBox.square(
                      dimension: 50,
                      child: Center(child: Icon(Icons.add_rounded,),),
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
