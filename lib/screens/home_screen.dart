 //lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/settings_service.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import '../models/game_mode.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _titleAnimationController;
  late Animation<double> _titleScaleAnimation;
  late Animation<Offset> _titleOffsetAnimation;

  bool _showContent = false;
  bool _showBestScoreButton = false;
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    _setupAnimations();
    _triggerContentAppearance();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('bestScore') ?? 0;
    });
  }

  void _setupAnimations() {
    _titleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _titleScaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _titleOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _titleAnimationController.forward();
  }

  void _triggerContentAppearance() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showContent = true);
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showBestScoreButton = true);
    });
  }

  void _navigateToGame(GameMode mode) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => GameScreen(mode: mode),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _showBestScoreDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.greenAccent, width: 2),
        ),
        title: const Text(
          'Meilleur Score',
          style: TextStyle(color: Colors.greenAccent),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 50, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              '🏆 $_bestScore points',
              style: const TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, IconData icon, int delay, VoidCallback onTap) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ElevatedButton.icon(
          icon: Icon(icon, size: 28, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
          ),
          onPressed: onTap,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final isDarkMode = settings.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // AppBar avec bouton paramètres
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.greenAccent),
                  onPressed: _navigateToSettings,
                ),
              ),

              // Titre animé
              SlideTransition(
                position: _titleOffsetAnimation,
                child: ScaleTransition(
                  scale: _titleScaleAnimation,
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/dino.png',
                        height: 100,
                        color: isDarkMode ? Colors.white : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'DINO RUNNER',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                          shadows: const [Shadow(color: Colors.green, blurRadius: 12)],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenu principal
              Expanded(
                child: AnimatedOpacity(
                  opacity: _showContent ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Choisis un mode de jeu :',
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                      const SizedBox(height: 30),
                      _buildModeButton('Infini', Icons.all_inclusive, 0, () => _navigateToGame(GameMode.infinite)),
                      _buildModeButton('Contre-la-montre', Icons.timer, 150, () => _navigateToGame(GameMode.timeAttack)),
                      _buildModeButton('Défi du jour', Icons.calendar_today, 300, () => _navigateToGame(GameMode.challenge)),
                      _buildModeButton('Hardcore', Icons.whatshot, 450, () => _navigateToGame(GameMode.hardcore)),
                    ],
                  ),
                ),
              ),

              // Bouton meilleur score
              if (_showBestScoreButton)
                AnimatedSlide(
                  duration: const Duration(milliseconds: 800),
                  offset: _showBestScoreButton ? Offset.zero : const Offset(0, 2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _showBestScoreButton ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton.icon(
                        onPressed: _showBestScoreDialog,
                        icon: const Icon(Icons.emoji_events, color: Colors.amber),
                        label: const Text('Meilleur Score'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade800,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
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
