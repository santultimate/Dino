// lib/screens/game_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../services/sound_service.dart';
import '../services/score_service.dart';
import '../services/power_up_service.dart';
import '../widgets/dino.dart';
import '../widgets/obstacle.dart';
import '../widgets/power_up.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/background_parallax.dart';
import '../models/game_state.dart';
import '../models/game_mode.dart';
import '../models/power_up_type.dart';
import '../models/obstacle_type.dart';
import '../utils/animations.dart';
import '../models/sound_type.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late final GameService _gameService;
  late final SoundService _soundService;
  late final ScoreService _scoreService;
  late final PowerUpService _powerUpService;
  late AnimationController _shakeController;
  late AnimationController _powerUpEffectController;
  late AnimationController _jumpEffectController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _initializeGame();
  }

  void _initializeServices() {
    _gameService = context.read<GameService>();
    _soundService = Provider.of<SoundService>(context, listen: false);
    // _scoreService = context.read<ScoreService>(); // Temporarily disabled
    _powerUpService = context.read<PowerUpService>();
  }

  void _initializeAnimations() {
    _shakeController = createShakeAnimation(this);
    _powerUpEffectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _powerUpEffectController.reverse();
        }
      });

    _jumpEffectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
  }

  Future<void> _initializeGame() async {
    await _gameService.initialize(mode: widget.mode);
    await _soundService.initialize();
    await _powerUpService.initialize();
    _gameService.addListener(_gameStateListener);
    _powerUpService.addListener(_powerUpListener);
  }

  void _gameStateListener() {
    if (!mounted) return;

    switch (_gameService.state) {
      case GameState.gameOver:
        _handleGameOver();
        _soundService.playSoundEffect(SoundType.collision);
        HapticFeedback.heavyImpact();
        break;
      case GameState.playing:
        _soundService.resumeBackgroundMusic();
        break;
      case GameState.paused:
        _soundService.pauseBackgroundMusic();
        break;
      case GameState.ready:
        break;
    }

    setState(() {});
  }

  void _powerUpListener() {
    if (_powerUpService.activePowerUps.isNotEmpty) {
      _powerUpEffectController.forward(from: 0);
      _soundService.playSoundEffect(SoundType.powerUp);
      HapticFeedback.mediumImpact();
    }
    setState(() {});
  }

  Future<void> _handleGameOver() async {
    _shakeController.forward(from: 0);
    final score = _gameService.currentScore;

    // Temporarily disabled ScoreService functionality
    // await _scoreService.saveScore(
    //   mode: widget.mode,
    //   score: score,
    //   level: _gameService.level,
    // );

    // final highScore = await _scoreService.getBestScore(widget.mode);
    // final bestScore = await _scoreService.getGlobalHighScore();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        score: score,
        highScore: 0, // Temporarily set to 0
        bestScore: 0, // Temporarily set to 0
        mode: widget.mode.toString(),
        level: _gameService.level,
        powerUpsUsed: null,
        onReplay: _restartGame,
        onMenu: () {
          Navigator.pop(context); // Close the dialog
          Navigator.pop(context); // Go back to home screen
        },
        onSaveScore: (name) {
          // Temporarily disabled
          // _scoreService.saveScore(
          //   mode: widget.mode,
          //   score: score,
          //   level: _gameService.level,
          // );
        },
      ),
    );
  }

  Future<void> _restartGame() async {
    Navigator.pop(context); // Close the game over dialog
    await _gameService.reset();
    await _soundService.resumeBackgroundMusic();
    if (mounted) setState(() {});
  }

  void _jump() {
    if (_gameService.state != GameState.ready &&
        _gameService.state != GameState.playing) {
      return;
    }

    if (_gameService.state == GameState.ready) {
      _gameService.start();
    }

    _jumpEffectController.forward(from: 0).then((_) => _jumpEffectController.reverse());
    _gameService.jump();
    _soundService.playSoundEffect(SoundType.jump);
    HapticFeedback.selectionClick();
  }

  void _togglePause() {
    _gameService.togglePause();
  }

  @override
  void dispose() {
    _gameService.removeListener(_gameStateListener);
    _powerUpService.removeListener(_powerUpListener);
    _shakeController.dispose();
    _powerUpEffectController.dispose();
    _jumpEffectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = _gameService.state;
    final score = _gameService.currentScore;
    final level = _gameService.level;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _jump,
        onVerticalDragStart: (_) => _jump(),
        child: Stack(
          children: [
            BackgroundParallax(
              speed: 0.02,
              isDarkMode: false,
            ),
            _buildGameElements(),
            _buildPowerUpEffect(),
            GameHUD(
              score: score,
              bestScore: 0,
              level: level,
              mode: widget.mode,
              remainingTime: _gameService.remainingTime,
              gameState: gameState,
              onPause: _togglePause,
              onExit: () => Navigator.pop(context),
            ),
            if (gameState == GameState.ready) _buildStartMessage(),
            if (gameState == GameState.gameOver) _buildBlurOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameElements() {
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeController, _jumpEffectController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeController.value * 20 * (1 - _shakeController.value),
            0,
          ),
          child: Transform.scale(
            scale: 1.0 + _jumpEffectController.value,
            child: child,
          ),
        );
      },
      child: Stack(
        children: [
          DinoWidget(
            dinoY: _gameService.dinoPosition,
            isJumping: _gameService.isJumping,
            runVelocity: 1.0,
          ),
          // Obstacle qui défile
          ObstacleWidget(
            positionX: _gameService.obstaclePosition * MediaQuery.of(context).size.width,
            assetPath: _getObstacleAsset(_gameService.currentObstacle),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpEffect() {
    return AnimatedBuilder(
      animation: _powerUpEffectController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.yellow.withOpacity(_powerUpEffectController.value * 0.2),
                Colors.transparent,
              ],
              radius: 1.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartMessage() {
    return const Center(
      child: Text(
        'TAP TO START',
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
    );
  }

  Widget _buildBlurOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
        child: Container(
          color: Colors.black.withOpacity(0.2),
        ),
      ),
    );
  }

  String _getObstacleAsset(ObstacleType obstacleType) {
    switch (obstacleType) {
      case ObstacleType.cactus:
        return 'assets/images/cactus.png';
      case ObstacleType.bird:
        return 'assets/images/cactus.png'; // Using cactus for now, replace with bird.png when available
      case ObstacleType.rock:
        return 'assets/images/cactus.png'; // Using cactus for now, replace with rock.png when available
      default:
        return 'assets/images/cactus.png';
    }
  }
}
