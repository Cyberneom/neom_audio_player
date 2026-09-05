import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

import '../../data/implementations/audio_player_equalizer_controller.dart';
import '../../utils/enums/audio_player_equalizer_preset.dart';

/// Full equalizer UI with enable toggle, per-band vertical sliders,
/// and preset buttons.
///
/// Finds [AudioPlayerEqualizerController] via Sint and uses [Obx] for reactive updates.
class EqualizerWidget extends StatefulWidget {

  final Color? accentColor;

  const EqualizerWidget({super.key, this.accentColor});

  @override
  State<EqualizerWidget> createState() => _EqualizerWidgetState();

}

class _EqualizerWidgetState extends State<EqualizerWidget> {

  late final AudioPlayerEqualizerController _controller;
  List<double> _gains = [];
  List<double> _frequencies = [];
  double _minDb = -15;
  double _maxDb = 15;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller = Sint.find<AudioPlayerEqualizerController>();
    _loadParameters();
  }

  Future<void> _loadParameters() async {
    final gains = await _controller.getBandGains();
    final freqs = await _controller.getCenterFrequencies();
    final range = await _controller.getGainRange();
    if (mounted) {
      setState(() {
        _gains = gains;
        _frequencies = freqs;
        _minDb = range.minDb;
        _maxDb = range.maxDb;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEnableToggle(theme, accent),
        if (_controller.isEnabled && _loaded) ...[
          const SizedBox(height: 16),
          _buildPresetRow(theme, accent),
          const SizedBox(height: 20),
          Expanded(child: _buildBandSliders(theme, accent)),
        ],
      ],
    );
  }

  Widget _buildEnableToggle(ThemeData theme, Color accent) {
    return Obx(() => SwitchListTile(
      title: Text('Equalizer', style: theme.textTheme.titleMedium),
      value: _controller.isEnabled,
      activeThumbColor: accent,
      onChanged: (value) async {
        await _controller.setEnabled(value);
        if (value) await _loadParameters();
        setState(() {});
      },
    ));
  }

  Widget _buildPresetRow(ThemeData theme, Color accent) {
    return SizedBox(
      height: 36,
      child: Obx(() => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AudioPlayerEqualizerPreset.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final preset = AudioPlayerEqualizerPreset.values[i];
          final isActive = _controller.activePreset == preset;
          return ChoiceChip(
            label: Text(preset.displayName),
            selected: isActive,
            selectedColor: accent.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: isActive ? accent : theme.textTheme.bodyMedium?.color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
            onSelected: (_) async {
              await _controller.applyPreset(preset);
              await _loadParameters();
            },
          );
        },
      )),
    );
  }

  Widget _buildBandSliders(ThemeData theme, Color accent) {
    if (_gains.isEmpty) return const SizedBox.shrink();

    return Row(
      children: List.generate(_gains.length, (i) {
        final freqHz = _frequencies.length > i ? _frequencies[i] : 0.0;
        final label = freqHz >= 1000
            ? '${(freqHz / 1000).toStringAsFixed(1)}k'
            : '${freqHz.round()}';

        return Expanded(
          child: Column(
            children: [
              Text(
                '${_gains[i].round()} dB',
                style: TextStyle(fontSize: 10, color: theme.hintColor),
              ),
              Expanded(
                child: _VerticalBandSlider(
                  value: _gains[i],
                  min: _minDb,
                  max: _maxDb,
                  accent: accent,
                  onChanged: (gain) async {
                    setState(() => _gains[i] = gain);
                    await _controller.setBandGain(i, gain);
                  },
                ),
              ),
              Text(
                '$label\nHz',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: theme.hintColor),
              ),
            ],
          ),
        );
      }),
    );
  }

}

class _VerticalBandSlider extends StatelessWidget {

  final double value;
  final double min;
  final double max;
  final Color accent;
  final ValueChanged<double> onChanged;

  const _VerticalBandSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitHeight,
      alignment: Alignment.bottomCenter,
      child: Transform.rotate(
        angle: -pi / 2,
        child: SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: Slider(
              activeColor: accent,
              inactiveColor: accent.withValues(alpha: 0.3),
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

}
