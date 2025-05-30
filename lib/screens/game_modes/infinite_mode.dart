import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/dino.dart';
import '../../widgets/obstacle.dart';
import '../../widgets/power_up.dart';
import '../../utils/game_utils.dart';
import '../../utils/sound_manager.dart';
import '../../widgets/scrolling_background.dart';

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

  // Game Objects
  final List<Obstacle> obstacles = [];
  final List<PowerUp> powerUps = [];
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
    SoundManager.initialize();
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
      obstacles.clear();
      powerUps.clear();
    });

    SoundManager.playBackgroundMusic();
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
    obstacles.removeWhere((obs) => obs.update());
    powerUps.removeWhere((pu) => pu.update());
  }

  void _checkCollisions() {
    if (obstacles.any((obs) => obs.collidesWith(dinoY))) {
      _endGame();
    }
    
    // Check power-up collisions
    powerUps.removeWhere((pu) {
      if (pu.collidesWith(dinoY)) {
        _applyPowerUp(pu.type);
        return true;
      }
      return false;
    });
  }

  void _applyPowerUp(PowerUpType type) {
    SoundManager.playPowerUp();
    // Implement power-up effects
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
      obstacles.add(Obstacle(speed: gameSpeed * 2));
    }
    if (score % powerUpInterval == 0) {
      powerUps.add(PowerUp(speed: gameSpeed * 2));
    }
  }

  void _jump() {
    if (isJumping || isGameOver) return;
    
    setState(() {
      isJumping = true;
      velocity = jumpForce;
      _animationController.forward(from: 0);
    });
    SoundManager.playJump();
  }

  void _endGame() {
    gameLoopTimer?.cancel();
    setState(() => isGameOver = true);
    SoundManager.playGameOver();
    SoundManager.pauseBackgroundMusic();
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        score: score,
        highScore: highScore,
        onRestart: _startGame,
        onExit: () => Navigator.pop(context),
      ),
    );
  }

  @override
  void dispose() {
    gameLoopTimer?.cancel();
    _animationController.dispose();
    SoundManager.dispose();
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
            ScrollingBackground(offset: backgroundOffset),
            Dino(yPosition: dinoY, isJumping: isJumping),
            ...obstacles.map((o) => o.build(context)),
            ...powerUps.map((p) => p.build(context)),
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

// GameOverDialog.dart (separate file)
class GameOverDialog extends StatelessWidget {
  final int score;
  final int highScore;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const GameOverDialog({
    super.key,
    required this.score,
    required this.highScore,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Game Over', 
          style: TextStyle(color: Colors.white, fontSize: 24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Score: $score', 
              style: const TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 10),
          Text('High Score: $highScore', 
              style: const TextStyle(color: Colors.white70, fontSize: 18)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onRestart,
          child: const Text('Restart', 
              style: TextStyle(color: Colors.green)),
        ),
        TextButton(
          onPressed: onExit,
          child: const Text('Exit', 
              style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}