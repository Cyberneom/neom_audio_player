// import 'package:flutter/material.dart';
// import 'package:palette_generator/palette_generator.dart';
//
// import '../theme/music_player_theme.dart';
//
// Future<List<Color>> getColors({
//   required ImageProvider imageProvider,
// }) async {
//   PaletteGenerator paletteGenerator;
//   paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
//   final Color dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
//   final Color darkMutedColor = paletteGenerator.darkMutedColor?.color ?? Colors.black;
//   final Color lightMutedColor = paletteGenerator.lightMutedColor?.color ?? dominantColor;
//   if (dominantColor.computeLuminance() < darkMutedColor.computeLuminance()) {
//     // checks if the luminance of the darkMuted color is > than the luminance of the dominant
//     MusicPlayerTheme().playGradientColor = [darkMutedColor, dominantColor,];
//     return [darkMutedColor, dominantColor,];
//   } else if (dominantColor == darkMutedColor) {
//     // if the two colors are the same, it will replace dominantColor by lightMutedColor
//     MusicPlayerTheme().playGradientColor = [
//       lightMutedColor,
//       darkMutedColor,
//     ];
//     return [
//       lightMutedColor,
//       darkMutedColor,
//     ];
//   } else {
//     MusicPlayerTheme().playGradientColor = [
//       dominantColor,
//       darkMutedColor,
//     ];
//     return [
//       dominantColor,
//       darkMutedColor,
//     ];
//   }
// }
