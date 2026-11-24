import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/shared_listening_service.dart';
import 'package:neom_core/domain/use_cases/tip_service.dart';
import 'package:neom_core/domain/use_cases/wallet_service.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:sint/sint.dart';

import '../../neom_audio_handler.dart';

/// Compact Gigmeout action pills for Mobile & Web audio players:
/// 1. `🪙 {balance} · Apoyar` -> opens `TipSheet` via [TipService.showTipModal]
///    (plus a one-time 8-second educational coachmark on a signed-in user's first track).
/// 2. `🎧 Sesión Compartida` -> opens optional shared song room via [SharedListeningService].
///
/// Renders `SizedBox.shrink()` on non-Gigmeout apps (`AppInUse.e`, etc.) and
/// for Public Domain / ad tracks so GigCoins tipping and Shared Listening stay
/// exclusive to Gigmeout's independent artist community.
class GigmeoutPlayerActionsBar extends StatefulWidget {
  final MediaItem? mediaItem;
  final Stream<Duration>? positionStream;
  final bool compact;

  const GigmeoutPlayerActionsBar({
    super.key,
    required this.mediaItem,
    this.positionStream,
    this.compact = false,
  });

  @override
  State<GigmeoutPlayerActionsBar> createState() =>
      _GigmeoutPlayerActionsBarState();
}

class _GigmeoutPlayerActionsBarState extends State<GigmeoutPlayerActionsBar> {
  static const String _coachmarkHiveKey = 'gigcoin_player_guide_seen_v1';

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _compactCoachmarkOverlay;
  StreamSubscription<Duration>? _posSub;
  Timer? _coachmarkDismissTimer;
  bool _showCoachmark = false;
  double _balance = 0;

  bool get _isGigmeout => AppConfig.instance.appInUse == AppInUse.g;

  bool get _isCommunityArtistTrack {
    final item = widget.mediaItem;
    if (item == null || item.id.isEmpty) return false;
    if (NeomAudioHandler.isPublicDomainMediaItem(item)) return false;
    if (NeomAudioHandler.isAdMediaItem(item)) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (_isGigmeout && _isCommunityArtistTrack) {
      _refreshBalance();
      _attachCoachmarkWatcher();
    }
  }

