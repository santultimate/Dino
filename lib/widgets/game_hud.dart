import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';

class GameHUD extends StatelessWidget {
  final int score;
  final int bestScore;
  final int level;
  final GameMode mode;
  final int? remainingTime;
  final GameState gameState;
  final VoidCallback onPause;
  final VoidCallback onExit;

  const GameHUD({
    super.key,
    required this.score,
    required this.bestScore,
    required this.level,
    required this.mode,
    this.remainingTime,
    required this.gameState,
    required this.onPause,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(context),
        if (gameState == GameState.paused) _buildPauseOverlay(),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildScoreInfo(),
          if (mode == GameMode.timeAttack) _buildTimeInfo(),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildScoreInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score: $score',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Text(
          'Best: $bestScore',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          'Level: $level',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTimeInfo() {
    return Column(
      children: [
        const Icon(Icons.timer, color: Colors.white, size: 20),
        Text(
          '$remainingTime',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            gameState == GameState.paused ? Icons.play_arrow : Icons.pause,
            color: Colors.white,
          ),
          onPressed: onPause,
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: onExit,
        ),
      ],
    );
  }

  Widget _buildPauseOverlay() {
    return Expanded(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onPause,
                child: const Text('RESUME'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}