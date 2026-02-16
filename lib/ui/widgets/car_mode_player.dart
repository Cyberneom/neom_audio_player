import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sint/sint.dart';

import '../../data/implementations/enhanced_playback_controller.dart';
import '../../utils/enums/playback_mode.dart';

/// Full screen car mode player with large touch targets
class CarModePlayer extends StatefulWidget {
  /// Current song title
  final String title;

  /// Current artist
  final String artist;

  /// Album art URL
  final String? artUrl;

  /// Whether currently playing
  final bool isPlaying;

  /// Current position
  final Duration position;

  /// Total duration
  final Duration duration;

  /// Whether shuffle is on
  final bool isShuffled;

  /// Repeat mode (0 = off, 1 = all, 2 = one)
  final int repeatMode;

  /// Callbacks
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onSkipNext;
  final VoidCallback? onSkipPrevious;
  final VoidCallback? onToggleShuffle;
  final VoidCallback? onToggleRepeat;
  final VoidCallback? onExit;
  final ValueChanged<Duration>? onSeek;

  const CarModePlayer({
    super.key,
    required this.title,
    required this.artist,
    this.artUrl,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffled = false,
    this.repeatMode = 0,
    this.onPlay,
    this.onPause,
    this.onSkipNext,
    this.onSkipPrevious,
    this.onToggleShuffle,
    this.onToggleRepeat,
    this.onExit,
    this.onSeek,
  });

  @override
  State<CarModePlayer> createState() => _CarModePlayerState();
}

class _CarModePlayerState extends State<CarModePlayer> {
  @override
  void initState() {
    super.initState();
    // Force landscape and hide system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore orientations and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Sint.find<EnhancedPlaybackController>();
    final layout = controller.carModeLayout;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: layout == CarModeLayout.simple
            ? _buildSimpleLayout(theme)
            : layout == CarModeLayout.standard
                ? _buildStandardLayout(theme)
                : _buildFullLayout(theme),
      ),
    );
  }

  Widget _buildSimpleLayout(ThemeData theme) {
    return Row(
      children: [
        // Play/Pause (large)
        Expanded(
          child: _LargeButton(
            icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
            onTap: widget.isPlaying ? widget.onPause : widget.onPlay,
            color: Colors.white,
            size: 120,
          ),
        ),

        // Skip buttons
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LargeButton(
              icon: Icons.skip_previous,
              onTap: widget.onSkipPrevious,
              color: Colors.white70,
              size: 80,
            ),
            const SizedBox(height: 40),
            _LargeButton(
              icon: Icons.skip_next,
              onTap: widget.onSkipNext,
              color: Colors.white70,
              size: 80,
            ),
          ],
        ),

        // Exit button
        Padding(
          padding: const EdgeInsets.all(16),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 32),
            onPressed: widget.onExit,
          ),
        ),
      ],
    );
  }

  Widget _buildStandardLayout(ThemeData theme) {
    return Row(
      children: [
        // Album art
        if (widget.artUrl != null)
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(widget.artUrl!),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          )
        else
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade800,
              ),
              child: const Icon(
                Icons.music_note,
                size: 80,
                color: Colors.white54,
              ),
            ),
          ),

        // Controls
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Song info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.artist,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _CarModeProgressBar(
                  position: widget.position,
                  duration: widget.duration,
                  onSeek: widget.onSeek,
                ),
              ),
              const SizedBox(height: 32),

              // Main controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LargeButton(
                    icon: Icons.skip_previous,
                    onTap: widget.onSkipPrevious,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(width: 24),
                  _LargeButton(
                    icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
                    onTap: widget.isPlaying ? widget.onPause : widget.onPlay,
                    color: Colors.white,
                    size: 80,
                    filled: true,
                  ),
                  const SizedBox(width: 24),
                  _LargeButton(
                    icon: Icons.skip_next,
                    onTap: widget.onSkipNext,
                    color: Colors.white,
                    size: 60,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Exit button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 32),
                onPressed: widget.onExit,
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: widget.isShuffled ? Colors.green : Colors.white54,
                      size: 28,
                    ),
                    onPressed: widget.onToggleShuffle,
                  ),
                  IconButton(
                    icon: Icon(
                      widget.repeatMode == 2
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: widget.repeatMode > 0 ? Colors.green : Colors.white54,
                      size: 28,
                    ),
                    onPressed: widget.onToggleRepeat,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullLayout(ThemeData theme) {
    return Row(
      children: [
        // Album art (smaller)
        Container(
          width: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: widget.artUrl != null
                ? DecorationImage(
                    image: NetworkImage(widget.artUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: Colors.grey.shade800,
          ),
          child: widget.artUrl == null
              ? const Icon(Icons.music_note, size: 60, color: Colors.white54)
              : null,
        ),

        // Main content
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Song info
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.artist,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),

              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _CarModeProgressBar(
                  position: widget.position,
                  duration: widget.duration,
                  onSeek: widget.onSeek,
                ),
              ),
              const SizedBox(height: 16),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: widget.isShuffled ? Colors.green : Colors.white54,
                    ),
                    onPressed: widget.onToggleShuffle,
                  ),
                  const SizedBox(width: 8),
                  _LargeButton(
                    icon: Icons.skip_previous,
                    onTap: widget.onSkipPrevious,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(width: 8),
                  _LargeButton(
                    icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
                    onTap: widget.isPlaying ? widget.onPause : widget.onPlay,
                    color: Colors.white,
                    size: 64,
                    filled: true,
                  ),
                  const SizedBox(width: 8),
                  _LargeButton(
                    icon: Icons.skip_next,
                    onTap: widget.onSkipNext,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      widget.repeatMode == 2 ? Icons.repeat_one : Icons.repeat,
                      color: widget.repeatMode > 0 ? Colors.green : Colors.white54,
                    ),
                    onPressed: widget.onToggleRepeat,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Queue preview
        Container(
          width: 200,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Up Next',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: widget.onExit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: 5, // Show next 5 songs
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey.shade700,
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Song ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Artist',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LargeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final bool filled;

  const _LargeButton({
    required this.icon,
    this.onTap,
    required this.color,
    required this.size,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: filled ? null : Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(
            icon,
            color: filled ? Colors.black : color,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

class _CarModeProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration>? onSeek;

  const _CarModeProgressBar({
    required this.position,
    required this.duration,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              if (onSeek != null && duration.inMilliseconds > 0) {
                onSeek!(Duration(
                  milliseconds: (value * duration.inMilliseconds).round(),
                ));
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
