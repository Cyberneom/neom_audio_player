import 'package:flutter/material.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_music_player/utils/theme/music_player_theme.dart';

class GradientContainer extends StatefulWidget {
  final Widget? child;
  final bool hasOpacity;
  const GradientContainer({required this.child, this.hasOpacity = true,});
  @override
  _GradientContainerState createState() => _GradientContainerState();
}

class _GradientContainerState extends State<GradientContainer> {
  MusicPlayerTheme currentTheme = MusicPlayerTheme();
  @override
  Widget build(BuildContext context) {
    // ignore: use_decorated_box
    return Container(
      decoration: BoxDecoration(
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

class BottomGradientContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final bool hasOpacity;
  const BottomGradientContainer({
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

class GradientCard extends StatefulWidget {
  final Widget child;
  final BorderRadius? radius;
  final double? elevation;
  const GradientCard({
    required this.child,
    this.radius,
    this.elevation,
  });
  @override
  _GradientCardState createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard> {
  MusicPlayerTheme currentTheme = MusicPlayerTheme();
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.elevation ?? 3,
      shape: RoundedRectangleBorder(
        borderRadius: widget.radius ?? BorderRadius.circular(10.0),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: currentTheme.getCardGradient(),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
