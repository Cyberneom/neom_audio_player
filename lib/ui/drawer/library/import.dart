/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_music_player/data/api_services/spotify/spotify_api_calls.dart';
import 'package:neom_music_player/data/implementations/playlist_hive_controller.dart';
import 'package:neom_music_player/ui/widgets/gradient_containers.dart';
import 'package:neom_music_player/ui/widgets/image_card.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/ui/widgets/textinput_dialog.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/helpers/import_export_playlist.dart';
import 'package:neom_music_player/utils/helpers/search_add_playlist.dart';
import 'package:neom_music_player/utils/helpers/spotify_helper.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

class ImportPlaylist extends StatelessWidget {
  ImportPlaylist({super.key});

  final Box settingsBox = Hive.box(AppHiveConstants.settings);
  final List playlistNames =
      Hive.box(AppHiveConstants.settings).get('playlistNames')?.toList() as List? ??
          [AppHiveConstants.favoriteSongs];

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: AppColor.main75,
        appBar: AppBar(
          title: Text(PlayerTranslationConstants.importPlaylist.tr,),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: 3,
          itemBuilder: (ctx, index) {
            return ListTile(
              title: Text(
                index == 0
                    ? PlayerTranslationConstants.importFile.tr
                    : index == 1
                    ? PlayerTranslationConstants.importSpotify.tr
                    : PlayerTranslationConstants.importYt.tr,
              ),
              leading: SizedBox.square(
                dimension: 50,
                child: Center(
                  child: Icon(
                    index == 0
                        ? MdiIcons.import
                        : index == 1
                            ? MdiIcons.spotify
                            : index == 2
                                ? MdiIcons.youtube
                                : Icons.music_note_rounded,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
              onTap: () {
                index == 0
                    ? importFile(
                        ctx,
                        playlistNames,
                        settingsBox,
                      )
                    : index == 1
                        ? connectToSpotify(
                            ctx,
                            playlistNames,
                            settingsBox,
                          )
                        : index == 2
                            ? importYt(
                                ctx,
                                playlistNames,
                                settingsBox,
                              )
                            : index == 3
                                ? importJioSaavn(
                                    ctx,
                                    playlistNames,
                                    settingsBox,
                                  )
                                : importResso(
                                    ctx,
                                    playlistNames,
                                    settingsBox,
                                  );
              },
            );
          },
        ),
      ),
    );
  }
}

Future<void> importFile(
  BuildContext context,
  List playlistNames,
  Box settingsBox,
) async {
  await importFilePlaylist(context, playlistNames);
}

Future<void> connectToSpotify(
  BuildContext context,
  List playlistNames,
  Box settingsBox,
) async {
  final String? accessToken = await retriveAccessToken();

  if (accessToken == null) {
    launchUrl(
      Uri.parse(
        SpotifyApiCalls().requestAuthorization(),
      ),
      mode: LaunchMode.externalApplication,
    );
    final appLinks = AppLinks();
    appLinks.allUriLinkStream.listen(
      (uri) async {
        final link = uri.toString();
        if (link.contains('code=')) {
          final code = link.split('code=')[1];
          settingsBox.put('spotifyAppCode', code);
          final currentTime = DateTime.now().millisecondsSinceEpoch / 1000;
          final List<String> data =
              await SpotifyApiCalls().getAccessToken(code: code);
          if (data.isNotEmpty) {
            settingsBox.put('spotifyAccessToken', data[0]);
            settingsBox.put('spotifyRefreshToken', data[1]);
            settingsBox.put(
              'spotifyTokenExpireAt',
              currentTime + int.parse(data[2]),
            );
            await fetchPlaylists(
              data[0],
              context,
              playlistNames,
              settingsBox,
            );
          }
        }
      },
    );
  } else {
    await fetchPlaylists(
      accessToken,
      context,
      playlistNames,
      settingsBox,
    );
  }
}

