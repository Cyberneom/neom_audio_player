import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:sint/sint.dart';

import '../../../domain/models/media_lyrics.dart';
import '../../../neom_audio_handler.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../player/lyrics/lyrics.dart';
import '../utils/web_lrc_parser.dart';

/// Lyrics panel for the full-screen Now Playing view.
///
/// If the loaded lyrics contain LRC-style timestamps (`[mm:ss.xx]`), the
/// panel parses them, highlights the active line in real time, and
/// auto-scrolls to keep it centred — Apple Music Sing / Spotify lyrics
/// behaviour. Plain-text lyrics fall back to the previous static view.
class WebLyricsPanel extends StatefulWidget {
  final MediaItem mediaItem;

  const WebLyricsPanel({super.key, required this.mediaItem});

  @override
  State<WebLyricsPanel> createState() => _WebLyricsPanelState();
}

class _WebLyricsPanelState extends State<WebLyricsPanel> {
  MediaLyrics _lyrics = MediaLyrics();
  bool _isLoading = true;

  /// Parsed LRC entries (empty when the lyrics are plain text).
  List<LrcEntry> _entries = const [];
  int _activeIndex = -1;

  StreamSubscription<Duration>? _positionSub;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};

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

  @override
  void dispose() {
    _positionSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    setState(() => _isLoading = true);
    _detachPositionStream();

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

    if (!mounted) return;
    final parsed = parseLrc(_lyrics.lyrics);
    setState(() {
      _entries = parsed;
      _activeIndex = -1;
      _lineKeys
        ..clear()
        ..addEntries(List.generate(
          parsed.length,
          (i) => MapEntry(i, GlobalKey()),
        ));
      _isLoading = false;
    });

    if (parsed.isNotEmpty) _attachPositionStream();
  }

  void _attachPositionStream() {
    try {
      final handler = Sint.find<NeomAudioHandler>();
      _positionSub = handler.player.positionStream.listen(_onPosition);
    } catch (_) {
      // Audio handler not available — silently keep static view.
    }
  }

  void _detachPositionStream() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  void _onPosition(Duration pos) {
    if (_entries.isEmpty || !mounted) return;
    int idx = _activeIndex;
    // Linear walk forward most of the time; binary search if we jumped back.
    if (idx >= 0 && idx < _entries.length && pos >= _entries[idx].timestamp) {
      while (idx + 1 < _entries.length &&
          pos >= _entries[idx + 1].timestamp) {
        idx++;
      }
    } else {
      idx = _binarySearchFloor(pos);
    }
    if (idx != _activeIndex) {
      setState(() => _activeIndex = idx);
      _scrollToActive(idx);
    }
  }

  int _binarySearchFloor(Duration pos) {
    int lo = 0;
    int hi = _entries.length - 1;
    int result = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_entries[mid].timestamp <= pos) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return result;
  }

  void _scrollToActive(int index) {
    if (!_scrollController.hasClients) return;
    final key = _lineKeys[index];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.4,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AudioPlayerTranslationConstants.lyrics.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_entries.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColor.getMain().withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SYNCED',
                    style: TextStyle(
                      color: AppColor.getMain(),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
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

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColor.getMain()));
    }
    if (_lyrics.lyrics.isEmpty) {
      return Center(
        child: Text(
          AudioPlayerTranslationConstants.noLyricsAvailable.tr,
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_entries.isEmpty) {
      // Plain-text fallback (no LRC timestamps detected).
      return SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Text(
          _lyrics.lyrics,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
            height: 1.8,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: _entries.length,
      itemBuilder: (_, i) {
        final isActive = i == _activeIndex;
        final isPast = i < _activeIndex;
        return Container(
          key: _lineKeys[i],
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : isPast
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.55),
              fontSize: isActive ? 22 : 17,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              height: 1.4,
              letterSpacing: isActive ? -0.3 : 0,
            ),
            child: Text(_entries[i].text),
          ),
        );
      },
    );
  }
}

