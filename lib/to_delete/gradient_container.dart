// import 'package:flutter/material.dart';
// import 'package:neom_commons/core/utils/app_color.dart';
// import '../../utils/theme/music_player_theme.dart';
//
// class GradientContainer extends StatefulWidget {
//   final Widget? child;
//   final bool hasOpacity;
//   const GradientContainer({super.key, required this.child, this.hasOpacity = true,});
//   @override
//   _GradientContainerState createState() => _GradientContainerState();
// }
//
// class _GradientContainerState extends State<GradientContainer> {
//   MusicPlayerTheme currentTheme = MusicPlayerTheme();
//   @override
//   Widget build(BuildContext context) {
//     // ignore: use_decorated_box
//     return Container(
//       decoration: BoxDecoration(
//         gradient: widget.hasOpacity ? LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             AppColor.getMain(),
//             Colors.black45,
//           ],
//         ) : null,
//       ),
//       child: widget.child,
//     );
//   }
// }
