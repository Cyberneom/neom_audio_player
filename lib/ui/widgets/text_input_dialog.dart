import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';

class TextInputDialog extends StatelessWidget {
  final String title;
  final String? initialText;
  final TextInputType keyboardType;
  final Function(String, BuildContext) onSubmitted;

  const TextInputDialog({super.key,
    required this.title,
    this.initialText,
    required this.keyboardType,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialText);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      backgroundColor: AppColor.getMain(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          TextField(
            autofocus: true,
            controller: controller,
            keyboardType: keyboardType,
            textAlignVertical: TextAlignVertical.bottom,
            onSubmitted: (value) {
              onSubmitted(value, context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(AppTranslationConstants.cancel.tr),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: AppColor.bondiBlue,
          ),
          onPressed: () {
            onSubmitted(controller.text.trim(), context);
          },
          child: Text(
            AppTranslationConstants.ok.tr.toUpperCase(),
          ),
        ),
        const SizedBox(
          width: 5,
        ),
      ],
    );
  }
}

void showTextInputDialog({
  required String title,
  required BuildContext context,
  String? initialText,
  required TextInputType keyboardType,
  required Function(String, BuildContext) onSubmitted,
}) {
  showDialog(
    context: context,
    builder: (BuildContext ctxt) {
      return TextInputDialog(
        title: title,
        initialText: initialText,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
      );
    },
  );
}
