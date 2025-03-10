//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get.dart' as getx;
// import 'package:neom_commons/core/app_flavour.dart';
// import 'package:neom_commons/core/utils/app_color.dart';
// import 'package:neom_commons/core/utils/app_theme.dart';
// import 'ui/audio_player_routes.dart';
// import 'ui/player/media_player_page.dart';
// import 'ui/player/miniplayer_controller.dart';
// import 'utils/helpers/route_handler.dart';
// import 'utils/theme/music_app_theme.dart';
//
// class NeomAudioPlayerApp extends StatefulWidget {
//   const NeomAudioPlayerApp({super.key});
//
//
//   @override
//   NeomAudioPlayerAppState createState() => NeomAudioPlayerAppState();
// }
//
// class NeomAudioPlayerAppState extends State<NeomAudioPlayerApp> {
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     getx.Get.find<MiniPlayerController>().setIsTimeline(false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         title: AppFlavour.appInUse.name,
//         themeMode: MusicAppTheme.themeMode,
//         darkTheme: MusicAppTheme.darkTheme(
//           context: context,
//         ),
//       theme: ThemeData(
//         brightness: Brightness.dark,
//         fontFamily: AppTheme.fontFamily,
//         timePickerTheme: TimePickerThemeData(
//             backgroundColor: AppColor.getMain(),
//         ),
//       ),
//         // localizationsDelegates: const [
//         //   GlobalMaterialLocalizations.delegate,
//         //   GlobalWidgetsLocalizations.delegate,
//         //   GlobalCupertinoLocalizations.delegate,
//         // ],
//         locale: Get.deviceLocale,
//         supportedLocales: const [
//           Locale('es'), // Spanish, Mexico
//           Locale('en'), // English, United States
//           Locale('fr'), // French, France
//           Locale('de'), // German, Germany
//         ],
//         routes: AudioPlayerRoutes.routes,
//         onGenerateRoute: (RouteSettings settings) {
//           if (settings.name == '/player') {
//             return PageRouteBuilder(
//               pageBuilder: (_, __, ___) => MediaPlayerPage(), opaque: false,
//             );
//           }
//           return HandleRoute.handleRoute(settings.name);
//         },
//     );
//   }
// }
