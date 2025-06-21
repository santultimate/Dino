import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_mode.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreService {
  static const String _topScoresKey = 'top_scores';
  static const String _selectedSkinKey = 'selected_skin';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Enregistre un score localement (et dans Firestore si uid fourni)
  Future<void> saveScore({
    required GameMode mode,
    required int score,
    required int level,
    String? uid, // Si fourni, enregistre aussi dans Firestore
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scores = await getTopScores(mode);

      final newScore = {
        'score': score,
        'level': level,
        'mode': mode.toString(),
        'date': DateTime.now().toIso8601String(),
      };

      scores.add(newScore);
      scores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      final topScores = scores.length > 5 ? scores.sublist(0, 5) : scores;

      await prefs.setStringList(
        '${_topScoresKey}_${mode.toString()}',
        topScores.map((score) => jsonEncode(score)).toList(),
      );

      // 🔥 Firestore : sauvegarde distante si l’utilisateur est connecté
      if (uid != null) {
        final userDoc = _firestore.collection('scores').doc(uid);

        // Ajoute à l'historique
        await userDoc.collection('history').add(newScore);

        // Met à jour le meilleur score global utilisateur
        final currentHigh = await getPlayerHighScore(uid);
        if (score > currentHigh) {
          await userDoc.set({'highScore': score}, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('Error saving score: $e');
      rethrow;
    }
  }

  // 🔹 Récupère le top 5 local d’un mode
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

  // 🔹 Récupère le meilleur score local d’un mode
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

  // 🔹 Récupère le skin sélectionné localement
  Future<String> get selectedSkin async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedSkinKey) ?? 'default';
    } catch (e) {
      debugPrint('Error getting skin: $e');
      return 'default';
    }
  }

  // 🔹 Définit le skin sélectionné
  Future<void> setSelectedSkin(String skinId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedSkinKey, skinId);
    } catch (e) {
      debugPrint('Error saving skin: $e');
      rethrow;
    }
  }

  // 🔹 Récupère le meilleur score Firestore d’un utilisateur
  Future<int> getPlayerHighScore(String uid) async {
    try {
      final doc = await _firestore.collection('scores').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('highScore')) {
        return doc['highScore'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      debugPrint('Error getting player high score: $e');
      return 0;
    }
  }

  // 🔹 Récupère le meilleur score global (tous joueurs confondus)
  Future<int> getGlobalHighScore() async {
    try {
      final querySnapshot = await _firestore
          .collection('scores')
          .orderBy('highScore', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['highScore'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting global high score: $e');
      return 0;
    }
  }

  // 🔹 Récupère tous les scores historiques d’un utilisateur
  Future<List<Map<String, dynamic>>> getUserScores(String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection('scores')
          .doc(uid)
          .collection('history')
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting user scores: $e');
      return [];
    }
  }
}
