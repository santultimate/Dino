import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/game_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/shop_screen.dart';
import 'models/game_mode.dart';
import 'services/game_service.dart';
import 'services/sound_service.dart';
import 'services/score_service.dart';
import 'services/settings_service.dart';
import 'widgets/mode_button.dart';
import 'package:dino_game_v2/services/shop_service.dart' as shop_service;



void main() {
  runApp(
    MultiProvider(
      providers: [
            ChangeNotifierProvider(create: (_) => GameService()),
            ChangeNotifierProvider(create: (_) => SettingsService()),
            ChangeNotifierProvider(create: (_) => shop_service.ShopService()), // <- corrigé
            Provider(create: (_) => SoundService()),
            Provider(create: (_) => ScoreService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dino Game',
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _startGame(BuildContext context, GameMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(mode: mode),
      ),
    );
  }

  void _showLeaderboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LeaderboardScreen(),
      ),
    );
  }

  void _showShop(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShopScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dino Game'),
        actions: [
          const ModeButton(),
          IconButton(
            icon: const Icon(Icons.shop),
            onPressed: () => _showShop(context),
            tooltip: 'Boutique',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/dino.png',
                  height: 120,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 30),
                Text(
                  'Dino Game',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    shadows: [
                      const Shadow(
                        color: Colors.green,
                        blurRadius: 10,
                        offset: Offset.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildGameButton(
                  context,
                  'Mode Infini',
                  () => _startGame(context, GameMode.infinite),
                  Colors.green,
                ),
                _buildGameButton(
                  context,
                  'Time Attack',
                  () => _startGame(context, GameMode.timeAttack),
                  Colors.blue,
                ),
                _buildGameButton(
                  context,
                  'Défi du jour',
                  () => _startGame(context, GameMode.challenge),
                  Colors.orange,
                ),
                _buildGameButton(
                  context,
                  'Mode Hardcore',
                  () => _startGame(context, GameMode.hardcore),
                  Colors.red,
                ),
                const SizedBox(height: 30),
                _buildGameButton(
                  context,
                  'Classement',
                  () => _showLeaderboard(context),
                  Colors.purple,
                  icon: Icons.leaderboard,
                ),
                _buildGameButton(
                  context,
                  'Boutique',
                  () => _showShop(context),
                  Colors.amber,
                  icon: Icons.shop,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
    Color color, {
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 24),
            if (icon != null) const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
