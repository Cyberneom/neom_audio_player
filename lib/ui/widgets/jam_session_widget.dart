import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sint/sint.dart';

import '../../data/implementations/jam_session_controller.dart';
import '../../domain/models/jam_session.dart';
import '../../utils/enums/jam_session_type.dart';

/// Widget showing current Jam session status
class JamSessionBanner extends StatelessWidget {
  final Color? accentColor;
  final VoidCallback? onTap;

  const JamSessionBanner({
    super.key,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Sint.find<JamSessionController>();
    final theme = Theme.of(context);
    final accent = accentColor ?? const Color(0xFF1DB954);

    return Obx(() {
      final session = controller.currentSession;
      if (session == null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon with pulse animation
                  _PulsingIcon(color: Colors.white),
                  const SizedBox(width: 12),

                  // Session info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Jam Session',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          session.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${session.activeParticipants.length} listeners',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Share button
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => _shareSession(context, session),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _shareSession(BuildContext context, JamSession session) {
    Clipboard.setData(ClipboardData(text: session.shareUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Join code copied: ${session.joinCode}'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () {
            // Would use share_plus to share
          },
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final Color color;

  const _PulsingIcon({required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.podcasts,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

/// Create Jam Session bottom sheet
class CreateJamSessionSheet extends StatefulWidget {
  final VoidCallback? onCreated;

  const CreateJamSessionSheet({super.key, this.onCreated});

  @override
  State<CreateJamSessionSheet> createState() => _CreateJamSessionSheetState();
}

class _CreateJamSessionSheetState extends State<CreateJamSessionSheet> {
  final _nameController = TextEditingController();
  JamSessionType _type = JamSessionType.open;
  bool _allowRequests = true;
  bool _allowVoting = true;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Start a Jam',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Listen together with friends in real-time',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),

          // Session name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Session Name',
              hintText: 'My Jam Session',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Session type
          Text(
            'Who can join?',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: JamSessionType.values.map((type) {
              final isSelected = _type == type;
              return ChoiceChip(
                label: Text(type.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _type = type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Options
          SwitchListTile(
            title: const Text('Allow song requests'),
            subtitle: const Text('Participants can add songs to the queue'),
            value: _allowRequests,
            onChanged: (value) => setState(() => _allowRequests = value),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Allow voting'),
            subtitle: const Text('Participants can vote on songs'),
            value: _allowVoting,
            onChanged: (value) => setState(() => _allowVoting = value),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),

          // Create button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isCreating ? null : _createSession,
              child: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start Jam'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _createSession() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a session name')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final controller = Sint.find<JamSessionController>();
      await controller.createSession(
        name: _nameController.text,
        type: _type,
        allowRequests: _allowRequests,
        allowVoting: _allowVoting,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

/// Join Jam Session dialog
class JoinJamSessionDialog extends StatefulWidget {
  final VoidCallback? onJoined;

  const JoinJamSessionDialog({super.key, this.onJoined});

  @override
  State<JoinJamSessionDialog> createState() => _JoinJamSessionDialogState();
}

class _JoinJamSessionDialogState extends State<JoinJamSessionDialog> {
  final _codeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join a Jam'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the 6-character code to join a session'),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Join Code',
              hintText: 'ABC123',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isJoining ? null : _joinSession,
          child: _isJoining
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Join'),
        ),
      ],
    );
  }

  Future<void> _joinSession() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-character code')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final controller = Sint.find<JamSessionController>();
      await controller.joinSession(_codeController.text.toUpperCase());

      if (mounted) {
        Navigator.pop(context);
        widget.onJoined?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join session: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }
}

/// Participant avatar stack
class JamParticipantsStack extends StatelessWidget {
  final List<JamParticipant> participants;
  final int maxVisible;
  final double avatarSize;

  const JamParticipantsStack({
    super.key,
    required this.participants,
    this.maxVisible = 4,
    this.avatarSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleCount = participants.length.clamp(0, maxVisible);
    final overflow = participants.length - maxVisible;

    return SizedBox(
      width: avatarSize + (visibleCount - 1) * (avatarSize * 0.6) + (overflow > 0 ? avatarSize * 0.6 : 0),
      height: avatarSize,
      child: Stack(
        children: [
          for (var i = 0; i < visibleCount; i++)
            Positioned(
              left: i * (avatarSize * 0.6),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                  image: participants[i].avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(participants[i].avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: theme.colorScheme.primary,
                ),
                child: participants[i].avatarUrl == null
                    ? Center(
                        child: Text(
                          participants[i].displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visibleCount * (avatarSize * 0.6),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Text(
                    '+$overflow',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Show create jam session sheet
Future<void> showCreateJamSessionSheet(
  BuildContext context, {
  VoidCallback? onCreated,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: CreateJamSessionSheet(onCreated: onCreated),
    ),
  );
}

/// Show join jam session dialog
Future<void> showJoinJamSessionDialog(
  BuildContext context, {
  VoidCallback? onJoined,
}) {
  return showDialog(
    context: context,
    builder: (context) => JoinJamSessionDialog(onJoined: onJoined),
  );
}
