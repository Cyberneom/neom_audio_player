import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/audio_player_translation_constants.dart';

/// Spotify-style dialog for editing an existing playlist's metadata.
class WebEditPlaylistDialog extends StatefulWidget {
  final Itemlist itemlist;
  final VoidCallback? onUpdated;

  const WebEditPlaylistDialog({
    Key? key,
    required this.itemlist,
    this.onUpdated,
  }) : super(key: key);

  static Future<void> show(BuildContext context, Itemlist itemlist, {VoidCallback? onUpdated}) {
    return showDialog(
      context: context,
      builder: (_) => WebEditPlaylistDialog(itemlist: itemlist, onUpdated: onUpdated),
    );
  }

  @override
  State<WebEditPlaylistDialog> createState() => _WebEditPlaylistDialogState();
}

class _WebEditPlaylistDialogState extends State<WebEditPlaylistDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late bool _isPublic;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemlist.name);
    _descController = TextEditingController(text: widget.itemlist.description);
    _isPublic = widget.itemlist.public;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    widget.itemlist.name = name;
    widget.itemlist.description = _descController.text.trim();
    widget.itemlist.public = _isPublic;

    await ItemlistFirestore().update(widget.itemlist);

    if (mounted) {
      widget.onUpdated?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // Title
            Text(
              AudioPlayerTranslationConstants.editPlaylist.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Cover image preview
            if (widget.itemlist.imgUrl.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: platformNetworkImage(
                    imageUrl: widget.itemlist.imgUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorWidget: _coverPlaceholder(),
                  ),
                ),
              )
            else
              Center(child: _coverPlaceholder()),
            const SizedBox(height: 20),

            // Name field
            TextField(
              controller: _nameController,
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
              controller: _descController,
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
                  onChanged: (v) => setState(() => _isPublic = v),
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppTranslationConstants.cancel.tr,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.getMain(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
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

  Widget _coverPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColor.getMain().withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.library_music, color: Colors.white54, size: 48),
    );
  }
}
