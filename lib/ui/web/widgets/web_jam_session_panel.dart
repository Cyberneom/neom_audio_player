import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:sint/sint.dart';

import '../../../data/implementations/jam_session_controller.dart';
import '../../../domain/models/jam_session.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/enums/jam_session_type.dart';

/// Full Jam Session experience panel (queue with voting + chat).
/// Displayed in center panel of AudioPlayerWebLayout.
class WebJamSessionPanel extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onLeave;

  const WebJamSessionPanel({Key? key, this.onBack, this.onLeave}) : super(key: key);

  @override
  State<WebJamSessionPanel> createState() => _WebJamSessionPanelState();
}

class _WebJamSessionPanelState extends State<WebJamSessionPanel> {
  final _chatController = TextEditingController();

  JamSessionController get _jam => Sint.find<JamSessionController>();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _copyJoinCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AudioPlayerTranslationConstants.codeCopied.tr),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColor.surfaceElevated,
      ),
    );
  }

  Future<void> _leaveSession() async {
    await _jam.leaveSession();
    widget.onLeave?.call();
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.surfaceElevated,
        title: Text(AudioPlayerTranslationConstants.endSession.tr,
            style: const TextStyle(color: Colors.white)),
        content: Text(AudioPlayerTranslationConstants.endSessionWarning.tr,
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Sint.back(result: false),
            child: Text(AppTranslationConstants.cancel.tr, style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Sint.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AudioPlayerTranslationConstants.endSession.tr,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _jam.endSession();
      widget.onLeave?.call();
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    await _jam.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = _jam.currentSession;
      if (session == null || !_jam.isInSession) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.podcasts, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(AudioPlayerTranslationConstants.noActiveJamSession.tr,
                  style: TextStyle(color: Colors.grey[400], fontSize: 18)),
              const SizedBox(height: 24),
              if (widget.onBack != null)
                ElevatedButton(
                  onPressed: widget.onBack,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColor.getMain()),
                  child: Text(AudioPlayerTranslationConstants.goHome.tr, style: const TextStyle(color: Colors.white)),
                ),
            ],
          ),
        );
      }

      final isHost = _jam.currentUserRole == JamParticipantRole.host;
      final isCoHost = _jam.currentUserRole == JamParticipantRole.coHost;
      final canControl = isHost || isCoHost;

      return Column(
        children: [
          // ─── Header ───
          _buildHeader(session, isHost),

          // ─── Queue + Chat ───
          Expanded(
            child: Row(
              children: [
                // Queue section
                Expanded(
                  flex: 3,
                  child: _buildQueue(session, canControl),
                ),
                // Chat section
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: _buildChat(),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHeader(JamSession session, bool isHost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.getMain().withOpacity(0.3), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Back
          if (widget.onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack,
            ),
          // Pulsing icon
          _PulsingDot(color: AppColor.getMain()),
          const SizedBox(width: 12),
          // Session info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _copyJoinCode(session.joinCode),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AudioPlayerTranslationConstants.joinCode.tr}: ${session.joinCode}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.copy, color: Colors.grey[500], size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Participants count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${session.participantCount}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Leave / End buttons
          if (isHost)
            ElevatedButton.icon(
              onPressed: _endSession,
              icon: const Icon(Icons.stop, size: 16),
              label: Text(AudioPlayerTranslationConstants.endSession.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            )
          else
            OutlinedButton(
              onPressed: _leaveSession,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                AudioPlayerTranslationConstants.leaveSession.tr,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQueue(JamSession session, bool canControl) {
    final queue = session.queue;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: queue.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              AudioPlayerTranslationConstants.upNextQueue.tr,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        final item = queue[index - 1];
        final isCurrent = index - 1 == session.currentIndex;

        return _QueueRow(
          item: item,
          index: index - 1,
          isCurrent: isCurrent,
          canControl: canControl,
          onUpvote: () => _jam.upvote(item.id),
          onDownvote: () => _jam.downvote(item.id),
          onSuperVote: () => _jam.superVote(item.id),
          onRemove: canControl ? () => _jam.removeFromQueue(item.id) : null,
        );
      },
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Chat',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        // Messages
        Expanded(
          child: StreamBuilder<JamChatMessage>(
            stream: _jam.chatStream,
            builder: (context, snapshot) {
              return ListView(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (snapshot.hasData)
                    _ChatBubble(message: snapshot.data!),
                ],
              );
            },
          ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Send a message...',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: AppColor.getMain(), size: 20),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Queue Row with Voting ─────────────────────────────────────────────────

class _QueueRow extends StatefulWidget {
  final JamQueueItem item;
  final int index;
  final bool isCurrent;
  final bool canControl;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final VoidCallback onSuperVote;
  final VoidCallback? onRemove;

  const _QueueRow({
    required this.item,
    required this.index,
    required this.isCurrent,
    required this.canControl,
    required this.onUpvote,
    required this.onDownvote,
    required this.onSuperVote,
    this.onRemove,
  });

  @override
  State<_QueueRow> createState() => _QueueRowState();
}

class _QueueRowState extends State<_QueueRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final mediaItem = widget.item.mediaItem;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: widget.isCurrent
              ? AppColor.getMain().withOpacity(0.15)
              : (_isHovered ? Colors.white.withOpacity(0.05) : Colors.transparent),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Index or playing indicator
            SizedBox(
              width: 30,
              child: widget.isCurrent
                  ? Icon(Icons.graphic_eq, color: AppColor.getMain(), size: 18)
                  : Text(
                      '${widget.index + 1}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 12),
            // Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: (mediaItem.artUri?.toString() ?? '').isNotEmpty
                  ? platformNetworkImage(
                      imageUrl: mediaItem.artUri.toString(),
                      width: 40, height: 40, fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 40, height: 40,
                        color: AppColor.getMain().withOpacity(0.3),
                        child: const Icon(Icons.music_note, color: Colors.white54, size: 18),
                      ),
                    )
                  : Container(
                      width: 40, height: 40,
                      color: AppColor.getMain().withOpacity(0.3),
                      child: const Icon(Icons.music_note, color: Colors.white54, size: 18),
                    ),
            ),
            const SizedBox(width: 12),
            // Title + Artist + AddedBy
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mediaItem.title,
                    style: TextStyle(
                      color: widget.isCurrent ? AppColor.getMain() : Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${mediaItem.artist ?? ''} • ${AudioPlayerTranslationConstants.addedBy.tr} ${widget.item.addedByName}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Vote score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: widget.item.score > 0
                    ? Colors.green.withOpacity(0.2)
                    : widget.item.score < 0
                        ? Colors.red.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.item.score > 0 ? '+' : ''}${widget.item.score}',
                style: TextStyle(
                  color: widget.item.score > 0
                      ? Colors.greenAccent
                      : widget.item.score < 0
                          ? Colors.redAccent
                          : Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Vote buttons
            IconButton(
              icon: const Icon(Icons.thumb_up_outlined, size: 16),
              color: Colors.grey[500],
              onPressed: widget.onUpvote,
              tooltip: AudioPlayerTranslationConstants.upvote.tr,
              splashRadius: 16,
            ),
            IconButton(
              icon: const Icon(Icons.thumb_down_outlined, size: 16),
              color: Colors.grey[500],
              onPressed: widget.onDownvote,
              tooltip: AudioPlayerTranslationConstants.downvote.tr,
              splashRadius: 16,
            ),
            IconButton(
              icon: const Icon(Icons.bolt, size: 18),
              color: Colors.amber,
              onPressed: widget.onSuperVote,
              tooltip: AudioPlayerTranslationConstants.superVote.tr,
              splashRadius: 16,
            ),
            // Remove button (host/co-host)
            if (widget.onRemove != null && _isHovered)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: Colors.grey[500],
                onPressed: widget.onRemove,
                splashRadius: 16,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat Bubble ────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final JamChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSystem = message.type == JamChatMessageType.system;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            message.message,
            style: TextStyle(color: Colors.grey[600], fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: (message.senderAvatarUrl ?? '').isNotEmpty
                ? platformImageProvider(message.senderAvatarUrl!) : null,
            backgroundColor: AppColor.getMain().withOpacity(0.3),
            child: (message.senderAvatarUrl ?? '').isEmpty
                ? Text(
                    message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  message.message,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing Dot ────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.5 + _controller.value * 0.5),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.3 * _controller.value),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
