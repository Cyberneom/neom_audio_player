import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:sint/sint.dart';

import '../../../data/implementations/jam_session_controller.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';
import '../../../utils/enums/jam_session_type.dart';

/// Spotify-style dialog for creating a new Jam Session.
class WebJamCreateDialog extends StatefulWidget {
  final Itemlist? sourcePlaylist;
  final VoidCallback? onSessionCreated;

  const WebJamCreateDialog({
    Key? key,
    this.sourcePlaylist,
    this.onSessionCreated,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {Itemlist? sourcePlaylist, VoidCallback? onSessionCreated}) {
    return showDialog(
      context: context,
      builder: (_) => WebJamCreateDialog(
        sourcePlaylist: sourcePlaylist,
        onSessionCreated: onSessionCreated,
      ),
    );
  }

  @override
  State<WebJamCreateDialog> createState() => _WebJamCreateDialogState();
}

class _WebJamCreateDialogState extends State<WebJamCreateDialog> {
  late TextEditingController _nameController;
  JamSessionType _sessionType = JamSessionType.open;
  bool _allowRequests = true;
  bool _allowVoting = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.sourcePlaylist != null
          ? 'Jam: ${widget.sourcePlaylist!.name}'
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final controller = Sint.find<JamSessionController>();
      await controller.createSession(
        name: name,
        type: _sessionType,
        allowRequests: _allowRequests,
        allowVoting: _allowVoting,
      );

      if (mounted) {
        widget.onSessionCreated?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.podcasts, color: AppColor.getMain(), size: 28),
                const SizedBox(width: 12),
                Text(
                  AudioPlayerTranslationConstants.startJam.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Session Name
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AudioPlayerTranslationConstants.sessionName.tr,
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColor.getMain()),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Session Type
            Text(
              AudioPlayerTranslationConstants.whoCanJoin.tr,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: JamSessionType.values.map((type) {
                final isSelected = _sessionType == type;
                return ChoiceChip(
                  label: Text(
                    type.name == 'open' ? 'Open' : type.name == 'private' ? 'Private' : 'Friends',
                  ),
                  selected: isSelected,
                  selectedColor: AppColor.getMain(),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _sessionType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Allow Requests toggle
            _buildToggle(
              AudioPlayerTranslationConstants.allowRequests.tr,
              _allowRequests,
              (v) => setState(() => _allowRequests = v),
            ),
            const SizedBox(height: 8),

            // Allow Voting toggle
            _buildToggle(
              AudioPlayerTranslationConstants.allowVoting.tr,
              _allowVoting,
              (v) => setState(() => _allowVoting = v),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppTranslationConstants.cancel.tr,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isCreating ? null : _createSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.getMain(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          AudioPlayerTranslationConstants.startJam.tr,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColor.getMain(),
        ),
      ],
    );
  }
}
