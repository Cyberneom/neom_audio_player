import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

import '../../data/implementations/enhanced_playback_controller.dart';

/// Bottom sheet panel for controlling playback speed and pitch.
///
/// Provides sliders for fine control, preset chips for quick selection,
/// and text display of current values. Finds [EnhancedPlaybackController]
/// via Sint and uses [Obx] for reactive updates.
class PlaybackControlPanel extends StatelessWidget {

  final Color? accentColor;

  const PlaybackControlPanel({super.key, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;
    final controller = Sint.find<EnhancedPlaybackController>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('Playback Controls', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 24),

          // Speed section
          _buildSection(
            context: context,
            theme: theme,
            accent: accent,
            label: 'Speed',
            getValue: () => controller.playbackSpeed,
            setValue: (v) => controller.setPlaybackSpeed(v),
            reset: () => controller.resetPlaybackSpeed(),
            min: 0.5,
            max: 2.0,
            presets: controller.speedPresets,
            formatValue: (v) => '${v.toStringAsFixed(2)}x',
          ),

          const SizedBox(height: 24),

          // Pitch section
          _buildSection(
            context: context,
            theme: theme,
            accent: accent,
            label: 'Pitch',
            getValue: () => controller.pitch,
            setValue: (v) => controller.setPitch(v),
            reset: () => controller.resetPitch(),
            min: 0.5,
            max: 2.0,
            presets: const [0.5, 0.75, 1.0, 1.25, 1.5],
            formatValue: (v) => '${v.toStringAsFixed(2)}x',
          ),

          const SizedBox(height: 16),

          // Reset all button
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await controller.resetPlaybackSpeed();
                await controller.resetPitch();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset All'),
              style: TextButton.styleFrom(
                foregroundColor: theme.hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required ThemeData theme,
    required Color accent,
    required String label,
    required double Function() getValue,
    required Future<void> Function(double) setValue,
    required Future<void> Function() reset,
    required double min,
    required double max,
    required List<double> presets,
    required String Function(double) formatValue,
  }) {
    return Obx(() {
      final value = getValue();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.titleSmall),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formatValue(value),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (value != 1.0) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: reset,
                      child: Icon(Icons.refresh, size: 16, color: theme.hintColor),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: accent.withValues(alpha: 0.2),
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.1),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: (v) => setValue(v),
            ),
          ),

          // Preset chips
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final preset = presets[i];
                final isActive = (value - preset).abs() < 0.01;
                return ChoiceChip(
                  label: Text(formatValue(preset)),
                  selected: isActive,
                  selectedColor: accent.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isActive ? accent : theme.textTheme.bodySmall?.color,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setValue(preset),
                );
              },
            ),
          ),
        ],
      );
    });
  }

}
