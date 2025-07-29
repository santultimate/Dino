import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/dino.dart';
import '../../widgets/obstacle.dart';
import '../../widgets/power_up.dart';
import '../../utils/game_utils.dart';
import '../../utils/sound_manager.dart';
import '../../utils/game_constants.dart';
import '../../utils/game_physics.dart';
import '../../widgets/game_over_dialog.dart';
import '../../models/power_up_type.dart';
import '../../widgets/background_parallax.dart';
import '../../models/game_mode.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  double dinoY = 1;
  bool isJumping = false;
  int score = 0;
  int bestScore = 0;
  double obstacleX = 1;
  bool gameStarted = false;
  bool isPaused = false;
  bool isGameOver = false;
  int level = 1;
  List<int> topScores = [];

  // Time Attack specific variables
  int remainingTime = GameConstants.timeAttackDuration;
  double speed = GameConstants.timeAttackInitialSpeed;
  double scoreMultiplier = 1.0;
  bool hasTimeBonus = false;
  bool hasSpeedBoost = false;
  bool hasCoinMultiplier = false;
  Timer? timeBonusTimer;
  Timer? speedBoostTimer;
  Timer? coinMultiplierTimer;
  int coinsEarned = 0; // Coins earned during this run

  // Power-up system
  final List<double> powerUpXs = [];
  final List<PowerUpType> powerUpTypes = [];
  final Random _random = Random();

  late AnimationController _jumpController;
  late SharedPreferences _prefs;
  final SoundManager _soundManager = SoundManager();
  Timer? gameTimer;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    _initGame();
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(_handleJumpAnimation);
  }

  Future<void> _initGame() async {
    _prefs = await SharedPreferences.getInstance();
    bestScore = _prefs.getInt('bestScoreTimeAttack') ?? 0;
    topScores = List<int>.from(
      jsonDecode(_prefs.getString('topScoresTimeAttack') ?? '[]'),
    );
    await _soundManager.initialize();
    if (mounted) setState(() {});
  }

  void _handleJumpAnimation() {
    if (!isJumping) return;
    final jumpHeight = GamePhysics.calculateJumpHeight(_jumpController.value);
    setState(() => dinoY = 1 - jumpHeight);

    if (_jumpController.isCompleted) {
      _jumpController.reset();
      isJumping = false;
      setState(() => dinoY = 1);
    }
  }

  void _startGame() {
    if (gameStarted) return;
    gameStarted = true;
    isGameOver = false;
    obstacleX = 1;
    score = 0;
    coinsEarned = 0; // Reset coins
    level = 1;
    speed = GameConstants.timeAttackInitialSpeed;
    scoreMultiplier = 1.0;
    remainingTime = GameConstants.timeAttackDuration;
    powerUpXs.clear();
    powerUpTypes.clear();
    _clearTimeBonus();
    _clearSpeedBoost();
    _clearCoinMultiplier();

    _soundManager.playBackgroundMusic();
    _startGameLoop();
    _startCountdown();
  }

  void _startGameLoop() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isPaused && mounted) {
        setState(() {
          obstacleX -= speed * 1.5;

          if (obstacleX < -1.2) {
            obstacleX = 1;
            score += (1 * scoreMultiplier).round();

            // Earn coins based on mode
            int coinsToEarn = GameConstants.timeAttackCoinsPerObstacle;
            if (hasCoinMultiplier) {
              coinsToEarn *= 2; // Double coins with multiplier
            }
            coinsEarned += coinsToEarn;

            if (score % GameConstants.levelUpInterval == 0) {
              speed += GameConstants.timeAttackSpeedIncrement;
              level++;
            }
          }

          // Update power-ups
          for (int i = 0; i < powerUpXs.length; i++) {
            powerUpXs[i] -= speed * 1.5;
          }
          powerUpXs.removeWhere((x) => x < -1.2);
          for (int i = powerUpTypes.length - 1; i >= 0; i--) {
            if (powerUpXs.length <= i) {
              powerUpTypes.removeAt(i);
            }
          }

          // Check power-up collisions
          for (int i = 0; i < powerUpXs.length; i++) {
            if (powerUpXs[i] < 0.3 && powerUpXs[i] > 0.1 && dinoY > 0.8) {
              _applyPowerUp(powerUpTypes[i]);
              powerUpXs.removeAt(i);
              powerUpTypes.removeAt(i);
              break;
            }
          }

          // Spawn power-ups
          if (score % 20 == 0 && powerUpXs.length < 2) {
            powerUpXs.add(1.2);
            powerUpTypes.add(_getRandomPowerUp());
          }

          if (_checkCollision()) {
            _soundManager.playCrashSound();
            _endGame();
            timer.cancel();
          }
        });
      }
    });
  }

  void _startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused && mounted) {
        setState(() {
          remainingTime--;

          if (remainingTime <= 0) {
            _endGame();
            timer.cancel();
          }
        });
      }
    });
  }

  PowerUpType _getRandomPowerUp() {
    final powerUps = [
      PowerUpType.speedBoost,
      PowerUpType.healthBoost,
      PowerUpType.doubleCoins, // Add coin multiplier
    ];
    return powerUps[_random.nextInt(powerUps.length)];
  }

  PowerUpType? _getActivePowerUp() {
    if (hasSpeedBoost) return PowerUpType.speedBoost;
    if (hasTimeBonus) return PowerUpType.healthBoost;
    if (hasCoinMultiplier) return PowerUpType.doubleCoins;
    return null;
  }

  void _activateTimeBonus() {
    hasTimeBonus = true;
    remainingTime += GameConstants.timeAttackBonusTime;
    timeBonusTimer?.cancel();
    timeBonusTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => hasTimeBonus = false);
    });
  }

  void _activateSpeedBoost() {
    hasSpeedBoost = true;
    speedBoostTimer?.cancel();
    speedBoostTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => hasSpeedBoost = false);
    });
  }

  void _activateCoinMultiplier() {
    hasCoinMultiplier = true;
    coinMultiplierTimer?.cancel();
    coinMultiplierTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => hasCoinMultiplier = false);
    });
  }

  void _clearTimeBonus() {
    hasTimeBonus = false;
    timeBonusTimer?.cancel();
  }

  void _clearSpeedBoost() {
    hasSpeedBoost = false;
    speedBoostTimer?.cancel();
  }

  void _clearCoinMultiplier() {
    hasCoinMultiplier = false;
    coinMultiplierTimer?.cancel();
  }

  bool _checkCollision() {
    return obstacleX < GameConstants.collisionRightBound &&
        obstacleX > GameConstants.collisionLeftBound &&
        dinoY > GameConstants.collisionHeightThreshold;
  }

  void _jump() {
    if (isJumping || !gameStarted || isPaused) return;
    isJumping = true;
    _soundManager.playJumpSound();
    _jumpController.forward(from: 0);
  }

  void _endGame() async {
    if (isGameOver) return;
    isGameOver = true;
    gameTimer?.cancel();
    countdownTimer?.cancel();
    _clearTimeBonus();
    await _soundManager.pauseBackgroundMusic();

    if (score > bestScore) {
      bestScore = score;
      await _prefs.setInt('bestScoreTimeAttack', bestScore);
    }

    topScores.add(score);
    topScores.sort((a, b) => b.compareTo(a));
    if (topScores.length > GameConstants.maxTopScores) {
      topScores = topScores.sublist(0, GameConstants.maxTopScores);
    }
    await _prefs.setString('topScoresTimeAttack', jsonEncode(topScores));

    if (!mounted) return;
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => GameOverDialog(
            score: score,
            bestScore: bestScore,
            level: level,
            mode: widget.mode.name,
            onReplay: _resetGame,
            onMenu: () {
              Navigator.of(context).pop(); // Ferme le dialog
              Navigator.of(context).pop(); // Ferme l'écran du mode de jeu
            },
            onSaveScore: (name) async {
              // Save score logic here
              if (kDebugMode) print('Score saved for $name: $score');
            },
          ),
    );
  }

  void _resetGame() {
    // Fermer le dialogue
    Navigator.pop(context);

    if (!mounted) return;
    setState(() {
      gameStarted = false;
      isGameOver = false;
      isPaused = false;
      score = 0;
      level = 1;
      dinoY = 1;
      obstacleX = 1.2;
      powerUpXs.clear();
      powerUpTypes.clear();
      remainingTime = GameConstants.timeAttackDuration;
      _clearTimeBonus();
    });
    _soundManager.resumeBackgroundMusic();
  }

  void _togglePause() {
    setState(() => isPaused = !isPaused);
    isPaused
        ? _soundManager.pauseBackgroundMusic()
        : _soundManager.resumeBackgroundMusic();
  }

  void _applyPowerUp(PowerUpType powerUpType) {
    _soundManager.playCoinSound();

    switch (powerUpType) {
      case PowerUpType.speedBoost:
        _activateSpeedBoost();
        break;
      case PowerUpType.healthBoost:
        _activateTimeBonus();
        break;
      case PowerUpType.doubleCoins:
        _activateCoinMultiplier();
        break;
      default:
        // Handle other power-ups if needed
        break;
    }
  }

  @override
  void dispose() {
    _jumpController.dispose();
    gameTimer?.cancel();
    countdownTimer?.cancel();
    _clearTimeBonus();
    _soundManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: gameStarted ? _jump : _startGame,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildBackground(),
            Positioned(
              left: GamePositions.dinoLeftPosition,
              bottom:
                  GamePositions.dinoGroundLevel -
                  (dinoY * GamePositions.dinoJumpMultiplier),
              child: DinoWidget(
                dinoY: dinoY,
                isJumping: isJumping,
                hasShield: false,
                hasInvincibility: false,
                hasSpeedBoost: hasSpeedBoost,
                hasDoubleCoins: hasCoinMultiplier,
                hasDamageBoost: false,
                activePowerUp: _getActivePowerUp(),
              ),
            ),
            Positioned(
              left:
                  obstacleX *
                  MediaQuery.of(context).size.width *
                  GamePositions.obstacleWidthMultiplier,
              bottom: GamePositions.obstacleGroundLevel,
              child: const ObstacleWidget(positionX: 0),
            ),
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
            _buildHUD(),
            _buildTimer(),
            if (!gameStarted && !isGameOver) _buildStartButton(),
            if (isPaused && !isGameOver) _buildPauseOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return const BackgroundParallax(
      isNightMode: false,
      customBackground: 'assets/images/background.png',
    );
  }

  Widget _buildHUD() {
    return Positioned(
      top: 40,
      left: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score: $score',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Best: $bestScore',
            style: const TextStyle(fontSize: 18, color: Colors.amber),
          ),
          Text(
            'Level: $level',
            style: const TextStyle(fontSize: 16, color: Colors.green),
          ),
          Text(
            '💰 $coinsEarned',
            style: const TextStyle(fontSize: 16, color: Colors.yellow),
          ),
          // Power-up indicators
          if (hasSpeedBoost)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚡ SPEED',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (hasCoinMultiplier)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💰 x2 COINS',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return Positioned(
      top: 40,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: remainingTime <= 10 ? Colors.red : Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasTimeBonus ? Colors.green : Colors.white,
            width: 2,
          ),
        ),
        child: Text(
          '${remainingTime}s',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: hasTimeBonus ? Colors.green : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'TIME ATTACK',
            style: TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '60 seconds to score as much as possible!',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            onPressed: _startGame,
            child: const Text(
              'START',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Text(
          'PAUSED',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
