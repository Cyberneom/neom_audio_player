import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:sint/sint.dart';

import '../../../domain/models/media_lyrics.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../player/lyrics/lyrics.dart';

/// Lyrics panel for the full-screen Now Playing view.
class WebLyricsPanel extends StatefulWidget {
  final MediaItem mediaItem;

  const WebLyricsPanel({Key? key, required this.mediaItem}) : super(key: key);

  @override
  State<WebLyricsPanel> createState() => _WebLyricsPanelState();
}

class _WebLyricsPanelState extends State<WebLyricsPanel> {
  MediaLyrics _lyrics = MediaLyrics();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void didUpdateWidget(covariant WebLyricsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaItem.id != widget.mediaItem.id) {
      _fetchLyrics();
    }
  }

  Future<void> _fetchLyrics() async {
    setState(() => _isLoading = true);

    // Check extras for embedded lyrics first
    final extras = widget.mediaItem.extras;
    String embeddedLyrics = '';
    if (extras != null) {
      embeddedLyrics = (extras['lyrics'] as String?) ?? '';
      if (embeddedLyrics.isEmpty) {
        embeddedLyrics = (extras['description'] as String?) ?? '';
      }
    }

    if (embeddedLyrics.isNotEmpty) {
      _lyrics = MediaLyrics(
        mediaId: widget.mediaItem.id,
        lyrics: embeddedLyrics.replaceAll('&nbsp;', ''),
      );
    } else {
      _lyrics = await Lyrics.getLyrics(
        id: widget.mediaItem.id,
        title: widget.mediaItem.title,
        artist: widget.mediaItem.artist ?? '',
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AudioPlayerTranslationConstants.lyrics.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColor.getMain()))
                : _lyrics.lyrics.isEmpty
                    ? Center(
                        child: Text(
                          AudioPlayerTranslationConstants.noLyricsAvailable.tr,
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          _lyrics.lyrics,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            height: 1.8,
                          ),
                        ),
                      ),
          ),
          if (_lyrics.source.name.isNotEmpty && _lyrics.lyrics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${AudioPlayerTranslationConstants.poweredBy} ${_lyrics.source.name}',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
