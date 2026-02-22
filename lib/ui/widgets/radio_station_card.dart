import 'package:flutter/material.dart';

import '../../domain/models/radio_station.dart';
import '../../utils/enums/radio_seed_type.dart';

/// Card widget for displaying a radio station
class RadioStationCard extends StatelessWidget {
  final RadioStation station;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onSave;
  final bool isPlaying;
  final bool showSaveButton;

  const RadioStationCard({
    super.key,
    required this.station,
    this.onTap,
    this.onPlay,
    this.onSave,
    this.isPlaying = false,
    this.showSaveButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap ?? onPlay,
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover image / icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: _getGradientForType(station.seedType),
                ),
                child: station.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          station.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildIcon(),
                        ),
                      )
                    : _buildIcon(),
              ),
              const SizedBox(width: 12),

              // Station info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      station.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getIconForType(station.seedType),
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            station.description.isNotEmpty
                                ? station.description
                                : station.seedType.displayName,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (station.mood != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          station.mood!.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSaveButton)
                    IconButton(
                      icon: const Icon(Icons.bookmark_border),
                      onPressed: onSave,
                      tooltip: 'Save station',
                    ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: onPlay,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Icon(
      _getIconForType(station.seedType),
      color: Colors.white,
      size: 28,
    );
  }

  IconData _getIconForType(RadioSeedType type) {
    switch (type) {
      case RadioSeedType.song:
        return Icons.music_note;
      case RadioSeedType.artist:
        return Icons.person;
      case RadioSeedType.genre:
        return Icons.category;
      case RadioSeedType.personalMix:
        return Icons.favorite;
      case RadioSeedType.mood:
        return Icons.mood;
      case RadioSeedType.album:
        return Icons.album;
      case RadioSeedType.playlist:
        return Icons.queue_music;
      case RadioSeedType.decade:
        return Icons.calendar_today;
      case RadioSeedType.discovery:
        return Icons.explore;
      case RadioSeedType.liked:
        return Icons.thumb_up;
    }
  }

  LinearGradient _getGradientForType(RadioSeedType type) {
    switch (type) {
      case RadioSeedType.song:
        return const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case RadioSeedType.artist:
        return const LinearGradient(
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case RadioSeedType.genre:
        return const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case RadioSeedType.personalMix:
        return const LinearGradient(
          colors: [Color(0xFFfa709a), Color(0xFFfee140)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case RadioSeedType.mood:
        return const LinearGradient(
          colors: [Color(0xFF30cfd0), Color(0xFF330867)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case RadioSeedType.discovery:
        return const LinearGradient(
          colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

/// Grid card for radio station
class RadioStationGridCard extends StatelessWidget {
  final RadioStation station;
  final VoidCallback? onTap;
  final bool isPlaying;

  const RadioStationGridCard({
    super.key,
    required this.station,
    this.onTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getColorsForMood(station.mood),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: station.imageUrl.isNotEmpty
                        ? Image.network(
                            station.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.radio,
                              size: 48,
                              color: Colors.white54,
                            ),
                          )
                        : const Icon(
                            Icons.radio,
                            size: 48,
                            color: Colors.white54,
                          ),
                  ),
                  if (isPlaying)
                    Container(
                      color: Colors.black38,
                      child: const Center(
                        child: Icon(
                          Icons.equalizer,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    station.description.isNotEmpty
                        ? station.description
                        : station.seedType.displayName,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getColorsForMood(RadioMood? mood) {
    switch (mood) {
      case RadioMood.energetic:
      case RadioMood.workout:
        return [const Color(0xFFff512f), const Color(0xFFdd2476)];
      case RadioMood.relaxed:
      case RadioMood.chill:
        return [const Color(0xFF11998e), const Color(0xFF38ef7d)];
      case RadioMood.happy:
        return [const Color(0xFFf7971e), const Color(0xFFffd200)];
      case RadioMood.melancholic:
        return [const Color(0xFF4b6cb7), const Color(0xFF182848)];
      case RadioMood.focus:
        return [const Color(0xFF2193b0), const Color(0xFF6dd5ed)];
      case RadioMood.party:
        return [const Color(0xFFf953c6), const Color(0xFFb91d73)];
      case RadioMood.sleep:
        return [const Color(0xFF0f0c29), const Color(0xFF302b63)];
      case RadioMood.romantic:
        return [const Color(0xFFf5576c), const Color(0xFFf093fb)];
      default:
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
    }
  }
}
