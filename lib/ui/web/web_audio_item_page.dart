import 'package:flutter/material.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/playable_item.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:sint/sint.dart';

import '../../utils/audio_item_source_availability.dart';
import '../player/miniplayer_controller.dart';
import '../player/widgets/unavailable_audio_details.dart';
import 'widgets/web_now_playing_full.dart';

/// Loads a route's requested song before attaching the shared web player.
/// Keeping the request metadata visible prevents a previous session's song
/// from appearing while the new source is being loaded or when loading fails.
class WebAudioItemPage extends StatefulWidget {
  final PlayableItem item;
  final bool playItem;

  const WebAudioItemPage({super.key, required this.item, this.playItem = true});

  @override
  State<WebAudioItemPage> createState() => _WebAudioItemPageState();
}

class _WebAudioItemPageState extends State<WebAudioItemPage> {
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final invoker = Sint.find<AudioPlayerInvokerService>();
      final miniPlayer = Sint.isRegistered<MiniPlayerController>()
          ? Sint.find<MiniPlayerController>()
          : Sint.put(MiniPlayerController());
      await invoker.init(
        items: [widget.item],
        playItem: widget.playItem,
        recommend: AppConfig.instance.canPersistUserActivity,
      );
      final selected = miniPlayer.visibleMediaItem;
      if (selected?.id != widget.item.id ||
          selected?.extras?['url'] != audioItemSource(widget.item)) {
        throw StateError('The requested audio source did not load.');
      }
    } catch (_) {
      _failed = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _failed) {
      return UnavailableAudioDetails(
        item: widget.item,
        isLoading: _loading,
        message: AppTranslationConstants.playbackErrorStopped.tr,
        onRetry: _failed ? _load : null,
      );
    }
    return WebNowPlayingFull(onClose: () => Navigator.of(context).maybePop());
  }
}
