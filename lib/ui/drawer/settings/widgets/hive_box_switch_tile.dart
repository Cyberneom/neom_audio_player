import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

class HiveBoxSwitchTile extends StatelessWidget {
  const HiveBoxSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.keyName,
    required this.defaultValue,
    this.isThreeLine,
    this.onChanged,
    this.contentPadding,
  });

  final String title;
  final String? subtitle;
  final String keyName;
  final bool defaultValue;
  final bool? isThreeLine;
  final EdgeInsetsGeometry? contentPadding;
  final Function({required bool val, required Box box})? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(AppHiveBox.settings.name).listenable(),
      builder: (BuildContext context, Box box, Widget? widget) {
        return SwitchListTile(
          activeColor: Theme.of(context).colorScheme.secondary,
          contentPadding: contentPadding,
          title: Text(title, style: AppTheme.settingsTitleStyle,),
          subtitle: subtitle != null ? Text(subtitle!, style: AppTheme.settingsSubtitleStyle, textAlign: TextAlign.justify,) : null,
          isThreeLine: isThreeLine ?? false,
          dense: true,
          value: box.get(keyName, defaultValue: defaultValue) as bool? ??
              defaultValue,
          onChanged: (val) {
            AppConfig.logger.d("Changing status for setting on $key with value as: $val");
            box.put(keyName, val);
            onChanged?.call(val: val, box: box);
          },
        );
      },
    );
  }
}
