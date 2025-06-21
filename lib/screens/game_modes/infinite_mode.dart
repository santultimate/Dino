import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/dino.dart';
import '../../widgets/obstacle.dart';
import '../../widgets/power_up.dart';
import '../../widgets/scrolling_background.dart';
import '../../widgets/game_over_dialog.dart';
import '../../utils/game_utils.dart';
import '../../utils/sound_manager.dart';
import '../../models/power_up_type.dart';

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
  int score = 0;
  int highScore = 0;
  double backgroundOffset = 0;

  // Game Objects (store positions)
  final List<double> obstacleXs = [];
  final List<double> powerUpXs = [];
  final List<PowerUpType> powerUpTypes = [];
  Timer? gameLoopTimer;
  late AnimationController _animationController;

  // Constants
  static const double gravity = -9.8; // More realistic gravity
  static const double jumpForce = 4.0; // Adjusted jump force
  static const double groundLevel = 0;
  static const double gameSpeed = 0.005;
  static const int obstacleInterval = 100;
  static const int powerUpInterval = 300;

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
      score = 0;
      dinoY = groundLevel;
      velocity = 0;
      backgroundOffset = 0;
      obstacleXs.clear();
      powerUpXs.clear();
      powerUpTypes.clear();
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
      _updateBackground();
      _updateObjects();
      _checkCollisions();
      _updateScore();
      _spawnObjects();
    });
  }

  void _updatePhysics() {
    velocity += gravity * 0.016; // Frame-time adjusted
    dinoY -= velocity * 0.016;
    // Ground collision
    if (dinoY > groundLevel) {
      dinoY = groundLevel;
      velocity = 0;
      isJumping = false;
    }
  }

  void _updateBackground() {
    backgroundOffset -= gameSpeed;
    if (backgroundOffset <= -1) backgroundOffset += 1;
  }

  void _updateObjects() {
    for (int i = 0; i < obstacleXs.length; i++) {
      obstacleXs[i] -= gameSpeed * 2;
    }
    for (int i = 0; i < powerUpXs.length; i++) {
      powerUpXs[i] -= gameSpeed * 2;
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
    // Simple collision check: if obstacle is close to dino
    for (final x in obstacleXs) {
      if (x < 0.2 && x > -0.2 && dinoY == groundLevel) {
        _endGame();
        return;
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
    SoundManager().playCoinSound(); // Use coin sound for now
    // Implement power-up effects here
  }

  void _updateScore() {
    score++;
    if (score > highScore) {
      highScore = score;
      _saveHighScore();
    }
  }

  void _spawnObjects() {
    if (score % obstacleInterval == 0) {
      obstacleXs.add(1.2); // Spawn at right edge
    }
    if (score % powerUpInterval == 0) {
      powerUpXs.add(1.2);
      powerUpTypes.add(PowerUpType.shield); // Example type
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
    setState(() => isGameOver = true);
    SoundManager().playGameOverSound();
    SoundManager().pauseBackgroundMusic();
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        score: score,
        bestScore: highScore,
        level: 1,
        mode: 'infinite',
        onReplay: _startGame,
        onMenu: () => Navigator.pop(context),
        onSaveScore: (name) {},
      ),
    );
  }

  @override
  void dispose() {
    gameLoopTimer?.cancel();
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
        backgroundColor: Colors.blueGrey[900],
        body: Stack(
          children: [
            ScrollingBackground(scrollFactor: backgroundOffset),
            DinoWidget(dinoY: dinoY, isJumping: isJumping),
            ...obstacleXs.map((x) => ObstacleWidget(positionX: x * MediaQuery.of(context).size.width)),
            ...powerUpXs.map((x) => PowerUpWidget(xPosition: x)),
            _buildScoreDisplay(),
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
          Text('Score: $score', 
              style: const TextStyle(fontSize: 20, color: Colors.white)),
          Text('High: $highScore', 
              style: const TextStyle(fontSize: 16, color: Colors.white70)),
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
        child: const Text('START GAME', 
            style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}