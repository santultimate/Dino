import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';

class GameHUD extends StatelessWidget {
  final int score;
  final int bestScore;
  final int level;
  final GameMode mode;
  final int remainingTime;
  final GameState gameState;
  final VoidCallback onPause;
  final VoidCallback onExit;

  const GameHUD({
    super.key,
    required this.score,
    required this.bestScore,
    required this.level,
    required this.mode,
    required this.remainingTime,
    required this.gameState,
    required this.onPause,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final levelColors = _getLevelColors();
    final color = levelColors[(level - 1) % levelColors.length];

    return Column(
      children: [
        // Top Bar with game info
        _buildTopBar(color),
        
        // Game mode indicator
        _buildModeIndicator(),
        
        // Pause overlay if game is paused
        if (gameState == GameState.paused) _buildPauseOverlay(),
      ],
    );
  }

  List<Color> _getLevelColors() {
    return [
      Colors.white,
      Colors.lightGreenAccent,
      Colors.yellow,
      Colors.orange,
      Colors.redAccent,
    ];
  }

  Widget _buildTopBar(Color levelColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBackButton(),
          _buildScoreInfo(levelColor),
          _buildTimerAndBestScore(),
          _buildPauseButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: onExit,
      tooltip: 'Quitter',
    );
  }

  Widget _buildScoreInfo(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Score: $score',
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(1, 1),
            
          ),
            ],
          ),
        ),
        


        Text(
          'Level: $level',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerAndBestScore() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          mode == GameMode.timeAttack
              ? '⏱️ ${remainingTime}s'
              : '⏱️ ${(score * 0.03).toStringAsFixed(1)}s',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Best: $bestScore',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildPauseButton() {
    if (gameState == GameState.ready) return const SizedBox(width: 48);
    
    return IconButton(
      icon: Icon(
        gameState == GameState.paused ? Icons.play_arrow : Icons.pause,
        color: Colors.white,
        size: 28,
      ),
      onPressed: onPause,
      tooltip: gameState == GameState.paused ? 'Reprendre' : 'Pause',
    );
  }

  Widget _buildModeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: Text(
        'MODE: ${_getModeName(mode)}',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.amber,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _getModeName(GameMode mode) {
    switch (mode) {
      case GameMode.infinite:
        return 'INFINI';
      case GameMode.timeAttack:
        return 'CONTRE LA MONTRE';
      case GameMode.dailyChallenge:
        return 'DÉFI QUOTIDIEN';
      case GameMode.hardcore:
        return 'HARDCORE';
    }
  }

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PAUSE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                      offset: Offset(2, 2),
                         ),
                
                    ],
                ),
              ),
              
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: onPause,
                child: const Text(
                  'REPRENDRE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}