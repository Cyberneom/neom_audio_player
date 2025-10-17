import 'package:flutter/material.dart';
import 'package:neom_core/app_config.dart';

class HandleRoute {

  static Route? handleRoute(String? url) {
    AppConfig.logger.i('received route url: $url');
    if (url == null) return null;

    final RegExpMatch? fileResult = RegExp(r'\/[0-9]+\/([0-9]+)\/').firstMatch('$url/');
    if (fileResult != null) {
      ///VERIFY TO ADD OFFLINE MODE
      // return PageRouteBuilder(
      //   opaque: false,
      //   pageBuilder: (_, __, ___) => OfflinePlayHandler(
      //     id: fileResult[1]!,
      //   ),
      // );
    }

    return null;
  }
}
