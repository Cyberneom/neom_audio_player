import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_sound/neom_sound.dart';

import '../../../utils/constants/audio_player_translation_constants.dart';
import '../audio_player_controller.dart';

/// 3-dot menu with player options including equalizer access
class PlayerOptionsMenu extends StatelessWidget {
  final AudioPlayerController controller;
  final Color? iconColor;

  const PlayerOptionsMenu({
    super.key,
    required this.controller,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: iconColor ?? theme.iconTheme.color,
      ),
      tooltip: AppTranslationConstants.moreOptions.tr,
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => [
        // Equalizer option
        PopupMenuItem<String>(
          value: 'equalizer',
          child: Row(
            children: [
              Icon(Icons.equalizer, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(AudioPlayerTranslationConstants.equalizer.tr),
            ],
          ),
        ),

        // Sleep timer option
        PopupMenuItem<String>(
          value: 'sleep_timer',
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(AudioPlayerTranslationConstants.sleepTimer.tr),
            ],
          ),
        ),

        const PopupMenuDivider(),

        // Audio quality option
        PopupMenuItem<String>(
          value: 'audio_quality',
          child: Row(
            children: [
              Icon(Icons.high_quality, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(AudioPlayerTranslationConstants.audioQuality.tr),
            ],
          ),
        ),

        // Speed option
        PopupMenuItem<String>(
          value: 'playback_speed',
          child: Row(
            children: [
              Icon(Icons.speed, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(AudioPlayerTranslationConstants.playbackSpeed.tr),
            ],
          ),
        ),

        const PopupMenuDivider(),

        // Go to artist
        if (controller.mediaItem.value?.artist?.isNotEmpty ?? false)
          PopupMenuItem<String>(
            value: 'go_to_artist',
            child: Row(
              children: [
                Icon(Icons.person, color: theme.iconTheme.color),
                const SizedBox(width: 12),
                Text(AudioPlayerTranslationConstants.goToArtist.tr),
              ],
            ),
          ),

        // Go to album
        if (controller.mediaItemAlbum.isNotEmpty)
          PopupMenuItem<String>(
            value: 'go_to_album',
            child: Row(
              children: [
                Icon(Icons.album, color: theme.iconTheme.color),
                const SizedBox(width: 12),
                Text(AudioPlayerTranslationConstants.goToAlbum.tr),
              ],
            ),
          ),

        // Report issue
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(AppTranslationConstants.report.tr),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'equalizer':
        _showEqualizerSheet(context);
        break;
      case 'sleep_timer':
        _showSleepTimerSheet(context);
        break;
      case 'audio_quality':
        _showAudioQualityDialog(context);
        break;
      case 'playback_speed':
        _showPlaybackSpeedDialog(context);
        break;
      case 'go_to_artist':
        controller.goToOwnerProfile();
        break;
      case 'go_to_album':
        controller.gotoPlaylistPlayer();
        break;
      case 'report':
        _showReportDialog(context);
        break;
    }
  }

  void _showEqualizerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Equalizer widget from neom_sound
                const Expanded(
                  child: EqualizerWidget(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              AudioPlayerTranslationConstants.sleepTimer.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SleepTimerChip(label: '15 min', minutes: 15),
                _SleepTimerChip(label: '30 min', minutes: 30),
                _SleepTimerChip(label: '45 min', minutes: 45),
                _SleepTimerChip(label: '1 hour', minutes: 60),
                _SleepTimerChip(label: '2 hours', minutes: 120),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAudioQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AudioPlayerTranslationConstants.audioQuality.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QualityOption(label: 'Auto', subtitle: 'Adjusts based on connection', isSelected: true),
            _QualityOption(label: 'High', subtitle: '320 kbps', isSelected: false),
            _QualityOption(label: 'Normal', subtitle: '160 kbps', isSelected: false),
            _QualityOption(label: 'Low', subtitle: '96 kbps', isSelected: false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslationConstants.close.tr),
          ),
        ],
      ),
    );
  }

  void _showPlaybackSpeedDialog(BuildContext context) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentSpeed = controller.audioHandler?.player.speed ?? 1.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AudioPlayerTranslationConstants.playbackSpeed.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: speeds.map((speed) {
            final isSelected = (currentSpeed - speed).abs() < 0.01;
            return ListTile(
              title: Text('${speed}x'),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                controller.audioHandler?.player.setSpeed(speed);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslationConstants.report.tr),
        content: Text('${AudioPlayerTranslationConstants.reportIssue.tr}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslationConstants.cancel.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Would open report form
            },
            child: Text(AppTranslationConstants.report.tr),
          ),
        ],
      ),
    );
  }
}

class _SleepTimerChip extends StatelessWidget {
  final String label;
  final int minutes;

  const _SleepTimerChip({required this.label, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        // Would set sleep timer
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sleep timer set for $label')),
        );
      },
    );
  }
}

class _QualityOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;

  const _QualityOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(subtitle),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}
