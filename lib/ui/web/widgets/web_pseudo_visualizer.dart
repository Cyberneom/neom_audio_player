import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight, decorative pseudo audio visualizer for the web layout.
///
/// We do not have access to real FFT data (`just_audio` does not expose it),
/// so this widget animates a fixed number of bars with a deterministic
/// pseudo-random pattern. It looks alive enough to feel like a real meter and
/// stays cheap (single AnimationController, CustomPainter, no per-frame
/// allocations).
///
/// Set [playing] to false to freeze the bars at zero height — used to react
/// to the playback state without rebuilding the widget tree.
class WebPseudoVisualizer extends StatefulWidget {
  final int barCount;
  final double width;
  final double height;
  final Color color;
  final bool playing;
  final double barGap;

  const WebPseudoVisualizer({
    super.key,
    required this.color,
    this.barCount = 4,
    this.width = 22,
    this.height = 18,
    this.playing = true,
    this.barGap = 2,
  });

  @override
  State<WebPseudoVisualizer> createState() => _WebPseudoVisualizerState();
}

class _WebPseudoVisualizerState extends State<WebPseudoVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _phases;

  @override
  void initState() {
    super.initState();
    final rand = math.Random(widget.barCount * 31);
    _phases = List<double>.generate(
      widget.barCount,
      (_) => rand.nextDouble() * math.pi * 2,
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.playing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant WebPseudoVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing != oldWidget.playing) {
      if (widget.playing) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _BarsPainter(
            t: _controller.value,
            phases: _phases,
            color: widget.color,
            playing: widget.playing,
            gap: widget.barGap,
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  final double t;
  final List<double> phases;
  final Color color;
  final bool playing;
  final double gap;

  _BarsPainter({
    required this.t,
    required this.phases,
    required this.color,
    required this.playing,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = phases.length;
    if (n == 0) return;
    final barWidth = (size.width - gap * (n - 1)) / n;
    final paint = Paint()..color = color;
    final radius = Radius.circular(barWidth / 2);

    for (var i = 0; i < n; i++) {
      final wave = playing
          ? (math.sin(t * math.pi * 2 + phases[i]) * 0.5 + 0.5)
          : 0.0;
      // Keep a minimum so bars never fully collapse while playing.
      final h = (playing ? 0.25 + wave * 0.75 : 0.1) * size.height;
      final left = i * (barWidth + gap);
      final top = size.height - h;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, top, barWidth, h),
          topLeft: radius,
          topRight: radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.t != t || old.color != color || old.playing != playing;
}
