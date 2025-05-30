import 'package:flutter/material.dart';
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
import '../utils/animations.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> 
    with SingleTickerProviderStateMixin {
  late final GameService _gameService;
  late final SoundService _soundService;
  late final ScoreService _scoreService;
  late final PowerUpService _powerUpService;
  late AnimationController _shakeController;
  late AnimationController _powerUpEffectController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _initializeGame();
  }

  void _initializeServices() {
    _gameService = context.read<GameService>();
    _soundService = context.read<SoundService>();
    _scoreService = context.read<ScoreService>();
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
      case GameState.playing:
        _soundService.resumeBackgroundMusic();
      case GameState.paused:
        _soundService.pauseBackgroundMusic();
      case GameState.ready:
        break;
    }
    setState(() {});
  }

  void _powerUpListener() {
    if (_powerUpService.activePowerUps.isNotEmpty) {
      _powerUpEffectController.forward(from: 0);
    }
    setState(() {});
  }

  Future<void> _handleGameOver() async {
    _soundService.playSoundEffect(SoundType.gameOver);
    _shakeController.forward(from: 0);

    final score = _gameService.currentScore;
    await _scoreService.saveScore(
      mode: widget.mode,
      score: score,
      level: _gameService.level,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        score: score,
        highScore: _scoreService.getPlayerHighScore(widget.mode),
        bestScore: _scoreService.getGlobalHighScore(widget.mode),
        mode: widget.mode,
        level: _gameService.level,
        powerUpsUsed: _powerUpService.powerUpsUsed,
        onReplay: _restartGame,
        onMenu: () => Navigator.pop(context),
        onSaveScore: (name) => _scoreService.saveScore(
          name: name,
          score: score,
          mode: widget.mode,
          level: _gameService.level,
        ),
      ),
    );
  }

  Future<void> _restartGame() async {
    await _gameService.reset();
    await _powerUpService.reset();
    await _soundService.resumeBackgroundMusic();
    if (mounted) setState(() {});
  }

  void _jump() {
    if (_gameService.state == GameState.ready) {
      _gameService.start();
    }
    _gameService.jump();
    _soundService.playSoundEffect(SoundType.jump);
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
            // Parallax Background
            BackgroundParallax(
              speed: _gameService.speed / 2,
              isDarkMode: _scoreService.isDarkMode,
            ),

            // Game Elements with Shake Effect
            _buildGameElements(),

            // Power-Up Visual Effect
            _buildPowerUpEffect(),

            // Game HUD
            GameHUD(
              score: score,
              bestScore: _scoreService.getPlayerHighScore(widget.mode),
              level: level,
              mode: widget.mode,
              remainingTime: _gameService.remainingTime,
              gameState: gameState,
              activePowerUps: _powerUpService.activePowerUps,
              onPause: _togglePause,
              onExit: () => Navigator.pop(context),
            ),

            // Start Message
            if (gameState == GameState.ready) _buildStartMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameElements() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeController.value * 20 * (1 - _shakeController.value), 
            0
          ),
          child: child,
        );
      },
      child: Stack(
        children: [
          DinoWidget(
            positionY: _gameService.dinoPosition,
            isJumping: _gameService.isJumping,
            skin: _scoreService.selectedSkin,
            isInvincible: _powerUpService.isPowerUpActive(PowerUpType.invincibility),
          ),
          ..._gameService.obstacles.map((obs) => ObstacleWidget(
            positionX: obs.position,
            type: obs.type,
          )),
          ..._powerUpService.activePowerUps.map((pu) => PowerUpWidget(
            positionX: pu.position,
            type: pu.type,
          )),
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
    )
    );

  }
}