import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ui/widgets/gradient_containers.dart';
import '../../utils/constants/app_hive_constants.dart';
import '../../utils/constants/countrycodes.dart';
import '../../utils/helpers/spotify_helper.dart';
import '../api_services/spotify/spotify_api_calls.dart';
import 'app_hive_controller.dart';

class SpotifyHiveController extends GetxController  {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();
  final appHiveController = Get.find<AppHiveController>();

  late SharedPreferences prefs;

  bool firstTime = false;
  int lastNotificationCheckDate = 0;

  List localSongs = [];
  List globalSongs = [];
  bool localFetched = false;
  bool globalFetched = false;
  final ValueNotifier<bool> localFetchFinished = ValueNotifier<bool>(false);
  final ValueNotifier<bool> globalFetchFinished = ValueNotifier<bool>(false);

  @override
  Future<void> onInit() async {
    logger.d('');
    super.onInit();
  }

  Future<List> getChartDetails(String accessToken, String type) async {
    final String globalPlaylistId = CountryCodes.localChartCodes['Global']!;
    final String localPlaylistId = CountryCodes.localChartCodes.containsKey(type)
        ? CountryCodes.localChartCodes[type]!
        : CountryCodes.localChartCodes['Mexico']!;
    final String playlistId =
    type == 'Global' ? globalPlaylistId : localPlaylistId;
    final List data = [];
    final List tracks =
    await SpotifyApiCalls().getAllTracksOfPlaylist(accessToken, playlistId);
    for (final track in tracks) {
      final trackName = track['track']['name'];
      final imageUrlSmall = track['track']['album']['images'].last['url'];
      final imageUrlBig = track['track']['album']['images'].first['url'];
      final spotifyUrl = track['track']['external_urls']['spotify'];
      final artistName = track['track']['artists'][0]['name'].toString();
      data.add({
        'name': trackName,
        'artist': artistName,
        'image_url_small': imageUrlSmall,
        'image_url_big': imageUrlBig,
        'spotifyUrl': spotifyUrl,
      });
    }
    return data;
  }

  Future<void> scrapData(String type, {bool signIn = false}) async {
    final bool spotifySigned =
    Hive.box(AppHiveConstants.settings).get('spotifySigned', defaultValue: false) as bool;

    if (!spotifySigned && !signIn) {
      return;
    }
    final String spotifyToken = await getSpotifyToken();

    final String? accessToken = await retriveAccessToken();
    
    if (accessToken == null) {
      CoreUtilities.launchURL(SpotifyApiCalls().requestAuthorization(),openInApp: false);

      final appLinks = AppLinks();
      appLinks.allUriLinkStream.listen(
            (uri) async {
          final link = uri.toString();
          if (link.contains('code=')) {
            final code = link.split('code=')[1];
            Hive.box(AppHiveConstants.settings).put('spotifyAppCode', code);
            final currentTime = DateTime.now().millisecondsSinceEpoch / 1000;
            final List<String> data = await SpotifyApiCalls().getAccessToken(code: code);
            if (data.isNotEmpty) {
              Hive.box(AppHiveConstants.settings).put('spotifyAccessToken', data[0]);
              Hive.box(AppHiveConstants.settings).put('spotifyRefreshToken', data[1]);
              Hive.box(AppHiveConstants.settings).put('spotifySigned', true);
              Hive.box(AppHiveConstants.settings).put('spotifyTokenExpireAt', currentTime + int.parse(data[2]));
            }

            final temp = await getChartDetails(data[0], type);
            if (temp.isNotEmpty) {
              Hive.box(AppHiveConstants.cache).put('${type}_chart', temp);
              if (type == 'Global') {
                globalSongs = temp;
              } else {
                localSongs = temp;
              }
            }
            if (type == 'Global') {
              globalFetchFinished.value = true;
            } else {
              localFetchFinished.value = true;
            }
          }
        },
      );
    } else {
      final temp = await getChartDetails(spotifyToken, type);
      if (temp.isNotEmpty) {
        Hive.box(AppHiveConstants.cache).put('${type}_chart', temp);
        if (type == 'Global') {
          globalSongs = temp;
        } else {
          localSongs = temp;
        }
      }
      if (type == 'Global') {
        globalFetchFinished.value = true;
      } else {
        localFetchFinished.value = true;
      }
    }
  }

  Future<void> getCachedData(String type) async {
    if (type == 'Global') {
      globalFetched = true;
    } else {
      localFetched = true;
    }
    if (type == 'Global') {
      globalSongs = await Hive.box(AppHiveConstants.cache).get('${type}_chart', defaultValue: []) as List;
    } else {
      localSongs = await Hive.box(AppHiveConstants.cache).get('${type}_chart', defaultValue: []) as List;
    }
  }

  Future<String> changeCountry({required BuildContext context}) async {
    String region = Hive.box(AppHiveConstants.settings).get('region', defaultValue: 'México') as String;
    if (!CountryCodes.localChartCodes.containsKey(region)) {
      region = 'México';
    }

    await showModalBottomSheet(
      isDismissible: true,
      backgroundColor: AppColor.main75,
      context: context,
      builder: (BuildContext context) {
        const Map<String, String> codes = CountryCodes.localChartCodes;
        final List<String> countries = codes.keys.toList();
        return BottomGradientContainer(
          borderRadius: BorderRadius.circular(
            20.0,
          ),
          hasOpacity: false,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              0,
              10,
              0,
              10,
            ),
            itemCount: countries.length,
            itemBuilder: (context, idx) {
              return ListTileTheme(
                selectedColor: Theme.of(context).colorScheme.secondary,
                child: ListTile(
                  title: Text(
                    countries[idx],
                  ),
                  leading: Radio(
                    value: countries[idx],
                    groupValue: region,
                    onChanged: (value) {
                      localSongs = [];
                      region = countries[idx];
                      localFetched = false;
                      localFetchFinished.value = false;
                      Hive.box(AppHiveConstants.settings).put('region', region);
                      Navigator.pop(context);
                    },
                  ),
                  selected: region == countries[idx],
                  onTap: () {
                    localSongs = [];
                    region = countries[idx];
                    localFetchFinished.value = false;
                    Hive.box(AppHiveConstants.settings).put('region', region);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        );
      },
    );
    return region;
  }

}
