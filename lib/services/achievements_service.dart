import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final String iconAsset;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.iconAsset,
  });
}

class AchievementsService with ChangeNotifier {
  static final AchievementsService _instance = AchievementsService._internal();
  factory AchievementsService() => _instance;
  AchievementsService._internal();

  // Configuration des succès
  static final Map<String, Achievement> _allAchievements = {
    'first_play': Achievement(
      id: 'first_play',
      title: 'Première partie',
      description: 'Jouez votre première partie',
      targetValue: 1,
      iconAsset: 'assets/achievements/first_play.png',
    ),
    'score_100': Achievement(
      id: 'score_100',
      title: '100 points',
      description: 'Atteignez 100 points en une partie',
      targetValue: 100,
      iconAsset: 'assets/achievements/score_100.png',
    ),
    'consecutive_days': Achievement(
      id: 'consecutive_days',
      title: 'Joueur assidu',
      description: 'Jouez plusieurs jours consécutifs',
      targetValue: 3,  // 3 jours consécutifs par exemple
      iconAsset: 'assets/achievements/consecutive_days.png',
    ),
  };

  // Cache en mémoire
  final Map<String, bool> _unlockedCache = {};
  final Map<String, int> _progressCache = {};
  DateTime? _lastPlayDate;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger les succès débloqués
    for (var id in _allAchievements.keys) {
      _unlockedCache[id] = prefs.getBool('ach_$id') ?? false;
    }
    
    // Charger la progression
    for (var id in _allAchievements.keys) {
      _progressCache[id] = prefs.getInt('progress_$id') ?? 0;
    }
    
    // Charger la dernière date de jeu
    final lastDateStr = prefs.getString('last_play_date');
    _lastPlayDate = lastDateStr != null ? DateTime.parse(lastDateStr) : null;
  }

  bool isUnlocked(String achievementId) {
    return _unlockedCache[achievementId] ?? false;
  }

  int getProgress(String achievementId) {
    return _progressCache[achievementId] ?? 0;
  }

  Future<void> incrementAchievement(String achievementId, {int amount = 1}) async {
    if (!_allAchievements.containsKey(achievementId)) return;
    if (isUnlocked(achievementId)) return;

    final newValue = (_progressCache[achievementId] ?? 0) + amount;
    _progressCache[achievementId] = newValue;

    if (newValue >= _allAchievements[achievementId]!.targetValue) {
      await _unlockAchievement(achievementId);
    } else {
      await _saveProgress(achievementId, newValue);
    }
  }

  Future<void> unlockAchievement(String achievementId) async {
    if (!_allAchievements.containsKey(achievementId)) return;
    if (isUnlocked(achievementId)) return;

    await _unlockAchievement(achievementId);
  }

  Future<void> recordPlaySession() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    
    if (_lastPlayDate != null) {
      final daysBetween = now.difference(_lastPlayDate!).inDays;
      
      if (daysBetween == 1) {
        await incrementAchievement('consecutive_days');
      } else if (daysBetween > 1) {
        _progressCache['consecutive_days'] = 0;
        await _saveProgress('consecutive_days', 0);
      }
    }

    _lastPlayDate = now;
    await prefs.setString('last_play_date', now.toIso8601String());
    
    if (!isUnlocked('first_play')) {
      await _unlockAchievement('first_play');
    }
  }

  Map<Achievement, Map<String, dynamic>> getAllAchievements() {
    return Map.fromEntries(
      _allAchievements.entries.map((entry) {
        final achievement = entry.value;
        return MapEntry(achievement, {
          'unlocked': isUnlocked(achievement.id),
          'progress': getProgress(achievement.id),
          'target': achievement.targetValue,
        });
      }),
    );
  }

  // Méthodes privées
  Future<void> _unlockAchievement(String achievementId) async {
    _unlockedCache[achievementId] = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ach_$achievementId', true);
    _notifyAchievementUnlocked(achievementId);
  }

  Future<void> _saveProgress(String achievementId, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('progress_$achievementId', value);
    notifyListeners();
  }

  void _notifyAchievementUnlocked(String achievementId) {
    final achievement = _allAchievements[achievementId]!;
    debugPrint('Succès débloqué: ${achievement.title}');
    notifyListeners();
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (var id in _allAchievements.keys) {
      await prefs.remove('ach_$id');
      await prefs.remove('progress_$id');
    }
    
    await prefs.remove('last_play_date');
    
    _unlockedCache.clear();
    _progressCache.clear();
    _lastPlayDate = null;
    
    notifyListeners();
  }
}