
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_shared_preference_constants.dart';
import 'package:neom_commons/core/utils/enums/app_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';



class AppHiveController extends GetxController  {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  late SharedPreferences prefs;

  bool firstTime = false;
  int lastNotificationCheckDate = 0;

  @override
  void onInit() async {
    logger.d("");
    super.onInit();
    await openHiveBox("boxName");
  }
  static Future<void> openHiveBox(String boxName, {bool limit = false}) async {
    final box = await Hive.openBox(boxName).onError((error, stackTrace) async {
      Logger.root.severe('Failed to open $boxName Box', error, stackTrace);
      final Directory dir = await getApplicationDocumentsDirectory();
      final String dirPath = dir.path;
      File dbFile = File('$dirPath/$boxName.hive');
      File lockFile = File('$dirPath/$boxName.lock');
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        dbFile = File('$dirPath/BlackHole/$boxName.hive');
        lockFile = File('$dirPath/BlackHole/$boxName.lock');
      }
      await dbFile.delete();
      await lockFile.delete();
      await Hive.openBox(boxName);
      throw 'Failed to open $boxName Box\nError: $error';
    });
    // clear box if it grows large
    if (limit && box.length > 500) {
      box.clear();
    }
  }


  @override
  Future<void> updateFirstTIme(bool isFirstTime) async {
    await prefs.setBool(AppSharedPreferenceConstants.firstTime, isFirstTime);
  }




  @override
  void setLocale(AppLocale appLocale) {

    Locale locale = Get.deviceLocale!;

    switch(appLocale) {
      case AppLocale.english:
        locale = const Locale('en');
        break;
      case AppLocale.spanish:
        locale = const Locale('es');
        break;
      case AppLocale.french:
        locale = const Locale('fr');
        break;
      case AppLocale.deutsch:
        locale = const Locale('de');
        break;
    }

    Get.updateLocale(locale);

  }

  Future<void> setLastNotificationCheckDate(int lastNotificationCheckDate) async {
    logger.d("Setting last time notification were checked");

    try {
      lastNotificationCheckDate = lastNotificationCheckDate;
      await prefs.setInt(AppSharedPreferenceConstants.lastNotificationCheckDate, lastNotificationCheckDate);
    } catch (e) {
      logger.e(e.toString());
    }

  }

}
