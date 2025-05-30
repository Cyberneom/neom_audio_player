// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:neom_commons/core/utils/app_color.dart';
// import 'music_player_theme.dart';
//
// // ignore: avoid_classes_with_only_static_members
// class MusicAppTheme {
//   static MusicPlayerTheme get currentTheme => MusicPlayerTheme();
//   static ThemeMode get themeMode => MusicPlayerTheme().currentTheme();
//
//   static ThemeData lightTheme({
//     required BuildContext context,
//   }) {
//     return ThemeData(
//       textSelectionTheme: TextSelectionThemeData(
//         selectionHandleColor: currentTheme.currentColor(),
//         cursorColor: currentTheme.currentColor(),
//         selectionColor: currentTheme.currentColor(),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         focusedBorder: UnderlineInputBorder(
//           borderSide:
//               BorderSide(width: 1.5, color: currentTheme.currentColor()),
//         ),
//       ),
//       listTileTheme: ListTileThemeData(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(7.0),
//         ),
//       ),
//       visualDensity: VisualDensity.adaptivePlatformDensity,
//       appBarTheme: AppBarTheme(
//         backgroundColor: currentTheme.currentColor(),
//         systemOverlayStyle: SystemUiOverlayStyle(
//           statusBarIconBrightness: MusicAppTheme.themeMode == ThemeMode.system
//               ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
//                   ? Brightness.light
//                   : Brightness.dark
//               : MusicAppTheme.themeMode == ThemeMode.dark
//                   ? Brightness.light
//                   : Brightness.dark,
//         ),
//       ),
//       cardTheme: CardTheme(
//         clipBehavior: Clip.antiAlias,
//         elevation: 5,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(7.0),
//         ),
//       ),
//       disabledColor: Colors.grey[600],
//       brightness: Brightness.light,
//       indicatorColor: currentTheme.currentColor(),
//       progressIndicatorTheme: const ProgressIndicatorThemeData()
//           .copyWith(color: currentTheme.currentColor()),
//       iconTheme: IconThemeData(
//         color: Colors.grey[800],
//         opacity: 1.0,
//         size: 24.0,
//       ),
//       colorScheme: Theme.of(context).colorScheme.copyWith(
//             primary: Colors.grey[800],
//             brightness: Brightness.light,
//             secondary: currentTheme.currentColor(),
//           ),
//     );
//   }
//
//   static ThemeData darkTheme({
//     required BuildContext context,
//   }) {
//     return ThemeData(
//       textButtonTheme: TextButtonThemeData(
//         style: TextButton.styleFrom(
//           foregroundColor: Colors.white,
//           backgroundColor: AppColor.main75,
//           elevation: 0.0,
//         ),
//       ),
//       textSelectionTheme: TextSelectionThemeData(
//         selectionHandleColor: currentTheme.currentColor(),
//         cursorColor: currentTheme.currentColor(),
//         selectionColor: currentTheme.currentColor(),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         focusedBorder: UnderlineInputBorder(
//           borderSide:
//               BorderSide(width: 1.5, color: currentTheme.currentColor()),
//         ),
//       ),
//       listTileTheme: ListTileThemeData(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(7.0),
//         ),
//       ),
//       visualDensity: VisualDensity.adaptivePlatformDensity,
//       brightness: Brightness.dark,
//       appBarTheme: AppBarTheme(
//         color: currentTheme.getCanvasColor(),
//         foregroundColor: Colors.white,
//       ),
//       canvasColor: currentTheme.getCanvasColor(),
//       cardColor: currentTheme.getCardColor(),
//       cardTheme: CardTheme(
//         clipBehavior: Clip.antiAlias,
//         elevation: 5,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(7.0),
//         ),
//       ),
//       dialogBackgroundColor: currentTheme.getCardColor(),
//       progressIndicatorTheme: const ProgressIndicatorThemeData()
//           .copyWith(color: currentTheme.currentColor()),
//       iconTheme: const IconThemeData(
//         color: Colors.white,
//         opacity: 1.0,
//         size: 24.0,
//       ),
//       indicatorColor: currentTheme.currentColor(),
//       colorScheme: Theme.of(context).colorScheme.copyWith(
//             primary: Colors.white,
//             secondary: currentTheme.currentColor(),
//             brightness: Brightness.dark,
//           ),
//     );
//   }
// }
