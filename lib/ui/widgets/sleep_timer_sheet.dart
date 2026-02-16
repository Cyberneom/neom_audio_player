import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

import '../../data/implementations/enhanced_playback_controller.dart';
import '../../utils/enums/playback_mode.dart';

/// Bottom sheet for setting sleep timer
class SleepTimerSheet extends StatelessWidget {
  final Color? accentColor;
  final VoidCallback? onTimerSet;

  const SleepTimerSheet({
    super.key,
    this.accentColor,
    this.onTimerSet,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Sint.find<EnhancedPlaybackController>();
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

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
          // Handle
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
          const SizedBox(height: 20),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sleep Timer',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Obx(() {
                if (controller.isSleepTimerActive) {
                  return TextButton(
                    onPressed: () => controller.cancelSleepTimer(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          const SizedBox(height: 8),

          // Current timer status
          Obx(() {
            if (controller.isSleepTimerActive) {
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: accent),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timer Active',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        StreamBuilder<Duration>(
                          stream: controller.sleepTimerStream,
                          builder: (context, snapshot) {
                            final remaining = snapshot.data ?? controller.sleepTimerRemaining;
                            return Text(
                              _formatDuration(remaining),
                              style: theme.textTheme.bodyMedium,
                            );
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => controller.extendSleepTimer(
                        const Duration(minutes: 5),
                      ),
                      tooltip: 'Add 5 minutes',
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Timer options
          Text(
            'Stop playing in',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 12),

          // Preset grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in SleepTimerPreset.values)
                if (preset != SleepTimerPreset.custom)
                  _TimerChip(
                    label: preset.displayName,
                    isSelected: controller.activeSleepTimerPreset == preset,
                    accentColor: accent,
                    onTap: () {
                      controller.setSleepTimer(preset);
                      onTimerSet?.call();
                    },
                  ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom time button
          OutlinedButton.icon(
            onPressed: () => _showCustomTimePicker(context, controller),
            icon: const Icon(Icons.schedule),
            label: const Text('Set custom time'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: 0.5)),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),

          // Fade out option
          Obx(() => SwitchListTile(
                title: const Text('Fade out'),
                subtitle: const Text('Gradually lower volume before stopping'),
                value: controller.sleepTimerFadeOut,
                onChanged: (value) {
                  // Would update settings
                },
                activeColor: accent,
                contentPadding: EdgeInsets.zero,
              )),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showCustomTimePicker(
    BuildContext context,
    EnhancedPlaybackController controller,
  ) async {
    final result = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 30),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (result != null) {
      final duration = Duration(
        hours: result.hour,
        minutes: result.minute,
      );
      controller.setCustomSleepTimer(duration);
      onTimerSet?.call();
    }
  }
}

class _TimerChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _TimerChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? accentColor : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? accentColor : accentColor.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : accentColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Show sleep timer bottom sheet
Future<void> showSleepTimerSheet(
  BuildContext context, {
  Color? accentColor,
  VoidCallback? onTimerSet,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SleepTimerSheet(
      accentColor: accentColor,
      onTimerSet: onTimerSet,
    ),
  );
}
