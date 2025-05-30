import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/game_service.dart';
import '../../services/score_service.dart';
import '../../services/power_up_service.dart';
import '../../widgets/dino.dart';
import '../../widgets/obstacle.dart';
import '../../widgets/power_up.dart';
import '../../widgets/game_hud.dart';
import '../../widgets/game_over_dialog.dart';

class InfiniteMode extends StatefulWidget {
  const InfiniteMode({super.key});

  @override
  State<InfiniteMode> createState() => _InfiniteModeState();
}

class _InfiniteModeState extends State<InfiniteMode> with SingleTickerProviderStateMixin {
  late final GameService _gameService;
  late final ScoreService _scoreService;
  late final PowerUpService _powerUpService;
  late AnimationController _shakeController;
  StreamSubscription? _gameStateSubscription; // Ajout pour gérer la souscription

  @override
  void initState() {
    super.initState();
    _gameService = Provider.of<GameService>(context, listen: false);
    _scoreService = Provider.of<ScoreService>(context, listen: false);
    _powerUpService = Provider.of<PowerUpService>(context, listen: false);
    
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _gameService.initialize(mode: GameMode.infinite);
    // Remplacement de addListener par un StreamSubscription pour une meilleure gestion
    _gameStateSubscription = _gameService.gameStateStream.listen((_) {
      _gameStateListener();
    });
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
    await _scoreService.saveScore(
      mode: GameMode.infinite,
      score: _gameService.currentScore,
      level: _gameService.level,
    );
    if (!mounted) return;
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        score: _gameService.currentScore,
        bestScore: _scoreService.getBestScore(GameMode.infinite),
        level: _gameService.level,
        onRestart: _restartGame,
      ),
    );
  }

  Future<void> _restartGame() async {
    Navigator.of(context).pop(); // Fermer le dialogue avant de redémarrer
    await _gameService.reset();
    if (mounted) setState(() {});
  }

  void _jump() {
    if (_gameService.state == GameState.ready) {
      _gameService.start();
    }
    _gameService.jump();
  }

  @override
  void dispose() {
    _gameStateSubscription?.cancel(); // Annulation de la souscription
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = _gameService.state;
    final dinoY = _gameService.dinoPosition;
    final obstacles = _gameService.obstacles;
    final powerUps = _powerUpService.activePowerUps;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: GestureDetector(
        onTap: _jump,
        child: Stack(
          children: [
            // Game Background
            Positioned.fill(
              child: Image.asset(
                'assets/images/desert_bg.png',
                fit: BoxFit.cover,
                color: Colors.grey[800],
                colorBlendMode: BlendMode.multiply,
              ),
            ),

            // Game Elements with Shake Effect
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final shakeOffset = _shakeController.value * 10 * (1 - _shakeController.value);
                return Transform.translate(
                  offset: Offset(shakeOffset, 0),
                  child: child,
                );
              },
              child: Stack(
                children: [
                  DinoWidget(
                    positionY: dinoY,
                    isJumping: _gameService.isJumping,
                    skin: _scoreService.selectedSkin,
                  ),
                  ...obstacles.map((o) => ObstacleWidget(
                    positionX: o.position, 
                    type: o.type,
                    key: ValueKey(o.id), // Ajout d'une clé unique pour chaque obstacle
                  )),
                  ...powerUps.map((p) => PowerUpWidget(
                    positionX: p.position, 
                    type: p.type,
                    key: ValueKey(p.id), // Ajout d'une clé unique pour chaque power-up
                  )),
                ],
              ),
            ),

            // Game HUD
            GameHUD(
              score: _gameService.currentScore,
              bestScore: _scoreService.getBestScore(GameMode.infinite),
              level: _gameService.level,
              mode: GameMode.infinite,
              gameState: gameState,
              onPause: _gameService.togglePause,
              onExit: () => Navigator.pop(context),
            ),

            // Start Message
            if (gameState == GameState.ready)
              const Center(
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
              ),
          ],
        ),
      ),
    );
  }
}