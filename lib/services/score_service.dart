import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_mode.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Firestore

class ScoreService {
  static const String _topScoresKey = 'top_scores';
  static const String _selectedSkinKey = 'selected_skin';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // ✅ Ajout Firestore

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

      scores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
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

  // ✅ Méthode Firestore
  Future<int> getPlayerHighScore(String uid) async {
    final doc = await _firestore.collection('scores').doc(uid).get();
    if (doc.exists && doc.data()!.containsKey('highScore')) {
      return doc['highScore'] ?? 0;
    } else {
      return 0;
    }
  }
}
