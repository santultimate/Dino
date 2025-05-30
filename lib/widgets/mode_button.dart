import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class ModeButton extends StatelessWidget {
  const ModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    
    return IconButton(
      icon: Icon(
        settings.isDarkMode ? Icons.light_mode : Icons.dark_mode,
      ),
      onPressed: () {
        settings.toggleThemeMode();
      },
      tooltip: settings.isDarkMode ? 'Mode clair' : 'Mode sombre',
    );
  }
}