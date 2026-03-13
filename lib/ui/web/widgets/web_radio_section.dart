import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:sint/sint.dart';

import '../../../data/implementations/radio_controller.dart';
import '../../../domain/models/radio_station.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/mappers/media_item_mapper.dart';

/// Horizontal shelf of quick-start radio station cards for WebMainFeed.
class WebRadioSection extends StatefulWidget {
  const WebRadioSection({Key? key}) : super(key: key);

  @override
  State<WebRadioSection> createState() => _WebRadioSectionState();
}

class _WebRadioSectionState extends State<WebRadioSection> {

  List<_RadioOption> _buildOptions() {
    final options = <_RadioOption>[
      _RadioOption(
        label: AudioPlayerTranslationConstants.personalMix.tr,
        icon: Icons.person,
        gradient: [Colors.deepPurple, Colors.purple.shade300],
        onTap: () => _startRadio(() => Sint.find<RadioController>().createPersonalMix()),
      ),
      _RadioOption(
        label: AudioPlayerTranslationConstants.discoveryRadio.tr,
        icon: Icons.explore,
        gradient: [Colors.teal.shade700, Colors.teal.shade300],
        onTap: () => _startRadio(() => Sint.find<RadioController>().createDiscoveryStation()),
      ),
      _RadioOption(
        label: AudioPlayerTranslationConstants.likedSongsRadio.tr,
        icon: Icons.favorite,
        gradient: [Colors.pink.shade700, Colors.pink.shade300],
        onTap: () => _startRadio(() => Sint.find<RadioController>().createLikedSongsStation()),
      ),
    ];

    // Add genre-based radio options from user's profile
    try {
      final profile = Sint.find<UserService>().profile;
      final genres = profile.genres;
      if (genres != null && genres.isNotEmpty) {
        final genreNames = genres.values
            .where((g) => g.name.isNotEmpty)
            .take(4)
            .toList();
        for (int i = 0; i < genreNames.length; i++) {
          final genre = genreNames[i];
          options.add(_RadioOption(
            label: '${genre.name} ${AudioPlayerTranslationConstants.playRadio.tr}',
            icon: Icons.radio,
            gradient: _genreGradient(i),
            onTap: () => _startRadio(
              () => Sint.find<RadioController>().createStationFromGenre(genre.name),
            ),
          ));
        }
      }
    } catch (_) {}

    return options;
  }

  List<Color> _genreGradient(int index) {
    const gradients = [
      [Color(0xFF1DB954), Color(0xFF1ED760)],
      [Color(0xFFE91E63), Color(0xFFFF5252)],
      [Color(0xFF2196F3), Color(0xFF42A5F5)],
      [Color(0xFFFF9800), Color(0xFFFFB74D)],
    ];
    return gradients[index % gradients.length];
  }

  Future<void> _startRadio(Future<RadioStation> Function() generator) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AudioPlayerTranslationConstants.radioStarted.tr),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColor.surfaceElevated,
        ),
      );

      final station = await generator();
      if (station.queue.isNotEmpty) {
        final items = station.queue
            .map((m) => MediaItemMapper.toAppMediaItem(m))
            .toList();
        Sint.find<AudioPlayerInvokerService>().init(
          mediaItems: items,
          playItem: true,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _buildOptions();
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AudioPlayerTranslationConstants.radioSection.tr,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: options.length,
            itemBuilder: (context, index) => _WebRadioCard(option: options[index]),
          ),
        ),
      ],
    );
  }
}

class _RadioOption {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _RadioOption({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class _WebRadioCard extends StatefulWidget {
  final _RadioOption option;
  const _WebRadioCard({required this.option});

  @override
  State<_WebRadioCard> createState() => _WebRadioCardState();
}

class _WebRadioCardState extends State<_WebRadioCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.option.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.option.gradient,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isHovered
                ? [BoxShadow(color: widget.option.gradient.first.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Stack(
            children: [
              // Background icon
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  widget.option.icon,
                  size: 80,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.radio, color: Colors.white, size: 28),
                    const Spacer(),
                    Text(
                      widget.option.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Play button on hover
              if (_isHovered)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: widget.option.gradient.first, size: 24),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
