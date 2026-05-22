import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:sint/sint.dart';

import '../../../data/implementations/lyrics_controller.dart';
import '../../../domain/models/lrc_entry.dart';
import '../../../domain/models/media_lyrics.dart';
import '../../../neom_audio_handler.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/enums/lyrics_source.dart';

/// Mobile widget for displaying time-synced lyrics with karaoke-style
/// highlighting and auto-scroll.
///
/// Falls back to plain-text display when no LRC timestamps are detected.
/// Uses [LyricsController] for fetching, caching, and SplayTreeMap-based
/// O(log n) lookups of the active line.
class SyncedLyricsWidget extends StatefulWidget {

  final MediaItem mediaItem;
  final Color? accentColor;

  const SyncedLyricsWidget({
    super.key,
    required this.mediaItem,
    this.accentColor,
  });

  @override
  State<SyncedLyricsWidget> createState() => _SyncedLyricsWidgetState();

}

class _SyncedLyricsWidgetState extends State<SyncedLyricsWidget> {

  MediaLyrics _lyrics = MediaLyrics();
  bool _isLoading = true;
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
  void didUpdateWidget(covariant SyncedLyricsWidget oldWidget) {
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

    try {
      final controller = Sint.find<LyricsController>();
      _lyrics = await controller.fetchLyrics(
        mediaId: widget.mediaItem.id,
        title: widget.mediaItem.title,
        artist: widget.mediaItem.artist ?? '',
      );

      if (!mounted) return;

      _entries = controller.currentEntries;
      setState(() {
        _activeIndex = -1;
        _lineKeys
          ..clear()
          ..addEntries(List.generate(
            _entries.length,
            (i) => MapEntry(i, GlobalKey()),
          ));
        _isLoading = false;
      });

      if (_entries.isNotEmpty) _attachPositionStream();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _attachPositionStream() {
    try {
      final handler = Sint.find<NeomAudioHandler>();
      _positionSub = handler.player.positionStream.listen(_onPosition);
    } catch (_) {
      // Audio handler not available — keep static view.
    }
  }

  void _detachPositionStream() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  void _onPosition(Duration pos) {
    if (_entries.isEmpty || !mounted) return;

    final controller = Sint.find<LyricsController>();
    final idx = controller.getActiveLineIndex(pos);

    if (idx != _activeIndex) {
      setState(() => _activeIndex = idx);
      _scrollToActive(idx);
    }
  }

  void _scrollToActive(int index) {
    if (!_scrollController.hasClients || index < 0) return;
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
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? AppColor.getMain();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme, accent),
        const SizedBox(height: 12),
        Expanded(child: _buildBody(theme, accent)),
        if (_lyrics.source != LyricsSource.internal && _lyrics.lyrics.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${AudioPlayerTranslationConstants.poweredBy} ${_lyrics.source.name}',
              style: TextStyle(color: theme.hintColor, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, Color accent) {
    return Row(
      children: [
        Text(
          AudioPlayerTranslationConstants.lyrics.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_entries.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SYNCED',
              style: TextStyle(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBody(ThemeData theme, Color accent) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    if (_lyrics.lyrics.isEmpty) {
      return Center(
        child: Text(
          AudioPlayerTranslationConstants.noLyricsAvailable.tr,
          style: TextStyle(color: theme.hintColor, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Plain-text fallback
    if (_entries.isEmpty) {
      return SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Text(
          _lyrics.lyrics,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
        ),
      );
    }

    // Synced lyrics with karaoke highlight
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
                  ? accent
                  : isPast
                      ? theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.35)
                      : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.55),
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
