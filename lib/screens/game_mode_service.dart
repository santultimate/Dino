import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_mode.dart';
import '../screens/game_modes/infinite_mode.dart' as infinite;
import '../screens/game_modes/timed_mode.dart' as timed;
import '../screens/game_modes/hardcore_mode.dart' as hardcore;

class GameModeService with ChangeNotifier {
  GameMode _currentMode = GameMode.infinite;
  final Map<GameMode, int> _highScores = {};
  bool _isInitialized = false;

  GameMode get currentMode => _currentMode;
  int get currentHighScore => _highScores[_currentMode] ?? 0;
  Map<GameMode, int> get allHighScores => Map.unmodifiable(_highScores);

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadHighScores();
    _isInitialized = true;
  }

  Future<void> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    for (final mode in GameMode.values) {
      _highScores[mode] = prefs.getInt('highScore_${mode.name}') ?? 0;
    }
    notifyListeners();
  }

  Future<void> _saveHighScore(GameMode mode, int score) async {
    _highScores[mode] = score;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore_${mode.name}', score);
    notifyListeners();
  }

  void setCurrentMode(GameMode mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    notifyListeners();
  }

  void updateHighScore(int score) {
    if (score > currentHighScore) {
      _saveHighScore(_currentMode, score);
    }
  }

  Widget getModeScreen() {
    switch (_currentMode) {
      case GameMode.infinite:
        return const infinite.InfiniteMode();
      case GameMode.timeAttack:
        return timed.GameScreen(mode: timed.GameMode.timeAttack);
      case GameMode.challenge:
        return timed.GameScreen(mode: timed.GameMode.dailyChallenge);
      case GameMode.hardcore:
        return const hardcore.HardcoreMode();
    }
    throw UnimplementedError('Unknown game mode: \\_currentMode');
  }

  String getModeDescription(GameMode mode) {
    switch (mode) {
      case GameMode.infinite:
        return 'Course sans limite de temps\nRecord: \\${_highScores[GameMode.infinite] ?? 0}';
      case GameMode.timeAttack:
        return '60 secondes pour marquer un max de points\nRecord: \\${_highScores[GameMode.timeAttack] ?? 0}';
      case GameMode.challenge:
        return 'Défi unique chaque jour\nRecord: \\${_highScores[GameMode.challenge] ?? 0}';
      case GameMode.hardcore:
        return 'Difficulté maximale, un seul essai\nRecord: \\${_highScores[GameMode.hardcore] ?? 0}';
    }
    throw UnimplementedError('Unknown game mode: \\mode');
  }

  IconData getModeIcon(GameMode mode) {
    switch (mode) {
      case GameMode.infinite:
        return Icons.all_inclusive;
      case GameMode.timeAttack:
        return Icons.timer;
      case GameMode.challenge:
        return Icons.calendar_today;
      case GameMode.hardcore:
        return Icons.whatshot;
    }
    throw UnimplementedError('Unknown game mode: \\mode');
  }

  Color getModeColor(GameMode mode) {
    switch (mode) {
      case GameMode.infinite:
        return Colors.blue;
      case GameMode.timeAttack:
        return Colors.green;
      case GameMode.challenge:
        return Colors.orange;
      case GameMode.hardcore:
        return Colors.red;
    }
    throw UnimplementedError('Unknown game mode: \\mode');
  }
}
