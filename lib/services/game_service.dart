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
    notifyListeners();
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
    if (_isJumping || _state != GameState.playing) return;

    _isJumping = true;
    double time = 0;
    const double jumpForce = 5.0;
    const double gravity = 9.8;
    final double initialHeight = _dinoPosition;

    _jumpTimer?.cancel();
    _jumpTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      time += 0.016;
      final height = -0.5 * gravity * time * time + jumpForce * time;
      _dinoPosition = initialHeight - height / 3;

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
      if (_state != GameState.playing) return;

      _obstaclePosition -= _speed;
      
      if (_checkCollision()) {
        _endGame();
        return;
      }

      if (_obstaclePosition < -1.2) {
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
    return _obstaclePosition < 0.2 && 
           _obstaclePosition > -0.2 && 
           _dinoPosition > 0.7;
  }

  void _spawnNewObstacle() {
    _obstaclePosition = 1.0;
    _score++;
    _currentObstacle = _getRandomObstacle();

    if (_score % 5 == 0) {
      _level++;
      _speed += 0.002;
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
    _state = GameState.gameOver;
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _jumpTimer?.cancel();
    notifyListeners();
  }

  void _resetGame() {
    _pauseGame();
    
    _state = GameState.ready;
    _dinoPosition = 1.0;
    _obstaclePosition = 1.0;
    _isJumping = false;
    _score = 0;
    _level = 1;
    _speed = 0.02;
    _remainingTime = 60;
    _currentObstacle = ObstacleType.cactus;
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _jumpTimer?.cancel();
    super.dispose();
  }
}