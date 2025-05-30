import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/dino.dart';
import '../widgets/obstacle.dart';
import '../utils/game_utils.dart';
import '../utils/sound_manager.dart';
import '../utils/game_constants.dart';
import '../utils/game_physics.dart';
import '../widgets/game_over_dialog.dart';

enum GameMode { infinite, timeAttack, dailyChallenge, hardcore }

class GameScreen extends StatefulWidget {
  final GameMode mode;
  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
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

  double speed = GameConstants.initialSpeed;
  late AnimationController _jumpController;
  late SharedPreferences _prefs;
  final SoundManager _soundManager = SoundManager();
  Timer? gameTimer;

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
    bestScore = _prefs.getInt('bestScore') ?? 0;
    topScores = List<int>.from(jsonDecode(_prefs.getString('topScores') ?? '[]'));
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
    speed = GameConstants.initialSpeed;
    level = 1;

    _soundManager.playBackgroundMusic();
    _startGameLoop();
  }

  void _startGameLoop() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isPaused && mounted) {
        setState(() {
          obstacleX -= speed;

          if (obstacleX < -1.2) {
            obstacleX = 1;
            score++;

            if (score % GameConstants.levelUpInterval == 0) {
              speed += GameConstants.speedIncrement;
              level++;
            }
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
    await _soundManager.pauseBackgroundMusic();

    if (score > bestScore) {
      bestScore = score;
      await _prefs.setInt('bestScore', bestScore);
    }

    topScores.add(score);
    topScores.sort((a, b) => b.compareTo(a));
    if (topScores.length > GameConstants.maxTopScores) {
      topScores = topScores.sublist(0, GameConstants.maxTopScores);
    }
    await _prefs.setString('topScores', jsonEncode(topScores));

    if (!mounted) return;
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        score: score,
        bestScore: bestScore,
        level: level,
        topScores: topScores,
        onRestart: _resetGame,
        onExit: () => Navigator.pop(context),
      ),
    );
  }

  void _resetGame() {
    if (!mounted) return;
    setState(() {
      gameStarted = false;
      isGameOver = false;
      isPaused = false;
      dinoY = 1;
    });
    _soundManager.resumeBackgroundMusic();
  }

  void _togglePause() {
    setState(() => isPaused = !isPaused);
    isPaused ? _soundManager.pauseBackgroundMusic() : _soundManager.resumeBackgroundMusic();
  }

  @override
  void dispose() {
    _jumpController.dispose();
    gameTimer?.cancel();
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
            DinoWidget(positionY: dinoY),
            ObstacleWidget(positionX: obstacleX),
            _buildGameInfo(),
            if (!gameStarted && !isGameOver) _buildStartPrompt(),
            _buildPauseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/background.png',
        fit: BoxFit.cover,
        opacity: const AlwaysStoppedAnimation(0.8),
      ),
    );
  }

  Widget _buildGameInfo() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Score: $score",
                  style: TextStyle(
                    fontSize: 22,
                    color: GameUtils.getLevelColor(level),
                  ),
                ),
                Text(
                  "Niveau: $level",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            Text(
              "Best: $bestScore",
              style: const TextStyle(fontSize: 22, color: Colors.white70),
            ),
          ],
        ),
        Center(
          child: Text(
            "Mode: ${widget.mode.name.toUpperCase()}",
            style: const TextStyle(fontSize: 18, color: Colors.amber),
          ),
        ),
      ],
    );
  }

  Widget _buildStartPrompt() {
    return const Center(
      child: Text(
        "TAP TO START",
        style: TextStyle(fontSize: 28, color: Colors.white70),
      ),
    );
  }

  Widget _buildPauseButton() {
    return Positioned(
      top: 40,
      right: 20,
      child: Visibility(
        visible: gameStarted && !isGameOver,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
          ),
          onPressed: _togglePause,
          child: Text(isPaused ? 'RESUME' : 'PAUSE'),
        ),
      ),
    );
  }
}
