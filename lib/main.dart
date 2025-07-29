import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/game_mode_service.dart';
import 'services/game_service.dart';
import 'services/sound_service.dart';
import 'services/score_service.dart';
import 'services/settings_service.dart';
import 'services/power_up_service.dart';
import 'services/coin_service.dart';
import 'services/shop_service.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase temporarily disabled for development
  // TODO: Download correct google-services.json from Firebase Console
  bool firebaseInitialized = false;
  print('🚫 Firebase temporarily disabled for development');
  print('💡 To enable: Download google-services.json from Firebase Console');

  // Initialize AdService
  final adService = AdService();
  await adService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProvider(create: (_) => ShopService()),
        ChangeNotifierProvider(create: (_) => SoundService()),
        Provider(
          create: (_) => ScoreService(firebaseInitialized: firebaseInitialized),
        ),
        ChangeNotifierProvider(create: (_) => PowerUpService()),
        ChangeNotifierProvider(create: (_) => CoinService()),
        // Firebase services disabled for development
        // ChangeNotifierProvider(create: (_) => AchievementsService()),
        // Provider(create: (_) => FirebaseService()),
        ChangeNotifierProvider(create: (_) => GameModeService()),
        ChangeNotifierProvider(create: (_) => AdService()),
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
