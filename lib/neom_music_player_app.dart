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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get.dart' as getx;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_music_player/ui/player/miniplayer_controller.dart';
import 'package:neom_music_player/utils/helpers/route_handler.dart';
import 'package:neom_music_player/utils/theme/music_app_theme.dart';
import 'package:neom_music_player/ui/music_player_routes.dart';
import 'package:neom_music_player/ui/player/media_player_page.dart';

class NeomMusicPlayerApp extends StatefulWidget {

  @override
  _NeomMusicPlayerAppState createState() => _NeomMusicPlayerAppState();

  // ignore: unreachable_from_main
  static _NeomMusicPlayerAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_NeomMusicPlayerAppState>()!;

  /// Called when Doing Background Work initiated from Widget
  // @pragma('vm:entry-point')
  // static Future<void> backgroundCallback(Uri? data) async {
  //   if (data?.host == 'controls') {
  //     final audioHandler = await NeomAudioProvider().getAudioHandler();
  //     if (data?.path == '/play') {
  //       audioHandler.play();
  //     } else if (data?.path == '/pause') {
  //       audioHandler.pause();
  //     } else if (data?.path == '/skipNext') {
  //       audioHandler.skipToNext();
  //     } else if (data?.path == '/skipPrevious') {
  //       audioHandler.skipToPrevious();
  //     }
  //   }
  // }

}

class _NeomMusicPlayerAppState extends State<NeomMusicPlayerApp> {

  // late StreamSubscription _intentTextStreamSubscription;
  // late StreamSubscription _intentDataStreamSubscription;
  // final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    // _intentTextStreamSubscription.cancel();
    // _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getx.Get.find<MiniPlayerController>().setIsTimeline(false);
    ///TODO VERIFY IF NEEDED
    // HomeWidget.setAppGroupId('com.gigmeout.io');
    // HomeWidget.registerBackgroundCallback(NeomMusicPlayerApp.backgroundCallback);
    // AppTheme.currentTheme.addListener(() {
    //   setState(() {});
    // });

    if (Platform.isAndroid || Platform.isIOS) {
      ///TODO VERIFY IF NEEDED
      // For sharing or opening urls/text coming from outside the app while the app is in the memory
      // _intentTextStreamSubscription = ReceiveSharingIntent.getTextStream().listen(
      //   (String value) {
      //     AppUtilities.logger.i('Received intent on stream: $value');
      //     handleSharedText(value, navigatorKey);
      //   },
      //   onError: (err) {
      //     AppUtilities.logger.e('ERROR in getTextStream', err);
      //   },
      // );

      //TODO VERIFY IF NEEDED
      // For sharing or opening urls/text coming from outside the app while the app is closed
      // ReceiveSharingIntent.getInitialText().then((String? value) {
      //     AppUtilities.logger.i('Received Intent initially: $value');
      //     if (value != null) handleSharedText(value, navigatorKey);
      //   },
      //   onError: (err) {
      //     AppUtilities.logger.e('ERROR in getInitialTextStream', err);
      //   },
      // );

      //TODO VERIFY IF NEEDED
      // For sharing files coming from outside the app while the app is in the memory
      // _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream().listen(
      //   (List<SharedMediaFile> value) {
      //     if (value.isNotEmpty) {
      //       for (final file in value) {
      //         if (file.path.endsWith('.json')) {
      //           final List playlistNames = Hive.box(AppHiveConstants.settings).get('playlistNames')?.toList() as List? ?? [AppHiveConstants.favoriteSongs];
      //           importFilePlaylist(null, playlistNames,
      //             path: file.path,
      //             pickFile: false,
      //           ).then(
      //             (value) => navigatorKey.currentState?.pushNamed('/playlists'),
      //           );
      //         }
      //       }
      //     }
      //   },
      //   onError: (err) {
      //     AppUtilities.logger.e('ERROR in getDataStream', err);
      //   },
      // );

      //TODO VERIFY IF NEEDED
      // For sharing files coming from outside the app while the app is closed
      // ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      //   if (value.isNotEmpty) {
      //     for (final file in value) {
      //       if (file.path.endsWith('.json')) {
      //         final List playlistNames = Hive.box(AppHiveConstants.settings).get('playlistNames')?.toList() as List? ?? [AppHiveConstants.favoriteSongs];
      //         importFilePlaylist(
      //           null, playlistNames,
      //           path: file.path,
      //           pickFile: false,
      //         ).then(
      //           (value) => navigatorKey.currentState?.pushNamed('/playlists'),
      //         );
      //       }
      //     }
      //   }
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        // navigatorKey: navigatorKey,
        title: AppFlavour.appInUse.name,
        // restorationScopeId: AppFlavour.appInUse.name,
        themeMode: MusicAppTheme.themeMode,
        darkTheme: MusicAppTheme.darkTheme(
          context: context,
        ),
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: AppTheme.fontFamily,
        timePickerTheme: TimePickerThemeData(
            backgroundColor: AppColor.getMain()
        ),
      ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: Get.deviceLocale,
        supportedLocales: const [
          Locale('es'), // Spanish, Mexico
          Locale('en'), // English, United States
          Locale('fr'), // French, France
          Locale('de'), // German, Germany
        ],
        routes: MusicPlayerRoutes.routes,
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == '/player') {
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => MediaPlayerPage(), opaque: false,
            );
          }
          return HandleRoute.handleRoute(settings.name);
        },
    );
  }
}
