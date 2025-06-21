import 'dart:math';

/// Classe pour les calculs de physique du jeu
class GamePhysics {
  static const double gravity = 9.8;
  static const double jumpVelocity = 4.0;
  static const double maxJumpHeight = 0.4;
  
  /// Calcule la hauteur du saut basée sur le temps
  static double calculateJumpHeight(double time) {
    // Formule de physique pour un saut parabolique
    // h = v0 * t - 0.5 * g * t^2
    final height = jumpVelocity * time - 0.5 * gravity * time * time;
    return (height / maxJumpHeight).clamp(0.0, 1.0);
  }
  
  /// Calcule la vitesse de chute
  static double calculateFallVelocity(double time) {
    return gravity * time;
  }
  
  /// Vérifie si un objet est en collision avec un autre
  static bool checkCollision({
    required double x1,
    required double y1,
    required double width1,
    required double height1,
    required double x2,
    required double y2,
    required double width2,
    required double height2,
  }) {
    return x1 < x2 + width2 &&
           x1 + width1 > x2 &&
           y1 < y2 + height2 &&
           y1 + height1 > y2;
  }
  
  /// Calcule la distance entre deux points
  static double calculateDistance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
  }
  
  /// Applique une interpolation linéaire
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
  
  /// Calcule la vitesse basée sur le niveau
  static double calculateSpeed(int level) {
    return 0.02 + (level - 1) * 0.005;
  }
  
  /// Calcule le délai de spawn basé sur la difficulté
  static int calculateSpawnDelay(int level, {double difficulty = 1.0}) {
    final baseDelay = 2000 - (level * 50);
    return (baseDelay / difficulty).clamp(500, 2000).round();
  }
} 