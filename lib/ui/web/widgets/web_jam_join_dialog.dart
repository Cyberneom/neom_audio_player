import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:sint/sint.dart';

import '../../../data/implementations/jam_session_controller.dart';
import '../../../utils/constants/audio_player_translation_constants.dart';

/// Dialog for joining an existing Jam Session via 6-character code.
class WebJamJoinDialog extends StatefulWidget {
  final VoidCallback? onJoined;

  const WebJamJoinDialog({Key? key, this.onJoined}) : super(key: key);

  static Future<void> show(BuildContext context, {VoidCallback? onJoined}) {
    return showDialog(
      context: context,
      builder: (_) => WebJamJoinDialog(onJoined: onJoined),
    );
  }

  @override
  State<WebJamJoinDialog> createState() => _WebJamJoinDialogState();
}

class _WebJamJoinDialogState extends State<WebJamJoinDialog> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Code must be 6 characters');
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final controller = Sint.find<JamSessionController>();
      await controller.joinSession(code);

      if (mounted) {
        widget.onJoined?.call();
        Sint.back();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
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
                  AudioPlayerTranslationConstants.joinJam.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-character code to join a session',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Code Input
            TextField(
              controller: _codeController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              textAlign: TextAlign.center,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'ABC123',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                counterText: '',
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
                errorText: _error,
                errorStyle: const TextStyle(color: Colors.redAccent),
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Sint.back(),
                  child: Text(
                    AppTranslationConstants.cancel.tr,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isJoining ? null : _join,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.getMain(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          AudioPlayerTranslationConstants.joinJam.tr,
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
}
