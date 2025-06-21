import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'game_mode_service.dart';
import 'mode_card.dart';
import '../models/game_mode.dart';

class DifficultySelectorScreen extends StatefulWidget {
  const DifficultySelectorScreen({super.key});

  @override
  State<DifficultySelectorScreen> createState() => _DifficultySelectorScreenState();
}

class _DifficultySelectorScreenState extends State<DifficultySelectorScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _gameModes = [
    {
      'type': GameMode.infinite,
      'title': 'Mode Infini',
      'subtitle': 'Cours le plus longtemps possible sans limite de temps',
      'icon': Icons.all_inclusive,
      'color': Colors.teal,
      'difficulty': '⭐',
    },
    {
      'type': GameMode.timeAttack,
      'title': 'Contre-la-montre',
      'subtitle': 'Fais le meilleur score en 60 secondes',
      'icon': Icons.timer,
      'color': Colors.orange,
      'difficulty': '⭐⭐',
    },
    {
      'type': GameMode.challenge,
      'title': 'Défi Quotidien',
      'subtitle': 'Un challenge unique chaque jour',
      'icon': Icons.calendar_today,
      'color': Colors.blue,
      'difficulty': '⭐⭐⭐',
    },
    {
      'type': GameMode.hardcore,
      'title': 'Mode Hardcore',
      'subtitle': 'Un seul essai, vitesse extrême',
      'icon': Icons.flash_on,
      'color': const Color.fromARGB(255, 188, 173, 172),
      'difficulty': '⭐⭐⭐⭐⭐',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Démarre l'animation après le premier frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToGameMode(GameMode mode) {
    final gameModeService = context.read<GameModeService>();
    gameModeService.setCurrentMode(mode);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => gameModeService.getModeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisissez un Mode'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.shade700,
                Colors.teal.shade400,
              ],
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _gameModes.length,
          itemBuilder: (context, index) {
            final mode = _gameModes[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _gameModes.length - 1 ? 0 : 16,
              ),
              child: ModeCard(
                title: mode['title'],
                subtitle: mode['subtitle'],
                icon: mode['icon'],
                color: mode['color'],
                difficulty: mode['difficulty'],
                isDarkMode: isDarkMode,
                onTap: () => _navigateToGameMode(mode['type']),
                animationDelay: index * 100,
              ),
            );
          },
        ),
      ),
    );
  }
}