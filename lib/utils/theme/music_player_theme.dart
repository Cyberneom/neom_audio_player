import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';
class MusicPlayerTheme with ChangeNotifier {

  final bool _useSystemTheme = Hive.box(AppHiveBox.settings.name).get('useSystemTheme', defaultValue: false) as bool;
  String accentColor = Hive.box(AppHiveBox.settings.name).get('themeColor', defaultValue: 'Teal') as String;
  String canvasColor = Hive.box(AppHiveBox.settings.name).get('canvasColor', defaultValue: 'Grey') as String;
  String cardColor = Hive.box(AppHiveBox.settings.name).get('cardColor', defaultValue: 'Grey900') as String;
  int backGrad = Hive.box(AppHiveBox.settings.name).get('backGrad', defaultValue: 2) as int;
  int cardGrad = Hive.box(AppHiveBox.settings.name).get('cardGrad', defaultValue: 4) as int;
  int bottomGrad = Hive.box(AppHiveBox.settings.name).get('bottomGrad', defaultValue: 3) as int;
  int colorHue = Hive.box(AppHiveBox.settings.name).get('colorHue', defaultValue: 400) as int;

  ThemeMode currentTheme() {
    if (_useSystemTheme == true) {
      return ThemeMode.system;
    } else {
      return ThemeMode.dark;
    }
  }

  int currentHue() {
    return colorHue;
  }

  Color getCanvasColor() {
    if (canvasColor == 'Black') return Colors.black;
    if (canvasColor == 'Grey') return Colors.grey[900]!;
    return Colors.grey[900]!;
  }

  Color getCardColor() {
    if (cardColor == 'Grey800') return Colors.grey[800]!;
    if (cardColor == 'Grey850') return Colors.grey[850]!;
    if (cardColor == 'Grey900') return Colors.grey[900]!;
    if (cardColor == 'Black') return Colors.black;
    return Colors.grey[850]!;
  }

  // List<Color> getCardGradient() {
  //   return _cardOpt[cardGrad];
  // }

  Color currentColor() {
    switch (accentColor) {
      case 'Red':
        return Colors.redAccent[currentHue()]!;
      case 'Teal':
        return Colors.tealAccent[currentHue()]!;
      case 'Light Blue':
        return Colors.lightBlueAccent[currentHue()]!;
      case 'Yellow':
        return Colors.yellowAccent[currentHue()]!;
      case 'Orange':
        return Colors.orangeAccent[currentHue()]!;
      case 'Blue':
        return Colors.blueAccent[currentHue()]!;
      case 'Cyan':
        return Colors.cyanAccent[currentHue()]!;
      case 'Lime':
        return Colors.limeAccent[currentHue()]!;
      case 'Pink':
        return Colors.pinkAccent[currentHue()]!;
      case 'Green':
        return Colors.greenAccent[currentHue()]!;
      case 'Amber':
        return Colors.amberAccent[currentHue()]!;
      case 'Indigo':
        return Colors.indigoAccent[currentHue()]!;
      case 'Purple':
        return Colors.purpleAccent[currentHue()]!;
      case 'Deep Orange':
        return Colors.deepOrangeAccent[currentHue()]!;
      case 'Deep Purple':
        return Colors.deepPurpleAccent[currentHue()]!;
      case 'Light Green':
        return Colors.lightGreenAccent[currentHue()]!;
      case 'White':
        return Colors.white;

      default:
        return Colors.tealAccent[400]!;
    }
  }

}