  @override
  void didUpdateWidget(covariant GigmeoutPlayerActionsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isGigmeout) return;
    if (!_isCommunityArtistTrack) {
      _posSub?.cancel();
      _posSub = null;
      _coachmarkDismissTimer?.cancel();
      _dismissCoachmark();
      return;
    }
    if (oldWidget.mediaItem?.id != widget.mediaItem?.id) {
      _refreshBalance();
    }
    if (oldWidget.positionStream != widget.positionStream || _posSub == null) {
      _posSub?.cancel();
      _attachCoachmarkWatcher();
    }
  }

  @override
  void dispose() {
    _removeCompactOverlay();
    _posSub?.cancel();
    _coachmarkDismissTimer?.cancel();
    super.dispose();
  }

  void _dismissCoachmark() {
    _removeCompactOverlay();
    if (mounted && _showCoachmark) {
      setState(() => _showCoachmark = false);
    }
  }

  void _removeCompactOverlay() {
    _compactCoachmarkOverlay?.remove();
    _compactCoachmarkOverlay = null;
  }

  void _showCompactOverlayIfNeeded() {
    if (_compactCoachmarkOverlay != null || !mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _compactCoachmarkOverlay = OverlayEntry(
      builder: (_) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-40, -76),
          child: Material(
            color: Colors.transparent,
            child: _buildCoachmarkBanner(),
          ),
        ),
      ),
    );
    overlay.insert(_compactCoachmarkOverlay!);
  }

  Future<void> _refreshBalance() async {
    if (!AppConfig.instance.canPersistUserActivity) return;
    if (!Sint.isRegistered<WalletService>()) return;
    try {
      final ws = Sint.find<WalletService>();
      setState(() => _balance = ws.balance);
      await ws.refreshWallet();
      if (mounted) {
        setState(() => _balance = ws.balance);
      }
    } catch (_) {}
  }

  void _attachCoachmarkWatcher() {
    if (!_isCommunityArtistTrack) return;
    final stream = widget.positionStream;
    if (stream == null) return;
    _posSub = stream.listen((pos) {
      if (!mounted || _showCoachmark || !_isCommunityArtistTrack) return;
      if (!AppConfig.instance.canPersistUserActivity) return;
      if (pos.inSeconds < 8) return;
      try {
        if (!Hive.isBoxOpen(AppHiveBox.settings.name)) return;
        final box = Hive.box(AppHiveBox.settings.name);
        final alreadySeen = box.get(_coachmarkHiveKey, defaultValue: false) == true;
        if (alreadySeen) {
          _posSub?.cancel();
          return;
        }
        box.put(_coachmarkHiveKey, true);
        _posSub?.cancel();
        if (widget.compact) {
          _showCoachmark = true;
          _showCompactOverlayIfNeeded();
        } else {
          setState(() => _showCoachmark = true);
        }
        _coachmarkDismissTimer?.cancel();
        _coachmarkDismissTimer = Timer(const Duration(seconds: 9), _dismissCoachmark);
      } catch (_) {}
    });
  }

  void _handleSupportTap(BuildContext context) {
    final item = widget.mediaItem;
    if (!_isCommunityArtistTrack || item == null || item.id.isEmpty) return;

    AuthGuard.protect(context, () async {
      if (!Sint.isRegistered<TipService>()) return;
      final ownerProfileId = item.extras?['ownerProfileId']?.toString() ?? '';
      final ownerId = item.extras?['ownerId']?.toString() ?? '';
      final ownerEmail = item.extras?['ownerEmail']?.toString() ?? '';
      final recipientId = ownerProfileId.isNotEmpty
          ? ownerProfileId
          : (ownerId.isNotEmpty ? ownerId : ownerEmail);
      final artistName = (item.artist?.trim().isNotEmpty ?? false)
          ? item.artist!.trim()
          : 'Artista';

      await Sint.find<TipService>().showTipModal(
        context,
        recipientId: recipientId.isNotEmpty ? recipientId : item.id,
        recipientName: artistName,
        contextType: 'song',
        contextId: item.id,
      );
      await _refreshBalance();
    });
  }

  void _handleSharedSessionTap(BuildContext context) {
    final item = widget.mediaItem;
    if (!_isCommunityArtistTrack || item == null || item.id.isEmpty) return;

    AuthGuard.protect(context, () async {
      if (!Sint.isRegistered<SharedListeningService>()) return;
      await Sint.find<SharedListeningService>().openSharedSongRoom(
        context,
        mediaId: item.id,
        title: item.title,
        artist: item.artist ?? '',
        coverUrl: item.artUri?.toString(),
        ownerEmail: item.extras?['ownerEmail']?.toString(),
        ownerProfileId: item.extras?['ownerProfileId']?.toString() ??
            item.extras?['ownerId']?.toString(),
        durationSeconds: item.duration?.inSeconds ?? 180,
      );
    });
  }

  Widget _buildCoachmarkBanner() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amberAccent.withValues(alpha: 0.55),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tienes GigCoins de bienvenida · Toca «Apoyar» para impulsar directo a este artista (desde 1 GigCoin).',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                height: 1.25,
              ),
            ),
          ),
          InkWell(
            onTap: _dismissCoachmark,
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGigmeout || !_isCommunityArtistTrack) return const SizedBox.shrink();
    final item = widget.mediaItem;
    if (item == null || item.id.isEmpty) return const SizedBox.shrink();

    final loggedIn = AppConfig.instance.canPersistUserActivity;
    final balanceText = loggedIn
        ? (_balance == _balance.roundToDouble()
            ? _balance.toInt().toString()
            : _balance.toStringAsFixed(1))
        : '';

    final pillPadding = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final fontSize = widget.compact ? 11.0 : 12.5;

    final supportPill = CompositedTransformTarget(
      link: _layerLink,
      child: Tooltip(
        message: 'Impulsa directamente al artista con GigCoins',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _dismissCoachmark();
            _handleSupportTap(context);
          },
          child: Container(
            padding: pillPadding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.22),
                  AppColor.getMain().withValues(alpha: 0.24),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amberAccent.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🪙', style: TextStyle(fontSize: widget.compact ? 12 : 13)),
                const SizedBox(width: 4),
                Text(
                  loggedIn && balanceText.isNotEmpty
                      ? '$balanceText · Apoyar'
                      : 'Apoyar',
                  style: TextStyle(
                    color: Colors.amber[100],
                    fontWeight: FontWeight.w700,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final sharedPill = Sint.isRegistered<SharedListeningService>()
        ? Tooltip(
            message: 'Escucha esta canción con reacciones, chat y voz opcional',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _handleSharedSessionTap(context),
              child: Container(
                padding: pillPadding,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.headphones_rounded,
                      size: widget.compact ? 13 : 14,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.compact ? 'Sala' : 'Sesión Compartida',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : null;

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          supportPill,
          if (sharedPill != null) ...[
            const SizedBox(width: 6),
            sharedPill,
          ],
        ],
      );
    }

    final pillsRow = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        supportPill,
        if (sharedPill != null) sharedPill,
      ],
    );

    if (!_showCoachmark) return pillsRow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pillsRow,
        const SizedBox(height: 6),
        _buildCoachmarkBanner(),
      ],
    );
  }
}
