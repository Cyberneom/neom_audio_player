import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

import '../../data/implementations/listening_stats_controller.dart';
import '../../domain/models/listening_stats.dart';
import '../../domain/use_cases/listening_stats_service.dart';

/// Card showing listening stats summary
class ListeningStatsCard extends StatelessWidget {
  final Color? accentColor;
  final VoidCallback? onTap;

  const ListeningStatsCard({
    super.key,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Sint.find<ListeningStatsController>();
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

    return Obx(() {
      final stats = controller.stats;
      if (stats == null) {
        return const SizedBox.shrink();
      }

      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.15),
                  accent.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Listening',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: accent),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      value: stats.formattedTotalTime,
                      label: 'Total Time',
                      icon: Icons.timer,
                      color: accent,
                    ),
                    _StatItem(
                      value: stats.totalSongsPlayed.toString(),
                      label: 'Songs',
                      icon: Icons.music_note,
                      color: accent,
                    ),
                    _StatItem(
                      value: '${stats.currentStreak}',
                      label: 'Day Streak',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ],
                ),

                // Top artist preview
                if (stats.topArtists.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.2),
                        ),
                        child: stats.topArtists.first.imageUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  stats.topArtists.first.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      Icon(Icons.person, color: accent),
                                ),
                              )
                            : Icon(Icons.person, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Top Artist',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              stats.topArtists.first.artistName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${stats.topArtists.first.playCount} plays',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Full listening stats page
class ListeningStatsPage extends StatelessWidget {
  const ListeningStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Sint.find<ListeningStatsController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Activity'),
      ),
      body: Obx(() {
        final stats = controller.stats;
        if (stats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Time stats cards
            Row(
              children: [
                Expanded(
                  child: _TimeCard(
                    title: 'Today',
                    value: stats.formattedTodayTime,
                    icon: Icons.today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeCard(
                    title: 'This Week',
                    value: _formatMs(stats.weekListeningTimeMs),
                    icon: Icons.date_range,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeCard(
                    title: 'This Month',
                    value: _formatMs(stats.monthListeningTimeMs),
                    icon: Icons.calendar_month,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeCard(
                    title: 'All Time',
                    value: stats.formattedTotalTime,
                    icon: Icons.all_inclusive,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Streak card
            _StreakCard(
              currentStreak: stats.currentStreak,
              longestStreak: stats.longestStreak,
            ),
            const SizedBox(height: 24),

            // Top Artists
            if (stats.topArtists.isNotEmpty) ...[
              Text(
                'Top Artists',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...stats.topArtists.take(5).map((artist) => _ArtistTile(
                    artist: artist,
                  )),
              const SizedBox(height: 24),
            ],

            // Top Songs
            if (stats.topSongs.isNotEmpty) ...[
              Text(
                'Top Songs',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...stats.topSongs.take(5).map((song) => _SongTile(
                    song: song,
                  )),
              const SizedBox(height: 24),
            ],

            // Achievements preview
            if (controller.achievements.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Achievements',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to achievements page
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.achievements
                      .where((a) => a.isUnlocked)
                      .length,
                  itemBuilder: (context, index) {
                    final achievement = controller.achievements
                        .where((a) => a.isUnlocked)
                        .toList()[index];
                    return _AchievementChip(achievement: achievement);
                  },
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  String _formatMs(int ms) {
    final hours = ms ~/ (1000 * 60 * 60);
    final minutes = (ms ~/ (1000 * 60)) % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class _TimeCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _TimeCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const _StreakCard({
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currentStreak Day Streak!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Longest: $longestStreak days',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistTile extends StatelessWidget {
  final ArtistStat artist;

  const _ArtistTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage:
            artist.imageUrl != null ? NetworkImage(artist.imageUrl!) : null,
        child: artist.imageUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(artist.artistName),
      subtitle: Text('${artist.playCount} plays'),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        child: Center(
          child: Text(
            '#${artist.rank}',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final SongStat song;

  const _SongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: song.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(song.imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: song.imageUrl == null
            ? const Icon(Icons.music_note)
            : null,
      ),
      title: Text(
        song.songTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(song.artistName),
      trailing: Text(
        '${song.playCount}x',
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final Achievement achievement;

  const _AchievementChip({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              color: _getTierColor(achievement.tier),
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }
}
