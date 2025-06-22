import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/game_mode.dart';
import '../models/obstacle_type.dart';

class GameService with ChangeNotifier {
  GameState _state = GameState.ready;
  double _dinoPosition = 1.0;
  double _obstaclePosition = 1.0;
  bool _isJumping = false;
  int _score = 0;
  int _level = 1;
  double _speed = 0.02;
  int _remainingTime = 60;
  ObstacleType _currentObstacle = ObstacleType.cactus;
  GameMode _currentMode = GameMode.infinite;
  bool _isGameOverHandled = false; // Flag to prevent multiple game over events

  Timer? _gameTimer;
  Timer? _countdownTimer;
  Timer? _jumpTimer;

  // Getters
  GameState get state => _state;
  double get dinoPosition => _dinoPosition;
  double get obstaclePosition => _obstaclePosition;
  bool get isJumping => _isJumping;
  int get currentScore => _score;
  int get level => _level;
  int get remainingTime => _remainingTime;
  ObstacleType get currentObstacle => _currentObstacle;
  GameMode get currentMode => _currentMode;

  Future<void> initialize({required GameMode mode}) async {
    _currentMode = mode;
    _resetGame();
    _currentObstacle = _getRandomObstacle();
  }

  void start() {
    if (_state != GameState.ready) return;
    
    _state = GameState.playing;
    _startGameLoop();
    
    if (_currentMode == GameMode.timeAttack) {
      _startCountdown();
    }
    
    notifyListeners();
  }

  void jump() {
    // Prevent jumping if game is not playing or already jumping
    if (_isJumping || _state != GameState.playing) return;

    _isJumping = true;
    double time = 0;
    const double jumpForce = 10.0; // Adjusted from 12.0 to 10.0 for more controlled jump
    const double gravity = 12.0; // Adjusted from 15.0 to 12.0 for smoother fall
    final double initialHeight = _dinoPosition;

    _jumpTimer?.cancel();
    _jumpTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // Stop jumping if game state changes
      if (_state != GameState.playing) {
        timer.cancel();
        _isJumping = false;
        return;
      }
      
      time += 0.016;
      final height = -0.5 * gravity * time * time + jumpForce * time;
      _dinoPosition = initialHeight - height / 2.8; // Adjusted from /3.0 to /2.8 for better height

      if (_dinoPosition >= 1.0) {
        _dinoPosition = 1.0;
        _isJumping = false;
        timer.cancel();
      }
      notifyListeners();
    });
  }

  void togglePause() {
    if (_state == GameState.playing) {
      _pauseGame();
    } else if (_state == GameState.paused) {
      _resumeGame();
    }
    notifyListeners();
  }

  Future<void> reset() async {
    _resetGame();
    notifyListeners();
  }

  void _startGameLoop() {
    const frameDuration = Duration(milliseconds: 16);
    _gameTimer = Timer.periodic(frameDuration, (timer) {
      // Check if game is still playing, if not, stop the timer immediately
      if (_state != GameState.playing || _isGameOverHandled) {
        timer.cancel();
        return;
      }

      _obstaclePosition -= _speed;
      
      // Check collision and stop immediately if collision occurs
      if (_checkCollision()) {
        timer.cancel(); // Stop the timer immediately
        _endGame();
        return;
      }

      if (_obstaclePosition < -0.3) { // Spawn new obstacle when current one is off-screen left
        _spawnNewObstacle();
      }

      notifyListeners();
    });
  }

  void _startCountdown() {
    const oneSecond = Duration(seconds: 1);
    _countdownTimer = Timer.periodic(oneSecond, (timer) {
      if (_state != GameState.playing) {
        timer.cancel();
        return;
      }

      _remainingTime--;
      
      if (_remainingTime <= 0) {
        _endGame();
      }
      
      notifyListeners();
    });
  }

  bool _checkCollision() {
    // Simplified and more accurate collision detection
    final obstacleX = _obstaclePosition;
    final dinoX = 0.2; // Dino's X position (left side of screen)
    final dinoY = _dinoPosition;
    
    // Check if obstacle is close to dino horizontally
    if (obstacleX > dinoX - 0.1 && obstacleX < dinoX + 0.2) {
      // Only trigger collision if dino is at ground level (not jumping)
      if (dinoY >= 0.98) { // Dino is at ground level (1.0 is ground)
        return true;
      }
    }
    return false;
  }

  void _spawnNewObstacle() {
    _obstaclePosition = 1.2; // Spawn new obstacle off-screen to the right
    _score++;
    _currentObstacle = _getRandomObstacle();

    if (_score % 5 == 0) {
      _level++;
      _speed += 0.0003; // Reduced from 0.0005 to 0.0003 for smoother progression
    }
  }

  ObstacleType _getRandomObstacle() {
    final random = DateTime.now().millisecond % ObstacleType.values.length;
    return ObstacleType.values[random];
  }

  void _pauseGame() {
    _state = GameState.paused;
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _jumpTimer?.cancel();
  }

  void _resumeGame() {
    _state = GameState.playing;
    _startGameLoop();
    if (_currentMode == GameMode.timeAttack) {
      _startCountdown();
    }
  }

  void _endGame() {
    gameOver();
  }

  void _resetGame() {
    _pauseGame();
    
    _state = GameState.ready;
    _dinoPosition = 1.0;
    _obstaclePosition = 1.2; // Start obstacle off-screen to the right
    _isJumping = false;
    _score = 0;
    _level = 1;
    _speed = 0.006; // Reduced from 0.008 to 0.006 for better balance with new jump
    _remainingTime = 60;
    _currentObstacle = ObstacleType.cactus;
    _isGameOverHandled = false; // Reset the game over flag
  }

  void gameOver() {
    // Prevent multiple game over events
    if (_isGameOverHandled) return;
    _isGameOverHandled = true;
    
    // Immediately stop all timers to prevent multiple game over events
    _jumpTimer?.cancel();
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    
    // Set state to game over
    _state = GameState.gameOver;
    
    // Remove auto-restart - game stops completely
    // Timer(const Duration(seconds: 2), () {
    //   if (_state == GameState.gameOver) {
    //     _isGameOverHandled = false; // Reset flag before restart
    //     reset();
    //     start();
    //   }
    // });
    
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _jumpTimer?.cancel();
    super.dispose();
  }
}