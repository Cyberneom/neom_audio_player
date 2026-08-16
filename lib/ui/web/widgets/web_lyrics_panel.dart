import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/device_utilities.dart';
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
  final bool compact;

  const WebLyricsPanel({
    super.key,
    required this.mediaItem,
    this.compact = false,
  });

  @override
  State<WebLyricsPanel> createState() => _WebLyricsPanelState();
}

class _WebLyricsPanelState extends State<WebLyricsPanel> {
  MediaLyrics _lyrics = MediaLyrics();
  bool _isLoading = true;

  /// Parsed LRC entries (empty when the lyrics are plain text).
  List<LrcEntry> _entries = const [];
  int _activeIndex = -1;

  double _fontSize = 18.0;

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

  void _seekTo(Duration timestamp) {
    try {
      final handler = Sint.find<NeomAudioHandler>();
      handler.player.seek(timestamp);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              const Icon(Icons.lyrics_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                AudioPlayerTranslationConstants.lyrics.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              if (_entries.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColor.getMain().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColor.getMain().withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColor.getMain(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'KARAOKE SYNC',
                        style: TextStyle(
                          color: AppColor.getMain(),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Font size controls
              Tooltip(
                message: 'Reducir tamaño de letra',
                child: IconButton(
                  icon: const Icon(Icons.text_decrease_rounded, color: Colors.white60, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    if (_fontSize > 14) setState(() => _fontSize -= 2);
                  },
                ),
              ),
              Tooltip(
                message: 'Aumentar tamaño de letra',
                child: IconButton(
                  icon: const Icon(Icons.text_increase_rounded, color: Colors.white60, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    if (_fontSize < 28) setState(() => _fontSize += 2);
                  },
                ),
              ),
              // Copy lyrics button
              if (_lyrics.lyrics.isNotEmpty)
                Tooltip(
                  message: 'Copiar letra',
                  child: IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.white60, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      DeviceUtilities.copyToClipboard(text: _lyrics.lyrics);
                      AppUtilities.showSnackBar(message: 'Letra copiada al portapapeles');
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 16),
          // Lyrics Body
          Expanded(child: _buildBody()),
          if (_lyrics.source.name.isNotEmpty && _lyrics.lyrics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AudioPlayerTranslationConstants.poweredBy} ${_lyrics.source.name}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  if (_entries.isNotEmpty)
                    Text(
                      'Toca cualquier línea para saltar al minuto exacto',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColor.getMain()),
            const SizedBox(height: 12),
            const Text(
              'Cargando letras...',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (_lyrics.lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_off_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text(
              AudioPlayerTranslationConstants.noLyricsAvailable.tr,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_entries.isEmpty) {
      // Plain-text fallback (no LRC timestamps detected).
      return SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _lyrics.lyrics,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: _fontSize,
            height: 1.9,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: _entries.length,
      padding: const EdgeInsets.symmetric(vertical: 40),
      itemBuilder: (_, i) {
        final isActive = i == _activeIndex;
        final isPast = i < _activeIndex;
        final entry = _entries[i];

        return Container(
          key: _lineKeys[i],
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _seekTo(entry.timestamp),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 16 : 8,
                  vertical: isActive ? 10 : 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : isPast
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.6),
                    fontSize: isActive ? _fontSize + 5 : _fontSize,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                    height: 1.4,
                    letterSpacing: isActive ? -0.4 : 0,
                    shadows: isActive
                        ? [
                            Shadow(
                              color: AppColor.getMain().withValues(alpha: 0.5),
                              blurRadius: 16,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(entry.text),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
