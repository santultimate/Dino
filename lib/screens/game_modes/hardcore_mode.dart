import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/dino.dart' as dino_widget;
import '../../widgets/obstacle.dart' as obstacle_widget;
import '../../widgets/ground.dart' as ground_widget;
import '../../widgets/cloud.dart' as cloud_widget;
import '../../utils/sound_manager.dart';

class HardcoreMode extends StatefulWidget {
  const HardcoreMode({super.key});

  @override
  State<HardcoreMode> createState() => _HardcoreModeState();
}

class _HardcoreModeState extends State<HardcoreMode> with SingleTickerProviderStateMixin {
  // Player variables
  double dinoY = 1;
  double time = 0;
  double height = 0;
  double initialHeight = 1;
  bool isJumping = false;
  bool isDucking = false;
  
  // Game variables
  List<double> obstacleXs = [2, 3, 4];
  List<double> cloudXs = [1, 2.5, 4];
  int score = 0;
  int highScore = 0;
  Timer? gameTimer;
  bool isGameOver = false;
  bool isPaused = false;
  
  // Difficulty
  late AnimationController difficultyController;
  final Random random = Random();
  
  // Screen dimensions
  late double screenWidth;
  late double screenHeight;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    difficultyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(() {
        if (difficultyController.value >= 1.0) {
          difficultyController.repeat(reverse: true);
        }
      })..forward();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  void startGame() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isPaused && !isGameOver) {
        _updateGame();
      }
    });
  }

  void _updateGame() {
    time += 0.016; // ~60fps
    height = -4.9 * time * time + 5 * time;

    setState(() {
      // Update dino position
      dinoY = initialHeight - height;
      if (dinoY > 1) {
        dinoY = 1;
        isJumping = false;
      }

      // Update obstacles
      final speed = 0.05 * (1 + difficultyController.value * 3);
      for (int i = 0; i < obstacleXs.length; i++) {
        obstacleXs[i] -= speed;
        
        // Reset obstacle when off screen
        if (obstacleXs[i] < -1.2) {
          obstacleXs[i] = 2 + random.nextDouble();
          score++;
          
          // Update high score if needed
          if (score > highScore) {
            highScore = score;
            _saveHighScore();
          }
        }
        
        // Collision detection
        if (obstacleXs[i] < 0.2 && obstacleXs[i] > -0.2 && 
            dinoY > 0.6 && !isDucking) {
          endGame();
        }
      }

      // Update clouds
      for (int i = 0; i < cloudXs.length; i++) {
        cloudXs[i] -= speed * 0.5;
        if (cloudXs[i] < -1.2) {
          cloudXs[i] = 2 + random.nextDouble() * 3;
        }
      }
    });
  }

  void jump() {
    if (!isJumping && !isGameOver && !isPaused) {
      time = 0;
      initialHeight = dinoY;
      isJumping = true;
      SoundManager().playJumpSound();
    }
  }

  void toggleDuck(bool ducking) {
    if (!isJumping && !isGameOver && !isPaused) {
      setState(() {
        isDucking = ducking;
      });
    }
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
      if (isPaused) {
        gameTimer?.cancel();
      } else {
        startGame();
      }
    });
  }

  void endGame() {
    setState(() {
      isGameOver = true;
    });
    gameTimer?.cancel();
    SoundManager().playGameOverSound();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('💀 Game Over', 
               style: TextStyle(color: Colors.white, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $score', 
                 style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 10),
            Text('High Score: $highScore', 
                 style: const TextStyle(color: Colors.amber, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetGame();
            },
            child: const Text('🔁 Rejouer', 
                   style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('🏠 Menu', 
                   style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    setState(() {
      dinoY = 1;
      obstacleXs = [2, 3, 4];
      cloudXs = [1, 2.5, 4];
      score = 0;
      isGameOver = false;
      isJumping = false;
      isDucking = false;
      time = 0;
      initialHeight = 1;
    });
    difficultyController.reset();
    difficultyController.forward();
    startGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    difficultyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFf7f7f7),
      body: GestureDetector(
        onTap: jump,
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! > 0) { // Swipe down
            toggleDuck(true);
          } else if (details.primaryDelta! < 0) { // Swipe up
            toggleDuck(false);
          }
        },
        child: Stack(
          children: [
            // Background elements
            ...cloudXs.map((x) => AnimatedContainer(
              alignment: Alignment(x, -0.7),
              duration: Duration(milliseconds: isPaused ? 0 : 100),
              child: cloud_widget.Cloud(),
            )),

            // Ground
            const Align(
              alignment: Alignment.bottomCenter,
              child: ground_widget.Ground(),
            ),

            // Dino player
            AnimatedContainer(
              alignment: Alignment(-0.8, dinoY),
              duration: Duration(milliseconds: isPaused ? 0 : 100),
              child: dino_widget.DinoWidget(
                dinoY: 0,
                isDucking: isDucking,
                isJumping: isJumping,
              ),
            ),

            // Obstacles
            ...obstacleXs.map((x) => AnimatedContainer(
              alignment: Alignment(x, 1),
              duration: Duration(milliseconds: isPaused ? 0 : 100),
              child: obstacle_widget.ObstacleWidget(positionX: x * 100),
            )),

            // UI Elements
            Positioned(
              top: 50,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.white,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'High Score: $highScore',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.white,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pause button
            if (!isGameOver)
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(
                    isPaused ? Icons.play_arrow : Icons.pause,
                    size: 30,
                    color: Colors.black87,
                  ),
                  onPressed: togglePause,
                ),
              ),

            // Pause overlay
            if (isPaused && !isGameOver)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Text(
                    'PAUSE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}