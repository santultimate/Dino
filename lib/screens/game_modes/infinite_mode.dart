import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/dino.dart';
import '../../widgets/obstacle.dart';
import '../../widgets/power_up.dart';
import '../../widgets/game_over_dialog.dart';
import '../../widgets/background_parallax.dart';
import '../../widgets/cloud.dart';
import '../../models/power_up_type.dart';
import '../../utils/game_constants.dart';
import '../../utils/sound_manager.dart';

class InfiniteMode extends StatefulWidget {
  const InfiniteMode({super.key});

  @override
  State<InfiniteMode> createState() => _InfiniteModeState();
}

class _InfiniteModeState extends State<InfiniteMode>
    with SingleTickerProviderStateMixin {
  // Game State
  double dinoY = 0;
  double velocity = 0;
  bool isGameStarted = false;
  bool isJumping = false;
  bool isGameOver = false;
  bool isHit = false;
  int score = 0;
  int highScore = 0;
  int level = 1;
  double currentSpeed = GameConstants.initialSpeed;
  bool isNightMode = false;
  int dayNightCycle = 0;

  // Power-up system
  bool hasShield = false;
  bool hasSpeedBoost = false;
  bool hasInvincibility = false;
  Timer? shieldTimer;
  Timer? speedBoostTimer;
  Timer? invincibilityTimer;

  // Game Objects (store positions)
  final List<double> obstacleXs = [];
  final List<double> powerUpXs = [];
  final List<PowerUpType> powerUpTypes = [];
  Timer? gameLoopTimer;
  late AnimationController _animationController;
  final Random _random = Random();

  // Constants
  static const double gravity = -9.8;
  static const double jumpForce = 4.0;
  static const double groundLevel = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _loadHighScore();
    SoundManager().initialize();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => highScore = prefs.getInt('highScoreInfinite') ?? 0);
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScoreInfinite', highScore);
  }

  void _startGame() {
    if (isGameStarted) return;
    setState(() {
      isGameStarted = true;
      isGameOver = false;
      isHit = false;
      score = 0;
      level = 1;
      dinoY = groundLevel;
      velocity = 0;
      currentSpeed = GameConstants.initialSpeed;
      isNightMode = false;
      dayNightCycle = 0;
      obstacleXs.clear();
      powerUpXs.clear();
      powerUpTypes.clear();
      _clearPowerUps();
    });
    SoundManager().playBackgroundMusic();
    _startGameLoop();
  }

  void _startGameLoop() {
    gameLoopTimer?.cancel();
    gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60 FPS
      (_) => _updateGame(),
    );
  }

  void _updateGame() {
    if (!mounted || isGameOver) return;
    setState(() {
      _updatePhysics();
      _updateObjects();
      _checkCollisions();
      _updateScore();
      _spawnObjects();
      _updateDayNightCycle();
      _updateProgressiveSpeed();
    });
  }

  void _updatePhysics() {
    velocity += gravity * 0.016;
    dinoY -= velocity * 0.016;
    // Ground collision
    if (dinoY > groundLevel) {
      dinoY = groundLevel;
      velocity = 0;
      isJumping = false;
    }
  }

  void _updateObjects() {
    for (int i = 0; i < obstacleXs.length; i++) {
      obstacleXs[i] -= currentSpeed * 2.0;
    }
    for (int i = 0; i < powerUpXs.length; i++) {
      powerUpXs[i] -= currentSpeed * 2.0;
    }
    // Remove off-screen objects
    obstacleXs.removeWhere((x) => x < -1.2);
    for (int i = powerUpXs.length - 1; i >= 0; i--) {
      if (powerUpXs[i] < -1.2) {
        powerUpXs.removeAt(i);
        powerUpTypes.removeAt(i);
      }
    }
  }

  void _checkCollisions() {
    // Check obstacle collisions (with invincibility check)
    if (!hasInvincibility) {
      for (final x in obstacleXs) {
        if (x < 0.2 && x > -0.2 && dinoY == groundLevel) {
          if (hasShield) {
            _removeShield();
            obstacleXs.remove(x);
            SoundManager().playHitSound();
            return;
          } else {
            _endGame();
            return;
          }
        }
      }
    }

    // Power-up collision
    for (int i = 0; i < powerUpXs.length; i++) {
      if (powerUpXs[i] < 0.2 && powerUpXs[i] > -0.2 && dinoY == groundLevel) {
        _applyPowerUp(powerUpTypes[i]);
        powerUpXs.removeAt(i);
        powerUpTypes.removeAt(i);
        break;
      }
    }
  }

  void _applyPowerUp(PowerUpType type) {
    SoundManager().playCoinSound();

    switch (type) {
      case PowerUpType.shield:
        _activateShield();
        break;
      case PowerUpType.speedBoost:
        _activateSpeedBoost();
        break;
      case PowerUpType.healthBoost:
        _activateInvincibility();
        break;
      case PowerUpType.doubleCoins:
        // Double score for a period
        break;
      case PowerUpType.damageBoost:
        // Not applicable in infinite mode
        break;
    }
  }

  void _activateShield() {
    hasShield = true;
    shieldTimer?.cancel();
    shieldTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => hasShield = false);
    });
  }

  void _activateSpeedBoost() {
    hasSpeedBoost = true;
    speedBoostTimer?.cancel();
    speedBoostTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => hasSpeedBoost = false);
    });
  }

  void _activateInvincibility() {
    hasInvincibility = true;
    invincibilityTimer?.cancel();
    invincibilityTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => hasInvincibility = false);
    });
  }

  void _removeShield() {
    hasShield = false;
    shieldTimer?.cancel();
  }

  void _clearPowerUps() {
    hasShield = false;
    hasSpeedBoost = false;
    hasInvincibility = false;
    shieldTimer?.cancel();
    speedBoostTimer?.cancel();
    invincibilityTimer?.cancel();
  }

  void _updateScore() {
    score++;
    if (score > highScore) {
      highScore = score;
      _saveHighScore();
    }
  }

  void _spawnObjects() {
    // Spawn obstacles with progressive frequency
    final obstacleChance = 0.03 + (level * 0.002);
    if (_random.nextDouble() < obstacleChance) {
      obstacleXs.add(1.2);
    }

    // Spawn power-ups more frequently (every 30 points instead of 150)
    if (score % 30 == 0 && score > 0 && powerUpXs.length < 2) {
      powerUpXs.add(1.2);
      powerUpTypes.add(_getRandomPowerUp());
    }

    // Additional random chance to spawn power-ups (5% chance every frame)
    if (_random.nextDouble() < 0.05 && powerUpXs.isEmpty && score > 10) {
      powerUpXs.add(1.2);
      powerUpTypes.add(_getRandomPowerUp());
    }
  }

  PowerUpType _getRandomPowerUp() {
    final powerUps = [
      PowerUpType.shield,
      PowerUpType.speedBoost,
      PowerUpType.healthBoost,
    ];
    return powerUps[_random.nextInt(powerUps.length)];
  }

  PowerUpType? _getActivePowerUp() {
    if (hasShield) return PowerUpType.shield;
    if (hasSpeedBoost) return PowerUpType.speedBoost;
    if (hasInvincibility) return PowerUpType.healthBoost;
    return null;
  }

  void _updateDayNightCycle() {
    dayNightCycle++;
    if (dayNightCycle >= GameConstants.dayNightCycleDuration * 60) {
      // 60 FPS
      dayNightCycle = 0;
      isNightMode = !isNightMode;
    }
  }

  void _updateProgressiveSpeed() {
    if (score % GameConstants.levelUpInterval == 0 && score > 0) {
      level++;
      currentSpeed += GameConstants.infiniteModeSpeedIncrement;

      // Apply speed boost if active
      if (hasSpeedBoost) {
        currentSpeed *= 1.5;
      }

      // Apply night mode speed multiplier
      if (isNightMode) {
        currentSpeed *= GameConstants.nightModeSpeedMultiplier;
      }

      // Cap maximum speed
      if (currentSpeed >
          GameConstants.initialSpeed * GameConstants.maxSpeedMultiplier) {
        currentSpeed =
            GameConstants.initialSpeed * GameConstants.maxSpeedMultiplier;
      }
    }
  }

  void _jump() {
    if (isJumping || isGameOver) return;
    setState(() {
      isJumping = true;
      velocity = jumpForce;
      _animationController.forward(from: 0);
    });
    SoundManager().playJumpSound();
  }

  void _endGame() {
    gameLoopTimer?.cancel();
    _clearPowerUps();
    setState(() {
      isGameOver = true;
      isHit = true;
    });
    SoundManager().playGameOverSound();
    SoundManager().pauseBackgroundMusic();
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => GameOverDialog(
            score: score,
            bestScore: highScore,
            level: level,
            mode: 'infinite',
            onReplay: _restartGame,
            onMenu: () {
              Navigator.of(context).pop(); // Ferme le dialog
              Navigator.of(context).pop(); // Ferme l'écran du mode de jeu
            },
            onSaveScore: (name) {},
          ),
    );
  }

  void _restartGame() {
    // Fermer le dialogue
    Navigator.pop(context);

    // Réinitialiser complètement le jeu
    setState(() {
      isGameStarted = false;
      isGameOver = false;
      isHit = false;
      score = 0;
      level = 1;
      dinoY = groundLevel;
      velocity = 0;
      currentSpeed = GameConstants.initialSpeed;
      isNightMode = false;
      dayNightCycle = 0;
      obstacleXs.clear();
      powerUpXs.clear();
      powerUpTypes.clear();
      _clearPowerUps();
    });

    // Redémarrer le jeu
    _startGame();
  }

  @override
  void dispose() {
    gameLoopTimer?.cancel();
    _clearPowerUps();
    _animationController.dispose();
    SoundManager().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _jump,
      onVerticalDragStart: (_) => _jump(),
      child: Scaffold(
        backgroundColor:
            isNightMode ? Colors.indigo[900] : Colors.blueGrey[900],
        body: Stack(
          children: [
            BackgroundParallax(
              isNightMode: isNightMode,
              customBackground: 'assets/images/background.png',
            ),

            // Nuages défilants
            ScrollingClouds(
              speed: currentSpeed,
              isPaused: false,
              cloudCount: 6,
            ),
            // Dino player
            Positioned(
              left: GamePositions.dinoLeftPosition,
              bottom:
                  GamePositions.dinoGroundLevel -
                  (dinoY * GamePositions.dinoJumpMultiplier),
              child: DinoWidget(
                dinoY: dinoY,
                isJumping: isJumping,
                isHit: isHit,
                hasShield: hasShield,
                hasInvincibility: hasInvincibility,
                hasSpeedBoost: hasSpeedBoost,
                hasDoubleCoins: false,
                hasDamageBoost: false,
                activePowerUp: _getActivePowerUp(),
              ),
            ),

            // Obstacles
            ...obstacleXs.map(
              (x) => Positioned(
                left:
                    x *
                    MediaQuery.of(context).size.width *
                    GamePositions.obstacleWidthMultiplier,
                bottom: GamePositions.obstacleGroundLevel,
                child: const ObstacleWidget(positionX: 0),
              ),
            ),

            // Power-ups
            ...powerUpXs.asMap().entries.map(
              (entry) => Positioned(
                left:
                    entry.value *
                    MediaQuery.of(context).size.width *
                    GamePositions.powerUpWidthMultiplier,
                bottom: GamePositions.powerUpGroundLevel,
                child: PowerUpWidget(
                  xPosition: 0,
                  powerUpType: powerUpTypes[entry.key],
                ),
              ),
            ),
            _buildScoreDisplay(),
            _buildPowerUpIndicators(),
            if (!isGameStarted && !isGameOver) _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Positioned(
      top: 40,
      left: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score: $score',
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          Text(
            'High: $highScore',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          Text(
            'Level: $level',
            style: const TextStyle(fontSize: 16, color: Colors.amber),
          ),
          Text(
            isNightMode ? '🌙 Night' : '☀️ Day',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpIndicators() {
    return Positioned(
      top: 40,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (hasShield)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🛡️', style: TextStyle(fontSize: 20)),
            ),
          if (hasSpeedBoost)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('⚡', style: TextStyle(fontSize: 20)),
            ),
          if (hasInvincibility)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('💎', style: TextStyle(fontSize: 20)),
            ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black54,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        ),
        onPressed: _startGame,
        child: const Text(
          'START GAME',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
