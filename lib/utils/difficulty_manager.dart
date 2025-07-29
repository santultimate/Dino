import 'dart:math';
import '../models/game_mode.dart';

class DifficultyManager {
  static const int _baseLevel = 1;
  static const double _baseSpeed = 0.01;
  static const double _maxSpeed = 0.08;
  static const int _maxLevel = 100;

  /// Calcule la vitesse actuelle basée sur le niveau
  static double getCurrentSpeed(int level, GameMode mode) {
    double baseSpeed = _getBaseSpeedForMode(mode);
    double speedIncrement = _getSpeedIncrementForMode(mode);
    
    // Formule progressive : vitesse augmente de manière logarithmique
    double speedMultiplier = 1.0 + (log(level + 1) / log(2)) * 0.3;
    double currentSpeed = baseSpeed * speedMultiplier;
    
    // Limiter la vitesse maximale
    return currentSpeed.clamp(baseSpeed, _maxSpeed);
  }

  /// Calcule la fréquence des obstacles basée sur le niveau
  static double getObstacleFrequency(int level, GameMode mode) {
    double baseFrequency = _getBaseObstacleFrequencyForMode(mode);
    double frequencyIncrement = 0.001;
    
    // Augmentation progressive de la fréquence
    double frequency = baseFrequency + (level * frequencyIncrement);
    
    // Limiter la fréquence maximale
    return frequency.clamp(baseFrequency, 0.15);
  }

  /// Calcule la difficulté des obstacles basée sur le niveau
  static ObstacleDifficulty getObstacleDifficulty(int level, GameMode mode) {
    if (level < 5) return ObstacleDifficulty.easy;
    if (level < 15) return ObstacleDifficulty.medium;
    if (level < 30) return ObstacleDifficulty.hard;
    if (level < 50) return ObstacleDifficulty.expert;
    return ObstacleDifficulty.master;
  }

  /// Calcule la fréquence des power-ups basée sur le niveau
  static double getPowerUpFrequency(int level, GameMode mode) {
    if (mode == GameMode.hardcore) return 0.0; // Pas de power-ups en hardcore
    
    double baseFrequency = 0.02;
    double frequency = baseFrequency - (level * 0.0005);
    
    // Maintenir une fréquence minimale
    return frequency.clamp(0.005, baseFrequency);
  }

  /// Calcule le bonus de score basé sur le niveau
  static int getScoreMultiplier(int level, GameMode mode) {
    int baseMultiplier = _getBaseScoreMultiplierForMode(mode);
    int levelBonus = (level / 10).floor(); // Bonus tous les 10 niveaux
    
    return baseMultiplier + levelBonus;
  }

  /// Calcule le bonus de pièces basé sur le niveau
  static int getCoinMultiplier(int level, GameMode mode) {
    int baseCoins = _getBaseCoinsForMode(mode);
    int levelBonus = (level / 5).floor(); // Bonus tous les 5 niveaux
    
    return baseCoins + levelBonus;
  }

  /// Détermine si un obstacle spécial doit apparaître
  static bool shouldSpawnSpecialObstacle(int level, GameMode mode) {
    if (level < 10) return false;
    
    double chance = (level - 10) * 0.01; // 1% de chance supplémentaire par niveau
    return Random().nextDouble() < chance.clamp(0.0, 0.3); // Max 30% de chance
  }

  /// Calcule la durée des power-ups basée sur le niveau
  static double getPowerUpDuration(int level, GameMode mode) {
    double baseDuration = 5.0;
    double durationReduction = level * 0.05; // Réduction de 0.05s par niveau
    
    return (baseDuration - durationReduction).clamp(2.0, baseDuration);
  }

  // Méthodes privées pour les valeurs de base par mode
  static double _getBaseSpeedForMode(GameMode mode) {
    switch (mode) {
      case GameMode.infinite:
        return 0.01;
      case GameMode.timeAttack:
        return 0.015;
      case GameMode.challenge:
        return 0.012;
      case GameMode.hardcore:
        return 0.025;
    }
  }

  static double _getSpeedIncrementForMode(GameMode mode) {
    switch (mode) {
      case GameMode.infinite:
        return 0.001;
      case GameMode.timeAttack:
        return 0.003;
      case GameMode.challenge:
        return 0.002;
      case GameMode.hardcore:
        return 0.006;
    }
  }

  static double _getBaseObstacleFrequencyForMode(GameMode mode) {
    switch (mode) {
      case GameMode.infinite:
        return 0.03;
      case GameMode.timeAttack:
        return 0.04;
      case GameMode.challenge:
        return 0.025;
      case GameMode.hardcore:
        return 0.06;
    }
  }

  static int _getBaseScoreMultiplierForMode(GameMode mode) {
    switch (mode) {
      case GameMode.infinite:
        return 1;
      case GameMode.timeAttack:
        return 2;
      case GameMode.challenge:
        return 3;
      case GameMode.hardcore:
        return 5;
    }
  }

  static int _getBaseCoinsForMode(GameMode mode) {
    switch (mode) {
      case GameMode.infinite:
        return 1;
      case GameMode.timeAttack:
        return 2;
      case GameMode.challenge:
        return 3;
      case GameMode.hardcore:
        return 4;
    }
  }
}

/// Niveaux de difficulté des obstacles
enum ObstacleDifficulty {
  easy,    // Obstacles simples, espacés
  medium,  // Obstacles moyens, fréquence normale
  hard,    // Obstacles complexes, fréquence élevée
  expert,  // Obstacles très complexes, fréquence très élevée
  master   // Obstacles extrêmes, fréquence maximale
} 