Future<void> importYt(
  BuildContext context,
  List playlistNames,
  Box settingsBox,
) async {
  showTextInputDialog(
    context: context,
    title: PlayerTranslationConstants.enterPlaylistLink.tr,
    initialText: '',
    keyboardType: TextInputType.url,
    onSubmitted: (String value, BuildContext context) async {
      final String link = value.trim();
      Navigator.pop(context);
      final Map data = await SearchAddPlaylist.addYtPlaylist(link);
      if (data.isNotEmpty) {
        if (data['title'] == '' && data['count'] == 0) {
          AppUtilities.logger.e(
            'Failed to import YT playlist. Data not empty but title or the count is empty.',
          );
          ShowSnackBar().showSnackBar(
            context,
            '${PlayerTranslationConstants.failedImport.tr}\n${PlayerTranslationConstants.confirmViewable.tr}',
            duration: const Duration(seconds: 3),
          );
        } else {
          playlistNames.add(
            data['title'] == '' ? 'Yt Playlist' : data['title'],
          );
          settingsBox.put(
            'playlistNames',
            playlistNames,
          );

          await SearchAddPlaylist.showProgress(
            data['count'] as int,
            context,
            SearchAddPlaylist.ytSongsAdder(
              data['title'].toString(),
              data['tracks'] as List,
            ),
          );
        }
      } else {
        AppUtilities.logger.e(
          'Failed to import YT playlist. Data is empty.',
        );
        ShowSnackBar().showSnackBar(
          context,
          PlayerTranslationConstants.failedImport.tr,
        );
      }
    },
  );
}

Future<void> importResso(
  BuildContext context,
  List playlistNames,
  Box settingsBox,
) async {
  showTextInputDialog(
    context: context,
    title: PlayerTranslationConstants.enterPlaylistLink.tr,
    initialText: '',
    keyboardType: TextInputType.url,
    onSubmitted: (String value, BuildContext context) async {
      final String link = value.trim();
      Navigator.pop(context);
      final Map data = await SearchAddPlaylist.addRessoPlaylist(link);
      if (data.isNotEmpty) {
        String playName = data['title'].toString();
        while (playlistNames.contains(playName) ||
            await Hive.boxExists(playName)) {
          // ignore: use_string_buffers
          playName = '$playName (1)';
        }
        playlistNames.add(playName);
        settingsBox.put(
          'playlistNames',
          playlistNames,
        );

        await SearchAddPlaylist.showProgress(
          data['count'] as int,
          context,
          SearchAddPlaylist.ressoSongsAdder(
            playName,
            data['tracks'] as List,
          ),
        );
      } else {
        AppUtilities.logger.e(
          'Failed to import Resso playlist. Data is empty.',
        );
        ShowSnackBar().showSnackBar(
          context,
          PlayerTranslationConstants.failedImport.tr,
        );
      }
    },
  );
}

Future<void> importSpotify(
  BuildContext context,
  String accessToken,
  String playlistId,
  String playlistName,
  Box settingsBox,
  List playlistNames,
) async {
  final Map data = await SearchAddPlaylist.addSpotifyPlaylist(
    playlistName,
    accessToken,
    playlistId,
  );
  if (data.isNotEmpty) {
    String playName = data['title'].toString();
    while (playlistNames.contains(playName) || await Hive.boxExists(playName)) {
      // ignore: use_string_buffers
      playName = '$playName (1)';
    }
    playlistNames.add(playName);
    settingsBox.put(
      'playlistNames',
      playlistNames,
    );

    await SearchAddPlaylist.showProgress(
      data['count'] as int,
      context,
      SearchAddPlaylist.spotifySongsAdder(
        playName,
        data['tracks'] as List,
      ),
    );
  } else {
    AppUtilities.logger.e(
      'Failed to import Spotify playlist. Data is empty.',
    );
    ShowSnackBar().showSnackBar(
      context,
      PlayerTranslationConstants.failedImport.tr,
    );
  }
}

