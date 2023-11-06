import 'package:flutter/material.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import '../../utils/theme/music_player_theme.dart';

class BottomGradientContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final bool hasOpacity;
  const BottomGradientContainer({super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius,
    this.hasOpacity = true,
  });
  @override
  _BottomGradientContainerState createState() =>
      _BottomGradientContainerState();
}

class _BottomGradientContainerState extends State<BottomGradientContainer> {
  MusicPlayerTheme currentTheme = MusicPlayerTheme();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.fromLTRB(25, 0, 25, 25),
      padding: widget.padding ?? const EdgeInsets.fromLTRB(10, 15, 10, 15),
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ??
            const BorderRadius.all(Radius.circular(15.0)),
        gradient: widget.hasOpacity ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.getMain(),
            Colors.black45,
          ],
        ) : null,
      ),
      child: widget.child,
    );
  }
}
