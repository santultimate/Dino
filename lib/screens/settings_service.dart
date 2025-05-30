import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  bool _isDarkMode = false;
  bool _animationsEnabled = true;
  String _difficulty = 'medium';

  bool get isDarkMode => _isDarkMode;
  bool get animationsEnabled => _animationsEnabled;
  String get difficulty => _difficulty;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _animationsEnabled = prefs.getBool('animationsEnabled') ?? true;
    _difficulty = prefs.getString('difficulty') ?? 'medium';
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> setAnimationsEnabled(bool value) async {
    _animationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animationsEnabled', value);
  }

  Future<void> setDifficulty(String value) async {
    _difficulty = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('difficulty', value);
  }

  Future<void> resetAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _loadSettings();
  }
}