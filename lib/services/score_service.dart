import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_mode.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreService {
  static const String _topScoresKey = 'top_scores';
  static const String _selectedSkinKey = 'selected_skin';

  FirebaseFirestore? _firestore;
  bool _firebaseInitialized = false;

  ScoreService({bool firebaseInitialized = false}) {
    _firebaseInitialized = firebaseInitialized;
    // Essayer d'initialiser Firebase de manière sécurisée
    _initializeFirebase();
  }

  void _initializeFirebase() {
    if (!_firebaseInitialized) {
      if (kDebugMode) {
        print('⚠️ Firebase not initialized, skipping Firestore setup');
      }
      return;
    }

    try {
      // Vérifier si Firebase est disponible
      _firestore = FirebaseFirestore.instance;
      if (kDebugMode) {
        print('🔥 Firebase Firestore initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Firebase not available: $e');
      }
      _firestore = null;
      _firebaseInitialized = false;
    }
  }

  // 🔹 Enregistre un score localement (et dans Firestore si uid fourni)
  Future<void> saveScore({
    required GameMode mode,
    required int score,
    required int level,
    String? uid, // Si fourni, enregistre aussi dans Firestore
    String? playerName, // Nom du joueur optionnel
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scores = await getTopScores(mode);

      final newScore = {
        'score': score,
        'level': level,
        'mode': mode.toString(),
        'date': DateTime.now().toIso8601String(),
        'dateFormatted': _formatDateForDisplay(DateTime.now()),
        'playerName':
            playerName ?? 'Joueur', // Utiliser le nom fourni ou par défaut
      };

      scores.add(newScore);
      scores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      final topScores = scores.length > 5 ? scores.sublist(0, 5) : scores;

      await prefs.setStringList(
        '${_topScoresKey}_${mode.toString()}',
        topScores.map((score) => jsonEncode(score)).toList(),
      );

      // 🔥 Firestore : sauvegarde distante si l'utilisateur est connecté et Firebase disponible
      if (uid != null && _firebaseInitialized && _firestore != null) {
        try {
          final userDoc = _firestore!.collection('scores').doc(uid);

          // Ajoute à l'historique
          await userDoc.collection('history').add(newScore);

          // Met à jour le meilleur score global utilisateur
          final currentHigh = await getPlayerHighScore(uid);
          if (score > currentHigh) {
            await userDoc.set({'highScore': score}, SetOptions(merge: true));
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error saving to Firebase: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving score: $e');
      rethrow;
    }
  }

  // 🔹 Récupère le top 5 local d'un mode
  Future<List<Map<String, dynamic>>> getTopScores(GameMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresData =
          prefs.getStringList('${_topScoresKey}_${mode.toString()}') ?? [];

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

  // 🔹 Récupère le meilleur score local d'un mode
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

  // 🔹 Récupère le meilleur score Firestore d'un utilisateur
  Future<int> getPlayerHighScore(String uid) async {
    try {
      if (!_firebaseInitialized || _firestore == null) return 0;

      final doc = await _firestore!.collection('scores').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('highScore')) {
        return doc['highScore'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error getting player high score: $e');
      }
      return 0;
    }
  }

  // 🔹 Récupère le meilleur score global (tous joueurs confondus)
  Future<int> getGlobalHighScore() async {
    try {
      if (!_firebaseInitialized || _firestore == null) return 0;

      final querySnapshot =
          await _firestore!
              .collection('scores')
              .orderBy('highScore', descending: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['highScore'] ?? 0;
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error getting global high score: $e');
      }
      return 0;
    }
  }

  // 🔹 Récupère tous les scores historiques d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserScores(String uid) async {
    try {
      if (!_firebaseInitialized || _firestore == null) return [];

      final querySnapshot =
          await _firestore!
              .collection('scores')
              .doc(uid)
              .collection('history')
              .orderBy('date', descending: true)
              .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error getting user scores: $e');
      }
      return [];
    }
  }

  // 🔹 Récupère les 5 derniers joueurs avec leurs scores (pour l'historique)
  Future<List<Map<String, dynamic>>> getLastPlayersHistory(
    GameMode mode,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresData =
          prefs.getStringList('${_topScoresKey}_${mode.toString()}') ?? [];

      final results = <Map<String, dynamic>>[];
      final playerNames = [
        'Joueur',
        'Gamer',
        'Player',
        'DinoRunner',
        'Champion',
      ];

      for (int i = 0; i < scoresData.length; i++) {
        try {
          final decoded = jsonDecode(scoresData[i]) as Map<String, dynamic>;
          if (decoded.isNotEmpty) {
            // Ajouter un nom par défaut si pas de nom
            if (!decoded.containsKey('playerName')) {
              decoded['playerName'] = playerNames[i % playerNames.length];
            }
            results.add(decoded);
          }
        } catch (e) {
          debugPrint('Error decoding score: $e');
        }
      }

      // Trier par score décroissant et limiter à 5
      results.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      return results.take(5).toList();
    } catch (e) {
      debugPrint('Error getting last players history: $e');
      return [];
    }
  }

  // 🔹 Formate une date pour l'affichage
  String _formatDateForDisplay(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Aujourd'hui
      return 'Aujourd\'hui à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Hier
      return 'Hier à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      // Cette semaine
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return '${days[dateTime.weekday - 1]} ${dateTime.day}/${dateTime.month}';
    } else {
      // Plus ancien
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
