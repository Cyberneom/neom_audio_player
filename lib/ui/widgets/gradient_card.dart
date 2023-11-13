import 'package:flutter/material.dart';
import '../../utils/theme/music_player_theme.dart';

class GradientCard extends StatefulWidget {
  final Widget child;
  final BorderRadius? radius;
  final double? elevation;
  const GradientCard({super.key,
    required this.child,
    this.radius,
    this.elevation,
  });
  @override
  GradientCardState createState() => GradientCardState();
}

class GradientCardState extends State<GradientCard> {
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
