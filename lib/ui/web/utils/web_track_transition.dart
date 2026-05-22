import 'package:flutter/material.dart';

/// Animated wrapper that slides + fades [child] whenever [trackKey] changes.
///
/// Used in the web bottom player and the full-screen now playing view to
/// give visual feedback when a new track starts. Stateless: callers pass the
/// current `mediaItem.id` (or any stable identifier) as [trackKey] and a
/// `child` keyed with the same identifier.
class WebTrackTransition extends StatelessWidget {
  final String trackKey;
  final Widget child;
  final Duration duration;
  final Offset slideOffset;

  const WebTrackTransition({
    super.key,
    required this.trackKey,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.slideOffset = const Offset(0, 0.15),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(begin: slideOffset, end: Offset.zero)
            .animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(trackKey),
        child: child,
      ),
    );
  }
}
