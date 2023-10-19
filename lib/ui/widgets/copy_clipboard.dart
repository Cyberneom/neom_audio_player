import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';

void copyToClipboard({
  required BuildContext context,
  required String text,
  String? displayText,
}) {
  Clipboard.setData(
    ClipboardData(text: text),
  );
  ShowSnackBar().showSnackBar(
    context,
    displayText ?? PlayerTranslationConstants.copied.tr,
  );
}
