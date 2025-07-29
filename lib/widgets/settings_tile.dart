// lib/widgets/settings_tile.dart
import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool? value;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onChanged;
  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.title,
    required this.icon,
    this.value,
    this.onTap,
    this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ??
          (value != null && onChanged != null
              ? Switch(
                  value: value!,
                  onChanged: onChanged,
                )
              : null),
      onTap: onTap,
    );
  }
}
