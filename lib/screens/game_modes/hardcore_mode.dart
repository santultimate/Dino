import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import '../../utils/game_constants.dart';
import '../../utils/sound_manager.dart';
import '../../widgets/background_parallax.dart';
import '../../widgets/cloud.dart' as cloud_widget;
import '../../widgets/dino.dart' as dino_widget;
import '../../widgets/ground.dart' as ground_widget;
import '../../widgets/obstacle.dart' as obstacle_widget;
import '../../services/score_service.dart';
import '../../models/game_state.dart';

class HardcoreMode extends StatefulWidget {
  const HardcoreMode({super.key});

  @override
  State<HardcoreMode> createState() => _HardcoreModeState();
}

class _HardcoreModeState extends State<HardcoreMode>
    with SingleTickerProviderStateMixin {
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
  int level = 1;
  Timer? gameTimer;
  bool isGameOver = false;
  bool isPaused = false;

  // Hardcore specific variables
  double currentSpeed = GameConstants.hardcoreInitialSpeed;
  double speedMultiplier = 1.0;
  bool isLowLight = false;
  int consecutiveJumps = 0;
  int maxConsecutiveJumps = 2; // Limit consecutive jumps
  int coinsEarned = 0; // Coins earned in hardcore mode
  bool isInvincible = false; // No invincibility in hardcore

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
    difficultyController =
        AnimationController(vsync: this, duration: const Duration(seconds: 30))
          ..addListener(() {
            if (difficultyController.value >= 1.0) {
              difficultyController.repeat(reverse: true);
            }
          })
          ..forward();

    // Démarrer le jeu automatiquement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startGame();
    });
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScoreHardcore') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScoreHardcore', highScore);
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
        consecutiveJumps = 0; // Reset consecutive jumps when landing
      }

      // Update obstacles with extreme speed
      final speed = currentSpeed * (1 + difficultyController.value * 2);
      for (int i = 0; i < obstacleXs.length; i++) {
        obstacleXs[i] -= speed;

        // Reset obstacle when off screen
        if (obstacleXs[i] < -1.2) {
          obstacleXs[i] = 2 + random.nextDouble();
          score++;

          // Earn coins in hardcore mode (most rewarding)
          coinsEarned += GameConstants.hardcoreModeCoinsPerObstacle;

          // Update high score if needed
          if (score > highScore) {
            highScore = score;
            _saveHighScore();
          }

          // Level up faster in hardcore mode
          if (score % GameConstants.hardcoreLevelUpInterval == 0) {
            level++;
            currentSpeed += GameConstants.hardcoreSpeedIncrement;
            speedMultiplier += 0.1;

            // Toggle low light mode every few levels
            if (level % 3 == 0) {
              isLowLight = !isLowLight;
            }
          }
        }

        // Collision detection - more precise
        if (obstacleXs[i] < 0.2 &&
            obstacleXs[i] > -0.2 &&
            dinoY < 0.8 &&
            !isDucking) {
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
    if (!isJumping &&
        !isGameOver &&
        !isPaused &&
        consecutiveJumps < maxConsecutiveJumps) {
      time = 0;
      initialHeight = dinoY;
      isJumping = true;
      consecutiveJumps++;
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
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              '💀 HARDCORE OVER',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Score: $score',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  'Level: $level',
                  style: const TextStyle(color: Colors.orange, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  'High Score: $highScore',
                  style: const TextStyle(color: Colors.amber, fontSize: 18),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Only one life. No power-ups.\nPure survival.',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  resetGame();
                },
                child: const Text(
                  '🔁 Try Again',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('🏠 Menu', style: TextStyle(fontSize: 18)),
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
      coinsEarned = 0; // Reset coins
      level = 1;
      currentSpeed = GameConstants.hardcoreInitialSpeed;
      speedMultiplier = 1.0;
      isLowLight = false;
      consecutiveJumps = 0;
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
      backgroundColor: isLowLight ? Colors.black : const Color(0xFFf7f7f7),
      body: GestureDetector(
        onTap: jump,
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! > 0) {
            // Swipe down
            toggleDuck(true);
          } else if (details.primaryDelta! < 0) {
            // Swipe up
            toggleDuck(false);
          }
        },
        child: Stack(
          children: [
            // Background with parallax effect
            BackgroundParallax(
              isNightMode: isLowLight,
              customBackground: 'assets/images/background.png',
            ),

            // Background elements with low light effect
            ...cloudXs.map(
              (x) => Positioned(
                left: x * MediaQuery.of(context).size.width * 0.8,
                top: 50,
                child: cloud_widget.CloudWidget(
                  speed: 1.0,
                  initialX: x * MediaQuery.of(context).size.width * 0.8,
                  y: 50,
                ),
              ),
            ),

            // Ground
            const Align(
              alignment: Alignment.bottomCenter,
              child: ground_widget.Ground(),
            ),

            // Dino player
            Positioned(
              left: GamePositions.dinoLeftPosition,
              bottom:
                  GamePositions.dinoGroundLevel -
                  (dinoY * GamePositions.dinoJumpMultiplier),
              child: dino_widget.DinoWidget(
                dinoY: 0,
                isDucking: isDucking,
                isJumping: isJumping,
              ),
            ),

            // Obstacles
            ...obstacleXs.map(
              (x) => Positioned(
                left:
                    x *
                    MediaQuery.of(context).size.width *
                    GamePositions.obstacleWidthMultiplier,
                bottom: GamePositions.obstacleGroundLevel,
                child: const obstacle_widget.ObstacleWidget(positionX: 0),
              ),
            ),

            // UI Elements
            Positioned(
              top: 50,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score: $score',
                    style: TextStyle(
                      color: isLowLight ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: isLowLight ? Colors.black : Colors.white,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'High: $highScore',
                    style: TextStyle(
                      color: isLowLight ? Colors.amber : Colors.orange,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: isLowLight ? Colors.black : Colors.white,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Level: $level',
                    style: TextStyle(
                      color: isLowLight ? Colors.red : Colors.red[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: isLowLight ? Colors.black : Colors.white,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '💰 $coinsEarned',
                    style: TextStyle(
                      color: isLowLight ? Colors.yellow : Colors.amber[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: isLowLight ? Colors.black : Colors.white,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  if (isLowLight)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🌙 LOW LIGHT',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Hardcore mode indicator
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Text(
                  '💀 HARDCORE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    color: isLowLight ? Colors.white : Colors.black87,
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

            // Low light overlay
            if (isLowLight)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const SizedBox.expand(),
              ),
          ],
        ),
      ),
    );
  }
}
