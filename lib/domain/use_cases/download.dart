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

import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';

import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_music_player/domain/use_cases/ext_storage_provider.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:neom_music_player/utils/helpers/lyrics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Download with ChangeNotifier {
  static final Map<String, Download> _instances = {};
  final String id;

  factory Download(String id) {
    if (_instances.containsKey(id)) {
      return _instances[id]!;
    } else {
      final instance = Download._internal(id);
      _instances[id] = instance;
      return instance;
    }
  }

  Download._internal(this.id);

  int? rememberOption;
  final ValueNotifier<bool> remember = ValueNotifier<bool>(false);
  String preferredDownloadQuality = Hive.box(AppHiveConstants.settings)
      .get('downloadQuality', defaultValue: '320 kbps') as String;
  String preferredYtDownloadQuality = Hive.box(AppHiveConstants.settings)
      .get('ytDownloadQuality', defaultValue: 'High') as String;
  String downloadFormat = Hive.box(AppHiveConstants.settings)
      .get('downloadFormat', defaultValue: 'm4a')
      .toString();
  bool createDownloadFolder = Hive.box(AppHiveConstants.settings)
      .get('createDownloadFolder', defaultValue: false) as bool;
  bool createYoutubeFolder = Hive.box(AppHiveConstants.settings)
      .get('createYoutubeFolder', defaultValue: false) as bool;
  double? progress = 0.0;
  String lastDownloadId = '';
  bool downloadLyrics =
      Hive.box(AppHiveConstants.settings).get('downloadLyrics', defaultValue: false) as bool;
  bool download = true;

  Future<void> prepareDownload(
    BuildContext context,
    Map data, {
    bool createFolder = false,
    String? folderName,
  }) async {
    AppUtilities.logger.i('Preparing download for ${data['title']}');
    download = true;
    if (Platform.isAndroid || Platform.isIOS) {
      AppUtilities.logger.i('Requesting storage permission');
      PermissionStatus status = await Permission.storage.status;
      if (status.isDenied) {
        AppUtilities.logger.i('Request denied');
        await [
          Permission.storage,
          Permission.accessMediaLocation,
          Permission.mediaLibrary,
        ].request();
      }
      status = await Permission.storage.status;
      if (status.isPermanentlyDenied) {
        AppUtilities.logger.i('Request permanently denied');
        await openAppSettings();
      }
    }
    final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    data['title'] = data['title'].toString().split('(From')[0].trim();

    String filename = '';
    final int downFilename =
        Hive.box(AppHiveConstants.settings).get('downFilename', defaultValue: 0) as int;
    if (downFilename == 0) {
      filename = '${data["title"]} - ${data["artist"]}';
    } else if (downFilename == 1) {
      filename = '${data["artist"]} - ${data["title"]}';
    } else {
      filename = '${data["title"]}';
    }
    // String filename = '${data["title"]} - ${data["artist"]}';
    String dlPath =
        Hive.box(AppHiveConstants.settings).get('downloadPath', defaultValue: '') as String;
    AppUtilities.logger.i('Cached Download path: $dlPath');
    if (filename.length > 200) {
      final String temp = filename.substring(0, 200);
      final List tempList = temp.split(', ');
      tempList.removeLast();
      filename = tempList.join(', ');
    }

    filename = '${filename.replaceAll(avoid, "").replaceAll("  ", " ")}.m4a';
    if (dlPath == '') {
      AppUtilities.logger.i('Cached Download path is empty, getting new path');
      final String? temp = await ExtStorageProvider.getExtStorage(
        dirName: 'Music',
        writeAccess: true,
      );
      dlPath = temp!;
    }
    AppUtilities.logger.i('New Download path: $dlPath');
    if (data['url'].toString().contains('google') && createYoutubeFolder) {
      AppUtilities.logger.i('Youtube audio detected, creating Youtube folder');
      dlPath = '$dlPath/YouTube';
      if (!await Directory(dlPath).exists()) {
        AppUtilities.logger.i('Creating Youtube folder');
        await Directory(dlPath).create();
      }
    }

    if (createFolder && createDownloadFolder && folderName != null) {
      final String foldername = folderName.replaceAll(avoid, '');
      dlPath = '$dlPath/$foldername';
      if (!await Directory(dlPath).exists()) {
        AppUtilities.logger.i('Creating folder $foldername');
        await Directory(dlPath).create();
      }
    }

    final bool exists = await File('$dlPath/$filename').exists();
    if (exists) {
      AppUtilities.logger.i('File already exists');
      if (remember.value == true && rememberOption != null) {
        switch (rememberOption) {
          case 0:
            lastDownloadId = data['id'].toString();
          case 1:
            downloadSong(context, dlPath, filename, data);
          case 2:
            while (await File('$dlPath/$filename').exists()) {
              filename = filename.replaceAll('.m4a', ' (1).m4a');
            }
          default:
            lastDownloadId = data['id'].toString();
            break;
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              title: Text(
                PlayerTranslationConstants.alreadyExists.tr,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '"${data['title']}" ${PlayerTranslationConstants.downAgain.tr}',
                    softWrap: true,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
              actions: [
                Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: remember,
                      builder: (
                        BuildContext context,
                        bool rememberValue,
                        Widget? child,
                      ) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                value: rememberValue,
                                onChanged: (bool? value) {
                                  remember.value = value ?? false;
                                },
                              ),
                              Text(
                                PlayerTranslationConstants.rememberChoice.tr,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () {
                              lastDownloadId = data['id'].toString();
                              Navigator.pop(context);
                              rememberOption = 0;
                            },
                            child: Text(
                              PlayerTranslationConstants.no.tr,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              Hive.box(AppHiveConstants.downloads).delete(data['id']);
                              downloadSong(context, dlPath, filename, data);
                              rememberOption = 1;
                            },
                            child:
                                Text(PlayerTranslationConstants.yesReplace.tr),
                          ),
                          const SizedBox(width: 5.0),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              while (await File('$dlPath/$filename').exists()) {
                                filename =
                                    filename.replaceAll('.m4a', ' (1).m4a');
                              }
                              rememberOption = 2;
                              downloadSong(context, dlPath, filename, data);
                            },
                            child: Text(
                              PlayerTranslationConstants.yes.tr,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.secondary ==
                                            Colors.white
                                        ? Colors.black
                                        : null,
                              ),
                            ),
                          ),
                          const SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }
    } else {
      downloadSong(context, dlPath, filename, data);
    }
  }

  Future<void> downloadSong(
    BuildContext context,
    String? dlPath,
    String fileName,
    Map data,
  ) async {
    AppUtilities.logger.i('processing download');
    progress = null;
    notifyListeners();
    String? filepath;
    late String filepath2;
    String? appPath;
    final List<int> bytes = [];
    String lyrics = '';
    final artname = fileName.replaceAll('.m4a', '.jpg');
    if (!Platform.isWindows) {
      AppUtilities.logger.i('Getting App Path for storing image');
      appPath = Hive.box(AppHiveConstants.settings).get('tempDirPath')?.toString();
      appPath ??= (await getTemporaryDirectory()).path;
    } else {
      final Directory? temp = await getDownloadsDirectory();
      appPath = temp!.path;
    }

    try {
      AppUtilities.logger.i('Creating audio file $dlPath/$fileName');
      await File('$dlPath/$fileName')
          .create(recursive: true)
          .then((value) => filepath = value.path);
      AppUtilities.logger.i('Creating image file $appPath/$artname');
      await File('$appPath/$artname')
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
    } catch (e) {
      AppUtilities.logger.i('Error creating files, requesting additional permission');
      if (Platform.isAndroid) {
        PermissionStatus status = await Permission.manageExternalStorage.status;
        if (status.isDenied) {
          AppUtilities.logger.i(
            'ManageExternalStorage permission is denied, requesting permission',
          );
          await [
            Permission.manageExternalStorage,
          ].request();
        }
        status = await Permission.manageExternalStorage.status;
        if (status.isPermanentlyDenied) {
          AppUtilities.logger.i(
            'ManageExternalStorage Request is permanently denied, opening settings',
          );
          await openAppSettings();
        }
      }

      AppUtilities.logger.i('Retrying to create audio file');
      await File('$dlPath/$fileName')
          .create(recursive: true)
          .then((value) => filepath = value.path);

      AppUtilities.logger.i('Retrying to create image file');
      await File('$appPath/$artname')
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
    }
    String kUrl = data['url'].toString();

    if (data['url'].toString().contains('google')) {
      AppUtilities.logger.i('Fetching youtube download url with preferred quality');
      // filename = filename.replaceAll('.m4a', '.opus');

      kUrl = preferredYtDownloadQuality == 'High'
          ? data['highUrl'].toString()
          : data['lowUrl'].toString();
      if (kUrl == 'null') {
        kUrl = data['url'].toString();
      }
    } else {
      AppUtilities.logger.i('Fetching jiosaavn download url with preferred quality');
      kUrl = kUrl.replaceAll(
        '_96.',
        "_${preferredDownloadQuality.replaceAll(' kbps', '')}.",
      );
    }

    AppUtilities.logger.i('Connecting to Client');
    final client = Client();
    final response = await client.send(Request('GET', Uri.parse(kUrl)));
    final int total = response.contentLength ?? 0;
    int recieved = 0;
    AppUtilities.logger.i('Client connected, Starting download');
    response.stream.asBroadcastStream();
    AppUtilities.logger.i('broadcasting download state');
    response.stream.listen((value) {
      bytes.addAll(value);
      try {
        recieved += value.length;
        progress = recieved / total;
        notifyListeners();
        if (!download) {
          client.close();
        }
      } catch (e) {
        AppUtilities.logger.e('Error in download: $e');
      }
    }).onDone(() async {
      if (download) {
        AppUtilities.logger.i('Download complete, modifying file');
        final file = File(filepath!);
        await file.writeAsBytes(bytes);

        final client = HttpClient();
        final HttpClientRequest request2 =
            await client.getUrl(Uri.parse(data['image'].toString()));
        final HttpClientResponse response2 = await request2.close();
        final bytes2 = await consolidateHttpClientResponseBytes(response2);
        final File file2 = File(filepath2);

        await file2.writeAsBytes(bytes2);
        try {
          AppUtilities.logger.i('Checking if lyrics required');
          if (downloadLyrics) {
            AppUtilities.logger.i('downloading lyrics');
            final Map res = await Lyrics.getLyrics(
              id: data['id'].toString(),
              title: data['title'].toString(),
              artist: data['artist'].toString(),
              saavnHas: data['has_lyrics'] == 'true',
            );
            lyrics = res['lyrics'].toString();
          }
        } catch (e) {
          AppUtilities.logger.e('Error fetching lyrics: $e');
          lyrics = '';
        }
        // commented out not to use FFmpeg as it increases the size of the app
        // can uncomment this if you want to use FFmpeg to convert the audio format
        // to any desired codec instead of the default m4a one.

        // final List<String> availableFormats = ['m4a'];
        // if (downloadFormat != 'm4a' &&
        //     availableFormats.contains(downloadFormat)) {
        //   List<String>? argsList;
        //   if (downloadFormat == 'mp3') {
        //     argsList = [
        //       '-y',
        //       '-i',
        //       '$filepath',
        //       '-c:a',
        //       'libmp3lame',
        //       '-b:a',
        //       '320k',
        //       (filepath!.replaceAll('.m4a', '.mp3'))
        //     ];
        //   }
        //   if (downloadFormat == 'm4a') {
        //     argsList = [
        //       '-y',
        //       '-i',
        //       filepath!,
        //       '-c:a',
        //       'aac',
        //       '-b:a',
        //       '320k',
        //       filepath!.replaceAll('.m4a', '.m4a')
        //     ];
        //   }
        //   // await FlutterFFmpeg().executeWithArguments(_argsList);
        //   // await File(filepath!).delete();
        //   // filepath = filepath!.replaceAll('.m4a', '.$downloadFormat');
        // }
        AppUtilities.logger.i('Getting audio tags');
        if (Platform.isAndroid) {
          try {
            final Tag tag = Tag(
              title: data['title'].toString(),
              artist: data['artist'].toString(),
              albumArtist: data['album_artist']?.toString() ??
                  data['artist']?.toString().split(', ')[0] ??
                  '',
              artwork: filepath2,
              album: data['album'].toString(),
              genre: data['language'].toString(),
              year: data['year'].toString(),
              lyrics: lyrics,
              comment: 'Gigmeout',
            );
            AppUtilities.logger.i('Started tag editing');
            final tagger = Audiotagger();
            await tagger.writeTags(
              path: filepath!,
              tag: tag,
            );
            // await Future.delayed(const Duration(seconds: 1), () async {
            //   if (await file2.exists()) {
            //     await file2.delete();
            //   }
            // });
          } catch (e) {
            AppUtilities.logger.e('Error editing tags: $e');
          }
        } else {
          // Set metadata to file
          await MetadataGod.writeMetadata(
            file: filepath!,
            metadata: Metadata(
              title: data['title'].toString(),
              artist: data['artist'].toString(),
              albumArtist: data['album_artist']?.toString() ??
                  data['artist']?.toString().split(', ')[0] ??
                  '',
              album: data['album'].toString(),
              genre: data['language'].toString(),
              year: int.parse(data['year'].toString()),
              // lyrics: lyrics,
              // comment: 'BlackHole',
              // trackNumber: 1,
              // trackTotal: 12,
              // discNumber: 1,
              // discTotal: 5,
              durationMs: int.parse(data['duration'].toString()) * 1000,
              fileSize: file.lengthSync(),
              picture: Picture(
                data: File(filepath2).readAsBytesSync(),
                mimeType: 'image/jpeg',
              ),
            ),
          );
        }
        AppUtilities.logger.i('Closing connection & notifying listeners');
        client.close();
        lastDownloadId = data['id'].toString();
        progress = 0.0;
        notifyListeners();

        AppUtilities.logger.i('Putting data to downloads database');
        final songData = {
          'id': data['id'].toString(),
          'title': data['title'].toString(),
          'subtitle': data['subtitle'].toString(),
          'artist': data['artist'].toString(),
          'albumArtist': data['album_artist']?.toString() ??
              data['artist']?.toString().split(', ')[0],
          'album': data['album'].toString(),
          'genre': data['language'].toString(),
          'year': data['year'].toString(),
          'lyrics': lyrics,
          'duration': data['duration'],
          'release_date': data['release_date'].toString(),
          'album_id': data['album_id'].toString(),
          'perma_url': data['perma_url'].toString(),
          'quality': preferredDownloadQuality,
          'path': filepath,
          'image': filepath2,
          'image_url': data['image'].toString(),
          'from_yt': data['language'].toString() == 'YouTube',
          'dateAdded': DateTime.now().toString(),
        };
        Hive.box(AppHiveConstants.downloads).put(songData['id'].toString(), songData);

        AppUtilities.logger.i('Everything done, showing snackbar');
        ShowSnackBar().showSnackBar(
          context,
          '"${data['title']}" ${PlayerTranslationConstants.downed.tr}',
        );
      } else {
        download = true;
        progress = 0.0;
        File(filepath!).delete();
        File(filepath2).delete();
      }
    });
  }
}
