import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_mode.dart';
import '../../models/game_state.dart';
import '../../services/game_service.dart';
import '../../services/score_service.dart';
import '../../widgets/dino.dart';
import '../../widgets/obstacle.dart';
import '../../widgets/game_hud.dart';
import '../../widgets/game_over_dialog.dart';
import '../../utils/game_constants.dart';
import '../../widgets/background_parallax.dart';
// import '../../utils/sound_manager.dart'; // Décommente si tu as un gestionnaire audio

class DailyChallengeMode extends StatefulWidget {
  const DailyChallengeMode({super.key});

  @override
  State<DailyChallengeMode> createState() => _DailyChallengeModeState();
}

class _DailyChallengeModeState extends State<DailyChallengeMode>
    with SingleTickerProviderStateMixin {
  late final GameService _gameService;
  late final ScoreService _scoreService;
  late final AnimationController _shakeController;

  // Daily challenge specific variables
  late DailyChallengeConfig _challengeConfig;
  bool _hasAttemptedToday = false;
  int _dailySeed = 0;
  String _challengeDescription = '';
  int _attemptsRemaining = 1;

  @override
  void initState() {
    super.initState();
    _gameService = Provider.of<GameService>(context, listen: false);
    _scoreService = Provider.of<ScoreService>(context, listen: false);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      if (mounted) setState(() {});
    });

    _initializeDailyChallenge();
  }

  Future<void> _initializeDailyChallenge() async {
    await _generateDailyChallenge();
    await _gameService.initialize(mode: GameMode.challenge);
    if (!mounted) return;
    _gameService.addListener(_gameStateListener);
  }

  Future<void> _generateDailyChallenge() async {
    // Generate daily seed based on current date
    final now = DateTime.now();
    _dailySeed = now.year * 10000 + now.month * 100 + now.day;

    // Create random generator with daily seed
    final random = Random(_dailySeed);

    // Generate challenge configuration
    _challengeConfig = _generateChallengeConfig(random);
    _challengeDescription = _generateChallengeDescription();

    // Check if user has already attempted today
    await _checkDailyAttempt();
  }

  DailyChallengeConfig _generateChallengeConfig(Random random) {
    final challengeTypes = [
      ChallengeType.speedFixed,
      ChallengeType.rareObstacles,
      ChallengeType.manyObstacles,
      ChallengeType.noDoubleJumps,
      ChallengeType.precisionRequired,
      ChallengeType.timeLimit,
    ];

    final selectedType = challengeTypes[random.nextInt(challengeTypes.length)];

    switch (selectedType) {
      case ChallengeType.speedFixed:
        return DailyChallengeConfig(
          type: selectedType,
          fixedSpeed: 0.025 + (random.nextDouble() * 0.015),
          obstacleFrequency: 0.02,
          allowDoubleJumps: true,
          timeLimit: null,
          targetScore: 30 + random.nextInt(20),
        );

      case ChallengeType.rareObstacles:
        return DailyChallengeConfig(
          type: selectedType,
          fixedSpeed: null,
          obstacleFrequency: 0.005, // Very rare
          allowDoubleJumps: true,
          timeLimit: null,
          targetScore: 20 + random.nextInt(15),
        );

      case ChallengeType.manyObstacles:
        return DailyChallengeConfig(
          type: selectedType,
          fixedSpeed: null,
          obstacleFrequency: 0.05, // Many obstacles
          allowDoubleJumps: true,
          timeLimit: null,
          targetScore: 50 + random.nextInt(30),
        );

      case ChallengeType.noDoubleJumps:
        return DailyChallengeConfig(
          type: selectedType,
          fixedSpeed: null,
          obstacleFrequency: 0.03,
          allowDoubleJumps: false,
          timeLimit: null,
          targetScore: 25 + random.nextInt(20),
        );

      case ChallengeType.precisionRequired:
        return DailyChallengeConfig(
          type: selectedType,
          fixedSpeed: null,
          obstacleFrequency: 0.025,
          allowDoubleJumps: true,
          timeLimit: null,
          targetScore: 40 + random.nextInt(25),
        );

      case ChallengeType.timeLimit:
        return DailyChallengeConfig(
          type: selectedType,
          fixedSpeed: null,
          obstacleFrequency: 0.03,
          allowDoubleJumps: true,
          timeLimit: 45 + random.nextInt(30), // 45-75 seconds
          targetScore: 35 + random.nextInt(25),
        );
    }
  }

  String _generateChallengeDescription() {
    switch (_challengeConfig.type) {
      case ChallengeType.speedFixed:
        return 'Speed locked at ${(_challengeConfig.fixedSpeed! * 1000).round()} units\nTarget: ${_challengeConfig.targetScore} obstacles';
      case ChallengeType.rareObstacles:
        return 'Obstacles are very rare\nTarget: ${_challengeConfig.targetScore} obstacles';
      case ChallengeType.manyObstacles:
        return 'Obstacles everywhere!\nTarget: ${_challengeConfig.targetScore} obstacles';
      case ChallengeType.noDoubleJumps:
        return 'No consecutive jumps allowed\nTarget: ${_challengeConfig.targetScore} obstacles';
      case ChallengeType.precisionRequired:
        return 'Perfect timing required\nTarget: ${_challengeConfig.targetScore} obstacles';
      case ChallengeType.timeLimit:
        return '${_challengeConfig.timeLimit}s time limit\nTarget: ${_challengeConfig.targetScore} obstacles';
    }
  }

  Future<void> _checkDailyAttempt() async {
    // This would check if user has already attempted today
    // For now, we'll just set it to false
    _hasAttemptedToday = false;
    _attemptsRemaining = _hasAttemptedToday ? 0 : 1;
  }

  void _gameStateListener() {
    if (!mounted) return;
    if (_gameService.state == GameState.gameOver) {
      _handleGameOver();
    }
    setState(() {});
  }

  Future<void> _handleGameOver() async {
    _shakeController.forward(from: 0);
    _hasAttemptedToday = true;
    _attemptsRemaining = 0;

    await _scoreService.saveScore(
      mode: GameMode.challenge,
      score: _gameService.currentScore,
      level: _gameService.level,
    );
    if (!mounted) return;
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => GameOverDialog(
            score: _gameService.currentScore,
            bestScore: 0, // Will be updated with actual value
            mode: 'Daily Challenge',
            level: _gameService.level,
            onReplay: _restartGame,
            onMenu: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to menu
            },
            onSaveScore: (name) async {
              // Handle score saving if needed
            },
          ),
    );
  }

  Future<void> _restartGame() async {
    if (!mounted) return;
    Navigator.of(context).pop(); // Fermer le dialog
    await _gameService.reset();
    if (mounted) setState(() {});
  }

  void _jump() {
    if (_gameService.state == GameState.ready) {
      _gameService.start();
    }
    _gameService.jump();
    // SoundManager.playJump(); // Active si tu utilises un sound manager
  }

  @override
  void dispose() {
    _gameService.removeListener(_gameStateListener);
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = _gameService.state;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: GestureDetector(
        onTap: _jump,
        child: Stack(
          children: [
            _buildBackground(),
            _buildShakeContent(),
            _buildHUD(gameState),
            if (gameState == GameState.ready) _buildStartMessage(),
            _buildChallengeInfo(),
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

  Widget _buildShakeContent() {
    final dinoY = _gameService.dinoPosition;
    final obstaclePosition = _gameService.obstaclePosition;
    final currentObstacle = _gameService.currentObstacle;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shakeOffset =
            _shakeController.value * 10 * (1 - _shakeController.value);
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: Stack(
        children: [
          // Dino player
          Positioned(
            left: GamePositions.dinoLeftPosition,
            bottom:
                GamePositions.dinoGroundLevel -
                (_gameService.dinoPosition * GamePositions.dinoJumpMultiplier),
            child: DinoWidget(
              dinoY: _gameService.dinoPosition,
              isJumping: _gameService.isJumping,
            ),
          ),

          // Obstacle
          Positioned(
            left:
                _gameService.obstaclePosition *
                MediaQuery.of(context).size.width *
                GamePositions.obstacleWidthMultiplier,
            bottom: GamePositions.obstacleGroundLevel,
            child: ObstacleWidget(
              positionX: 0,
              assetPath: _getObstacleAsset(currentObstacle),
            ),
          ),
          // Power-ups will be added here when power-up system is implemented
        ],
      ),
    );
  }

  String _getObstacleAsset(dynamic obstacleType) {
    // This is a placeholder - you'll need to implement proper obstacle type handling
    return 'assets/images/cactus.png';
  }

  Widget _buildHUD(GameState gameState) {
    return GameHUD(
      score: _gameService.currentScore,
      bestScore: 0, // Will be updated with actual value
      level: _gameService.level,
      mode: GameMode.challenge,
      gameState: gameState,
      onPause: _gameService.togglePause,
      onExit: () {
        if (mounted) Navigator.pop(context);
      },
    );
  }

  Widget _buildStartMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'DAILY CHALLENGE',
            style: TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 10,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  _challengeDescription,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Seed: $_dailySeed',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_hasAttemptedToday)
                  const Text(
                    'Already attempted today!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          if (!_hasAttemptedToday)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              onPressed: () => _jump(),
              child: const Text(
                'START CHALLENGE',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengeInfo() {
    return Positioned(
      top: 40,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              '📅 DAILY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Attempts: $_attemptsRemaining',
              style: const TextStyle(fontSize: 10, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

// Challenge configuration classes
enum ChallengeType {
  speedFixed,
  rareObstacles,
  manyObstacles,
  noDoubleJumps,
  precisionRequired,
  timeLimit,
}

class DailyChallengeConfig {
  final ChallengeType type;
  final double? fixedSpeed;
  final double obstacleFrequency;
  final bool allowDoubleJumps;
  final int? timeLimit;
  final int targetScore;

  DailyChallengeConfig({
    required this.type,
    this.fixedSpeed,
    required this.obstacleFrequency,
    required this.allowDoubleJumps,
    this.timeLimit,
    required this.targetScore,
  });
}
