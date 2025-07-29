// lib/utils/game_utils.dart

import 'dart:math';
import 'package:flutter/material.dart';

/// Classe utilitaire regroupant les fonctions communes du jeu
class GameUtils {
  static final Random _random = Random();
  
  // Configuration des difficultés
  static const Map<GameDifficulty, double> _difficultySettings = {
    GameDifficulty.easy: 0.7,
    GameDifficulty.medium: 1.0,
    GameDifficulty.hard: 1.5,
  };

  /// Retourne un nombre aléatoire dans un intervalle [min, max]
  static int getRandomInt(int min, int max) {
    assert(min <= max, 'Min must be less than or equal to max');
    return min + _random.nextInt(max - min + 1);
  }

  /// Retourne un double aléatoire dans un intervalle [min, max]
  static double getRandomDouble(double min, double max) {
    assert(min <= max, 'Min must be less than or equal to max');
    return min + _random.nextDouble() * (max - min);
  }

  /// Génère un délai aléatoire pour le spawn d'objets
  static Duration getRandomSpawnDelay({
    int minMs = 500,
    int maxMs = 2000,
    GameDifficulty difficulty = GameDifficulty.medium,
  }) {
    final baseDelay = getRandomInt(minMs, maxMs);
    final modifier = _difficultySettings[difficulty] ?? 1.0;
    return Duration(milliseconds: (baseDelay / modifier).round());
  }

  /// Formate un score pour l'affichage (ex: 1000 -> 1,000)
  static String formatScore(int score) {
    return score.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Calcule le score basé sur le temps et la difficulté
  static int calculateScore({
    required Duration playTime,
    GameDifficulty difficulty = GameDifficulty.medium,
    int multiplier = 1,
  }) {
    final timeScore = playTime.inSeconds;
    final difficultyFactor = _difficultySettings[difficulty] ?? 1.0;
    return (timeScore * difficultyFactor * multiplier).round();
  }

  /// Convertit des secondes en format MM:SS
  static String formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
           '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Crée un gradient linéaire basé sur une couleur de base
  static LinearGradient createGradient(Color baseColor, {bool isVertical = true}) {
    return LinearGradient(
      begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
      end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
      colors: [
        baseColor,
        baseColor.withOpacity(0.7),
        baseColor.withOpacity(0.4),
      ],
    );
  }

  /// Vérifie une collision entre deux rectangles
  static bool checkCollision({
    required Rect rect1,
    required Rect rect2,
    double tolerance = 0.7, // 70% de chevauchement requis
  }) {
    final intersection = rect1.intersect(rect2);
    final minOverlap = min(rect1.width, rect2.width) * tolerance;
    return intersection.width > minOverlap && 
           intersection.height > minOverlap;
  }

  /// Applique une valeur de bruit à une position
  static double applyNoise(double value, {double intensity = 0.1}) {
    return value + getRandomDouble(-intensity, intensity);
  }

  /// Retourne la couleur basée sur le niveau
  static Color getLevelColor(int level) {
    if (level <= 5) return Colors.green;
    if (level <= 10) return Colors.yellow;
    if (level <= 15) return Colors.orange;
    if (level <= 20) return Colors.red;
    return Colors.purple;
  }
}

/// Enumération des niveaux de difficulté
enum GameDifficulty {
  easy,
  medium,
  hard,
}

/// Extension pour les durées
extension DurationExtensions on Duration {
  /// Convertit une durée en string MM:SS
  String toMMSS() {
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }
}

/// Extension pour les Rect
extension RectExtensions on Rect {
  /// Crée un Rect à partir d'une position et taille
  static Rect fromPosition(Offset position, Size size) {
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      size.width,
      size.height,
    );
  }
}