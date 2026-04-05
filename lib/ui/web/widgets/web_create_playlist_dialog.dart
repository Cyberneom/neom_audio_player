import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/domain/use_cases/itemlist_service.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/audio_player_translation_constants.dart';

class WebCreatePlaylistDialog extends StatefulWidget {
  const WebCreatePlaylistDialog({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const WebCreatePlaylistDialog(),
    );
  }

  @override
  State<WebCreatePlaylistDialog> createState() => _WebCreatePlaylistDialogState();
}

class _WebCreatePlaylistDialogState extends State<WebCreatePlaylistDialog> {
  bool _isPublic = false;

  @override
  Widget build(BuildContext context) {
    final controller = Sint.find<ItemlistService>();

    return Dialog(
      backgroundColor: AppColor.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AudioPlayerTranslationConstants.createNewPlaylist.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Name field
            TextField(
              controller: controller.newItemlistNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppTranslationConstants.name.tr,
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
            const SizedBox(height: 16),
            // Description field
            TextField(
              controller: controller.newItemlistDescController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppTranslationConstants.description.tr,
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
            const SizedBox(height: 16),
            // Public toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTranslationConstants.publicList.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Switch(
                  value: _isPublic,
                  onChanged: (v) {
                    setState(() => _isPublic = v);
                    controller.isPublicNewItemlist = v;
                  },
                  activeColor: AppColor.getMain(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    controller.clearNewItemlist();
                    Sint.back();
                  },
                  child: Text(
                    AppTranslationConstants.cancel.tr,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    controller.isPublicNewItemlist = _isPublic;
                    await controller.createItemlist();
                    if (context.mounted) Sint.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.getMain(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    AppTranslationConstants.save.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