Future<void> importSpotifyViaLink(
  BuildContext context,
  List playlistNames,
  Box settingsBox,
  String accessToken,
) async {
  showTextInputDialog(
    context: context,
    title: PlayerTranslationConstants.enterPlaylistLink.tr,
    initialText: '',
    keyboardType: TextInputType.url,
    onSubmitted: (String value, BuildContext context) async {
      Navigator.pop(context);
      final String playlistId = value.split('?')[0].split('/').last;
      final playlistName = PlayerTranslationConstants.spotifyPublic.tr;
      await importSpotify(
        context,
        accessToken,
        playlistId,
        playlistName,
        settingsBox,
        playlistNames,
      );
    },
  );
}

Future<void> importJioSaavn(
  BuildContext context,
  List playlistNames,
  Box settingsBox,
) async {
  showTextInputDialog(
    context: context,
    title: PlayerTranslationConstants.enterPlaylistLink.tr,
    initialText: '',
    keyboardType: TextInputType.url,
    onSubmitted: (String value, BuildContext context) async {
      final String link = value.trim();
      Navigator.pop(context);
      final Map data = await SearchAddPlaylist.addJioSaavnPlaylist(
        link,
      );

      if (data.isNotEmpty) {
        final String playName = data['title'].toString();
        PlaylistHiveController().addPlaylist(playName, data['tracks'] as List);
        playlistNames.add(playName);
      } else {
        AppUtilities.logger.e('Failed to import JioSaavn playlist. data is empty');
        ShowSnackBar().showSnackBar(
          context,
          PlayerTranslationConstants.failedImport.tr,
        );
      }
    },
  );
}

Future<void> fetchPlaylists(
  String accessToken,
  BuildContext context,
  List playlistNames,
  Box settingsBox,
) async {
  final List spotifyPlaylists =
      await SpotifyApiCalls().getUserPlaylistsV2(accessToken);
  showModalBottomSheet(
    isDismissible: true,
    backgroundColor: AppColor.main75,
    context: context,
    builder: (BuildContext contxt) {
      return BottomGradientContainer(
        child: ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          itemCount: spotifyPlaylists.length + 1,
          itemBuilder: (ctxt, idx) {
            if (idx == 0) {
              return ListTile(
                title: Text(
                  PlayerTranslationConstants.importPublicPlaylist.tr,
                ),
                leading: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: Colors.transparent,
                  child: SizedBox.square(
                    dimension: 50,
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ),
                ),
                onTap: () async {
                  await importSpotifyViaLink(
                    context,
                    playlistNames,
                    settingsBox,
                    accessToken,
                  );
                  Navigator.pop(context);
                },
              );
            }

            final String playName = spotifyPlaylists[idx - 1]['name']
                .toString()
                .replaceAll('/', ' ');
            final int playTotal =
                spotifyPlaylists[idx - 1]['tracks']['total'] as int;
            return playTotal == 0
                ? const SizedBox()
                : ListTile(
                    title: Text(playName),
                    subtitle: Text(
                      playTotal == 1
                          ? '$playTotal ${PlayerTranslationConstants.song.tr}'
                          : '$playTotal ${PlayerTranslationConstants.songs.tr}',
                    ),
                    leading: imageCard(
                      imageUrl:
                          (spotifyPlaylists[idx - 1]['images'] as List).isEmpty
                              ? ''
                              : spotifyPlaylists[idx - 1]['images'][0]['url']
                                  .toString(),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final String playName = spotifyPlaylists[idx - 1]['name']
                          .toString()
                          .replaceAll('/', ' ');
                      final String playlistId =
                          spotifyPlaylists[idx - 1]['id'].toString();

                      importSpotify(
                        context,
                        accessToken,
                        playlistId,
                        playName,
                        settingsBox,
                        playlistNames,
                      );
                    },
                  );
          },
        ),
      );
    },
  );
  return;
}