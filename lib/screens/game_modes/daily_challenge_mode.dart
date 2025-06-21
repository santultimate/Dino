import 'dart:async';
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
// import '../../utils/sound_manager.dart'; // Décommente si tu as un gestionnaire audio

class DailyChallengeMode extends StatefulWidget {
  const DailyChallengeMode({super.key});

  @override
  State<DailyChallengeMode> createState() => _DailyChallengeModeState();
}

class _DailyChallengeModeState extends State<DailyChallengeMode> with SingleTickerProviderStateMixin {
  late final GameService _gameService;
  late final ScoreService _scoreService;
  late final AnimationController _shakeController;

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

    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _gameService.initialize(mode: GameMode.challenge);
    if (!mounted) return;
    _gameService.addListener(_gameStateListener);
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
      builder: (_) => GameOverDialog(
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
        color: Colors.grey[800],
        colorBlendMode: BlendMode.multiply,
      ),
    );
  }

  Widget _buildShakeContent() {
    final dinoY = _gameService.dinoPosition;
    final obstaclePosition = _gameService.obstaclePosition;
    final currentObstacle = _gameService.currentObstacle;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shakeOffset = _shakeController.value * 10 * (1 - _shakeController.value);
        return Transform.translate(offset: Offset(shakeOffset, 0), child: child);
      },
      child: Stack(
        children: [
          DinoWidget(
            dinoY: dinoY,
            isJumping: _gameService.isJumping,
          ),
          ObstacleWidget(
            positionX: obstaclePosition * MediaQuery.of(context).size.width,
            assetPath: _getObstacleAsset(currentObstacle),
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
}
