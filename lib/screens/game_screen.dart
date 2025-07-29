// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../models/obstacle_type.dart';
import '../models/power_up_type.dart';
import '../models/sound_type.dart';
import '../services/game_service.dart';
import '../services/power_up_service.dart';
import '../services/sound_service.dart';
import '../services/ad_service.dart';
import '../utils/game_constants.dart';
import '../widgets/background_parallax.dart';
import '../widgets/dino.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/obstacle.dart';
import '../utils/animations.dart';
import '../services/score_service.dart';
import '../widgets/cloud.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final GameService _gameService;
  late final SoundService _soundService;
  late final ScoreService _scoreService;
  late final PowerUpService _powerUpService;
  late AnimationController _shakeController;
  late AnimationController _powerUpEffectController;
  late AnimationController _jumpEffectController;
  int _bestScore = 0;
  bool _musicStarted = false;

  @override
  void initState() {
    super.initState();
    _gameService = context.read<GameService>();
    _powerUpService = context.read<PowerUpService>();
    _soundService = context.read<SoundService>();
    _scoreService =
        context.read<ScoreService>(); // Réactivé pour la sauvegarde des scores

    // Initialiser les contrôleurs d'animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _powerUpEffectController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _jumpEffectController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _gameService.addListener(_gameStateListener);
    _powerUpService.addListener(_powerUpListener);

    // Initialiser le jeu
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _gameService.initialize(mode: widget.mode);
    await _soundService.initialize();
    await _powerUpService.initialize();

    // Charger le meilleur score pour ce mode
    _bestScore = await _scoreService.getBestScore(widget.mode);
    setState(() {}); // Mettre à jour l'interface
  }

  void _gameStateListener() {
    if (!mounted) return;

    switch (_gameService.state) {
      case GameState.gameOver:
        _handleGameOver();
        _soundService.playSoundEffect(SoundType.collision);
        HapticFeedback.heavyImpact();
        _musicStarted = false; // Reset music flag
        break;
      case GameState.playing:
        // Démarrer la musique seulement si pas encore démarrée
        if (!_musicStarted) {
          _soundService.playBackgroundMusic();
          _musicStarted = true;
        }
        // Vérifier si un nouveau meilleur score est atteint
        if (_gameService.currentScore > _bestScore) {
          setState(() {
            _bestScore = _gameService.currentScore;
          });
        }
        break;
      case GameState.paused:
        _soundService.pauseBackgroundMusic();
        break;
      case GameState.ready:
        // Ne pas démarrer la musique ici, attendre que le jeu commence
        _musicStarted = false; // Reset music flag
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

    // Ne pas sauvegarder automatiquement, attendre que l'utilisateur entre son nom
    // await _scoreService.saveScore(
    //   mode: widget.mode,
    //   score: score,
    //   level: _gameService.level,
    //   playerName: 'Joueur', // Nom par défaut
    // );

    final highScore = await _scoreService.getBestScore(widget.mode);
    final bestScore = await _scoreService.getGlobalHighScore();

    // Mettre à jour le meilleur score local
    setState(() {
      _bestScore = highScore;
    });

    // Notifier que les scores ont été mis à jour
    _notifyScoreUpdate();

    // Afficher une publicité interstitielle après un délai
    final adService = context.read<AdService>();
    adService.showInterstitialAdAfterDelay(const Duration(seconds: 2));

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => GameOverDialog(
            score: score,
            highScore: highScore,
            bestScore: bestScore,
            mode: widget.mode.toString(),
            level: _gameService.level,
            powerUpsUsed: null,
            onReplay: _restartGame,
            onMenu: () {
              _soundService.stopBackgroundMusic(); // Arrêter la musique
              Navigator.pop(context); // Close the dialog
              Navigator.pop(context); // Go back to home screen
            },
            onSaveScore: (name) {
              _scoreService.saveScore(
                mode: widget.mode,
                score: score,
                level: _gameService.level,
                playerName: name, // Passer le nom du joueur
              );
              // Notifier à nouveau après sauvegarde
              _notifyScoreUpdate();
            },
          ),
    );
  }

  // Méthode pour notifier la mise à jour des scores
  void _notifyScoreUpdate() {
    // Les scores sont automatiquement mis à jour via SharedPreferences
    // Le HomeScreen se mettra à jour quand on y retourne
  }

  Future<void> _restartGame() async {
    Navigator.pop(context); // Close the game over dialog
    await _gameService.reset();
    // La musique sera redémarrée automatiquement quand l'état devient 'ready'
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

    _jumpEffectController
        .forward(from: 0)
        .then((_) => _jumpEffectController.reverse());
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
    // Arrêter la musique quand on quitte le jeu
    _soundService.stopBackgroundMusic();
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
            const BackgroundParallax(
              isNightMode: false,
              customBackground: 'assets/images/background.png',
            ),
            _buildGameElements(),
            _buildPowerUpEffect(),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: GameHUD(
                score: score,
                bestScore: _bestScore,
                level: level,
                mode: widget.mode,
                remainingTime: _gameService.remainingTime,
                gameState: gameState,
                onPause: _togglePause,
                onExit: () {
                  _soundService.stopBackgroundMusic(); // Arrêter la musique
                  Navigator.pop(context);
                },
              ),
            ),
            if (gameState == GameState.ready) _buildStartMessage(),
            if (gameState == GameState.gameOver) _buildBlurOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameElements() {
    final gameState = _gameService.state;

    // Ne montrer les éléments du jeu que si le jeu a commencé
    if (gameState == GameState.ready) {
      return const SizedBox.shrink(); // Rien afficher avant le début du jeu
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeController, _jumpEffectController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeController.value * 20 * (1 - _shakeController.value),
            0,
          ),
          child: Transform.scale(
            scale: 1.0 + _jumpEffectController.value * 0.1,
            child: child,
          ),
        );
      },
      child: Stack(
        children: [
          // Nuages en arrière-plan
          ..._buildClouds(),
          // Dino positionné correctement avec effet de saut amélioré
          Positioned(
            left: GamePositions.dinoLeftPosition,
            bottom:
                GamePositions.dinoGroundLevel +
                _gameService.dinoPosition * GamePositions.dinoJumpMultiplier,
            child: Transform.translate(
              offset: Offset(0, -_jumpEffectController.value * 10),
              child: DinoWidget(
                dinoY: _gameService.dinoPosition,
                isJumping: _gameService.isJumping,
                isHit: _gameService.isHit,
                runVelocity: 0.3,
              ),
            ),
          ),
          // Obstacle positionné correctement
          Positioned(
            left:
                _gameService.obstaclePosition *
                MediaQuery.of(context).size.width,
            bottom: GamePositions.obstacleGroundLevel,
            child: ObstacleWidget(
              positionX: 0, // Pas besoin de positionX car on utilise Positioned
              assetPath: _getObstacleAsset(_gameService.currentObstacle),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildClouds() {
    final screenWidth = MediaQuery.of(context).size.width;
    final clouds = <Widget>[];

    // Créer plusieurs nuages avec différentes positions et vitesses
    for (int i = 0; i < 5; i++) {
      final initialX = screenWidth + (i * 200.0);
      final y = 50.0 + (i * 40.0);
      final speed = 0.5 + (i * 0.2);
      final size = 40.0 + (i * 10.0);

      clouds.add(
        CloudWidget(speed: speed, initialX: initialX, y: y, size: size),
      );
    }

    return clouds;
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
            Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 0)),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
        child: Container(color: Colors.black.withOpacity(0.2)),
      ),
    );
  }

  String _getObstacleAsset(ObstacleType obstacleType) {
    switch (obstacleType) {
      case ObstacleType.cactus:
        return 'assets/images/cactus.png';
      case ObstacleType.bird:
        return 'assets/images/perodac.png'; // Using cactus for now, replace with bird.png when available
      case ObstacleType.rock:
        return 'assets/images/rock.png'; // Using cactus for now, replace with rock.png when available
      default:
        return 'assets/images/cactus.png';
    }
  }
}
