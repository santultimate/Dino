import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _animationsKey = 'animations_enabled';
  static const String _difficultyKey = 'difficulty';
  
  bool _isDarkMode = false;
  bool _animationsEnabled = true;
  String _difficulty = 'medium';

  bool get isDarkMode => _isDarkMode;
  bool get animationsEnabled => _animationsEnabled;
  String get difficulty => _difficulty;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeModeKey) ?? false;
    _animationsEnabled = prefs.getBool(_animationsKey) ?? true;
    _difficulty = prefs.getString(_difficultyKey) ?? 'medium';
    notifyListeners();
  }

  Future<void> toggleThemeMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool value) async {
    _animationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_animationsKey, _animationsEnabled);
    notifyListeners();
  }

  Future<void> setDifficulty(String value) async {
    _difficulty = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_difficultyKey, _difficulty);
    notifyListeners();
  }

  Future<void> resetAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    // Reset all game-related settings
    await prefs.remove('high_score');
    await prefs.remove('coins');
    await prefs.remove('unlocked_power_ups');
    await prefs.remove('purchased_items');
    await prefs.remove('achievements');
    
    // Keep user preferences (theme, animations, difficulty)
    // Only reset game progress
    
    notifyListeners();
  }
}