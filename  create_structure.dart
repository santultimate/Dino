import 'dart:io';

final List<String> folders = [
  'lib/screens',
  'lib/screens/game_modes',
  'lib/models',
  'lib/utils',
  'lib/widgets',
  'lib/services',
  'assets/images',
  'assets/sounds',
  'assets/data',
];

final Map<String, String> files = {
  'lib/main.dart': '',
  'lib/screens/home_screen.dart': '',
  'lib/screens/settings_screen.dart': '',
  'lib/screens/about_screen.dart': '',
  'lib/screens/shop_screen.dart': '',
  'lib/screens/difficulty_selector.dart': '',
  'lib/screens/game_modes/infinite_mode.dart': '',
  'lib/screens/game_modes/timed_mode.dart': '',
  'lib/screens/game_modes/daily_challenge_mode.dart': '',
  'lib/screens/game_modes/hardcore_mode.dart': '',
  'lib/models/user_model.dart': '',
  'lib/services/firebase_service.dart': '',
  'lib/utils/constants.dart': '',
};

void main() {
  for (var folder in folders) {
    final dir = Directory(folder);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      print('📁 Dossier créé : $folder');
    }
  }

  for (var entry in files.entries) {
    final file = File(entry.key);
    if (!file.existsSync()) {
      file.writeAsStringSync(entry.value);
      print('📄 Fichier créé : ${entry.key}');
    }
  }

  print('✅ Structure du projet créée avec succès.');
}
