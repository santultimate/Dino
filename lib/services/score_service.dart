import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Import pour jsonDecode/jsonEncode
import '../models/game_mode.dart';

class ScoreService {
  static const String _topScoresKey = 'top_scores';
  static const String _selectedSkinKey = 'selected_skin';

  Future<void> saveScore({
    required GameMode mode,
    required int score,
    required int level,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scores = await getTopScores(mode);
      
      scores.add({
        'score': score,
        'level': level,
        'mode': mode.toString(),
        'date': DateTime.now().toIso8601String(),
      });
      
      // Trie par score décroissant
      scores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      
      // Garde seulement les 5 meilleurs scores
      final topScores = scores.length > 5 ? scores.sublist(0, 5) : scores;
      
      await prefs.setStringList(
        '${_topScoresKey}_${mode.toString()}',
        topScores.map((score) => jsonEncode(score)).toList(),
      );
    } catch (e) {
      debugPrint('Error saving score: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTopScores(GameMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresData = prefs.getStringList('${_topScoresKey}_${mode.toString()}') ?? [];
      
      final results = <Map<String, dynamic>>[];
      
      for (final jsonString in scoresData) {
        try {
          final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
          if (decoded.isNotEmpty) {
            results.add(decoded);
          }
        } catch (e) {
          debugPrint('Error decoding score: $e');
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error getting scores: $e');
      return [];
    }
  }

  Future<int> getBestScore(GameMode mode) async {
    try {
      final scores = await getTopScores(mode);
      if (scores.isEmpty) return 0;
      
      // Trouve le score maximum
      int maxScore = 0;
      for (final score in scores) {
        final currentScore = score['score'] as int? ?? 0;
        if (currentScore > maxScore) {
          maxScore = currentScore;
        }
      }
      return maxScore;
    } catch (e) {
      debugPrint('Error getting best score: $e');
      return 0;
    }
  }

  Future<void> setSelectedSkin(String skinId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedSkinKey, skinId);
    } catch (e) {
      debugPrint('Error saving skin: $e');
      rethrow;
    }
  }

  Future<String> get selectedSkin async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedSkinKey) ?? 'default';
    } catch (e) {
      debugPrint('Error getting skin: $e');
      return 'default';
    }
  }
}