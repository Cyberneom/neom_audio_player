import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get/get.dart' as getx;
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'ui/audio_player_routes.dart';
import 'ui/player/media_player_page.dart';
import 'ui/player/miniplayer_controller.dart';
import 'utils/helpers/route_handler.dart';
import 'utils/theme/music_app_theme.dart';

class NeomAudioPlayerApp extends StatefulWidget {
  const NeomAudioPlayerApp({super.key});


  @override
  NeomAudioPlayerAppState createState() => NeomAudioPlayerAppState();

  // // ignore: unreachable_from_main
  // static NeomMusicPlayerAppState of(BuildContext context) =>
  //     context.findAncestorStateOfType<NeomMusicPlayerAppState>()!;

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

class NeomAudioPlayerAppState extends State<NeomAudioPlayerApp> {

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
        title: AppFlavour.appInUse.name,
        themeMode: MusicAppTheme.themeMode,
        darkTheme: MusicAppTheme.darkTheme(
          context: context,
        ),
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: AppTheme.fontFamily,
        timePickerTheme: TimePickerThemeData(
            backgroundColor: AppColor.getMain(),
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
        routes: AudioPlayerRoutes.routes,
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
