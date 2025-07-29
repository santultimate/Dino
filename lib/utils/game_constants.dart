// lib/utils/game_constants.dart

/// Constantes du jeu
class GameConstants {
  // Vitesse et physique
  static const double initialSpeed = 0.01;
  static const double speedIncrement = 0.002;
  static const int levelUpInterval = 15;

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

  // Mode-specific constants
  static const double infiniteModeSpeedIncrement =
      0.001; // Réduit de 0.003 à 0.001
  static const double timeAttackInitialSpeed = 0.015; // Réduit de 0.035 à 0.015
  static const double timeAttackSpeedIncrement =
      0.003; // Réduit de 0.008 à 0.003
  static const double hardcoreInitialSpeed = 0.025; // Réduit de 0.045 à 0.025
  static const double hardcoreSpeedIncrement = 0.006; // Réduit de 0.012 à 0.006

  // Time Attack settings
  static const int timeAttackDuration = 60; // seconds
  static const int timeAttackBonusTime = 5; // seconds for power-ups

  // Daily Challenge settings
  static const int dailyChallengeMaxAttempts = 1;
  static const int dailyChallengeSeed = 42; // Base seed for daily generation

  // Hardcore mode settings
  static const bool hardcoreAllowPowerUps = false;
  static const double hardcoreObstacleFrequency = 1.5; // More obstacles
  static const int hardcoreLevelUpInterval = 5; // Faster level progression

  // Progressive difficulty
  static const double maxSpeedMultiplier = 3.0; // Maximum speed increase
  static const int maxLevel = 50; // Maximum level cap

  // Day/Night cycle (for infinite mode)
  static const int dayNightCycleDuration = 30; // seconds per cycle
  static const double nightModeSpeedMultiplier =
      1.2; // Slightly faster at night

  // New features for enhanced modes
  static const int infiniteModeCoinsPerObstacle =
      1; // Coins earned per obstacle
  static const int timeAttackCoinsPerObstacle = 2; // More coins in time attack
  static const int dailyChallengeBonusCoins =
      10; // Bonus coins for daily challenge
  static const int hardcoreModeCoinsPerObstacle = 3; // Most coins in hardcore

  // Power-up settings per mode
  static const bool infiniteModeAllowAllPowerUps = true;
  static const bool timeAttackAllowTimePowerUps = true;
  static const bool dailyChallengeAllowPowerUps = true;
  static const bool hardcoreModeAllowPowerUps = false;

  // Obstacle frequency per mode
  static const double infiniteModeObstacleFrequency = 0.03;
  static const double timeAttackObstacleFrequency = 0.04; // More frequent
  static const double dailyChallengeObstacleFrequency = 0.025; // Variable
  static const double hardcoreModeObstacleFrequency = 0.06; // Very frequent
}

// Game positioning constants
class GamePositions {
  // Ground level for all game elements
  static const double universalGroundLevel =
      120.0; // Niveau de sol plus bas pour descendre les personnages

  // Dino position (hauteur 80px)
  static const double dinoLeftPosition = 80.0;
  static const double dinoGroundLevel =
      universalGroundLevel; // Utilise le niveau universel
  static const double dinoJumpMultiplier = 50.0;

  // Obstacle position (hauteur 60px)
  static const double obstacleGroundLevel =
      universalGroundLevel; // Utilise le niveau universel
  static const double obstacleWidthMultiplier = 0.8;

  // Power-up position
  static const double powerUpGroundLevel =
      universalGroundLevel + 30.0; // Légèrement plus haut
  static const double powerUpWidthMultiplier = 0.8;

  // Cloud position
  static const double cloudTopPosition = 50.0;
  static const double cloudWidthMultiplier = 0.8;

  // Menu d'accueil positions
  static const double homeScreenPadding = 24.0;
  static const double homeScreenButtonSpacing = 20.0;
  static const double homeScreenTitleSpacing = 40.0;

  // UI Elements positions
  static const double uiTopPadding = 40.0;
  static const double uiLeftPadding = 20.0;
  static const double uiRightPadding = 20.0;
  static const double uiBottomPadding = 20.0;

  // Game HUD positions
  static const double hudTopPosition = 50.0;
  static const double hudLeftPosition = 20.0;
  static const double hudRightPosition = 20.0;
}
