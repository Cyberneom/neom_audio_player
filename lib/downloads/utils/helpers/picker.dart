// import 'dart:io';
//
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:neom_commons/core/utils/app_utilities.dart';
//
// // ignore: avoid_classes_with_only_static_members
// class Picker {
//   static Future<String> selectFolder({
//     required BuildContext context,
//     String? message,
//   }) async {
//     final String? temp =
//         await FilePicker.platform.getDirectoryPath(dialogTitle: message);
//     AppConfig.logger.i('Selected folder: $temp');
//     return (temp == '/' || temp == null) ? '' : temp;
//   }
//
//   static Future<String> selectFile({
//     required BuildContext context,
//     // List<String>? ext,
//     String? message,
//   }) async {
//     final FilePickerResult? result = await FilePicker.platform.pickFiles(
//       // allowedExtensions: ext,
//       dialogTitle: message,
//     );
//
//     if (result != null) {
//       final File file = File(result.files.first.path!);
//       return file.path == '/' ? '' : file.path;
//     }
//     return '';
//   }
// }
