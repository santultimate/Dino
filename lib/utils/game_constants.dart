// lib/utils/game_constants.dart

/// Constantes du jeu
class GameConstants {
  // Vitesse et physique
  static const double initialSpeed = 0.02;
  static const double speedIncrement = 0.005;
  static const int levelUpInterval = 10;
  
  // Collision bounds
  static const double collisionLeftBound = 0.1;
  static const double collisionRightBound = 0.3;
  static const double collisionHeightThreshold = 0.7;
  
  // Scores
  static const int maxTopScores = 10;
  static const int scorePerObstacle = 1;
  
  // Timing
  static const int gameLoopInterval = 16; // milliseconds
  static const int jumpDuration = 800; // milliseconds
  
  // Dimensions
  static const double dinoWidth = 0.15;
  static const double dinoHeight = 0.2;
  static const double obstacleWidth = 0.1;
  static const double obstacleHeight = 0.15;
  
  // Power-ups
  static const int powerUpSpawnInterval = 50; // obstacles
  static const double powerUpDuration = 5.0; // seconds
  
  // Audio
  static const double defaultMusicVolume = 0.5;
  static const double defaultEffectsVolume = 0.7;
  
  // UI
  static const double uiPadding = 16.0;
  static const double buttonHeight = 48.0;
  static const double cardElevation = 4.0;
  
  // Colors
  static const int primaryColor = 0xFF4CAF50;
  static const int accentColor = 0xFFFF9800;
  static const int backgroundColor = 0xFF121212;
  static const int surfaceColor = 0xFF1E1E1E;
} 