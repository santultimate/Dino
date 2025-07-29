//lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/settings_service.dart';
import '../services/shop_service.dart';
import '../services/score_service.dart';
import '../services/ad_service.dart';
import '../utils/game_constants.dart';
import '../widgets/ad_banner.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'about_screen.dart';
import '../models/game_mode.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _titleAnimationController;
  late Animation<double> _titleScaleAnimation;
  late Animation<Offset> _titleOffsetAnimation;

  bool _showContent = false;
  bool _showBestScoreButton = false;
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBestScore();
    _setupAnimations();
    _triggerContentAppearance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger le meilleur score quand on revient du jeu
    _loadBestScore();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Recharger les scores quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      _loadBestScore();
    }
  }

  Future<void> _loadBestScore() async {
    try {
      final scoreService = context.read<ScoreService>();
      final bestScore = await scoreService.getBestScore(GameMode.infinite);
      debugPrint('🏆 Loading best score: $bestScore');
      if (mounted) {
        setState(() {
          _bestScore = bestScore;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading best score: $e');
    }
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
          return FadeTransition(opacity: animation, child: child);
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

  void _navigateToShop() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    );
  }

  void _showBestScoreDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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

  void _showScoreHistoryDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.greenAccent, width: 2),
            ),
            title: const Text(
              'Historique des Scores',
              style: TextStyle(color: Colors.greenAccent, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Meilleur score en tête
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            const Text(
                              'Meilleur Score',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$_bestScore points',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Titre de la liste
                  const Text(
                    'Top 5 des Derniers Joueurs',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Liste des 5 derniers joueurs avec mise à jour automatique
                  Consumer<ScoreService>(
                    builder: (context, scoreService, child) {
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: scoreService.getLastPlayersHistory(
                          GameMode.infinite,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.greenAccent,
                              ),
                            );
                          }

                          final players = snapshot.data ?? [];

                          if (players.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Aucun score enregistré',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          return Column(
                            children:
                                players.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final player = entry.value;
                                  final score = player['score'] as int? ?? 0;
                                  final playerName =
                                      player['playerName'] as String? ??
                                      'Joueur';
                                  final date = player['date'] as String? ?? '';
                                  final dateFormatted =
                                      player['dateFormatted'] as String? ?? '';

                                  // Formater la date
                                  String formattedDate = '';
                                  if (dateFormatted.isNotEmpty) {
                                    // Utiliser la date formatée si disponible
                                    formattedDate = dateFormatted;
                                  } else if (date.isNotEmpty) {
                                    try {
                                      final dateTime = DateTime.parse(date);
                                      // Format plus détaillé avec heure
                                      final now = DateTime.now();
                                      final difference = now.difference(
                                        dateTime,
                                      );

                                      if (difference.inDays == 0) {
                                        // Aujourd'hui
                                        formattedDate =
                                            'Aujourd\'hui à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                                      } else if (difference.inDays == 1) {
                                        // Hier
                                        formattedDate =
                                            'Hier à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                                      } else if (difference.inDays < 7) {
                                        // Cette semaine
                                        final days = [
                                          'Lun',
                                          'Mar',
                                          'Mer',
                                          'Jeu',
                                          'Ven',
                                          'Sam',
                                          'Dim',
                                        ];
                                        formattedDate =
                                            '${days[dateTime.weekday - 1]} ${dateTime.day}/${dateTime.month}';
                                      } else {
                                        // Plus ancien
                                        formattedDate =
                                            '${dateTime.day}/${dateTime.month}/${dateTime.year}';
                                      }
                                    } catch (e) {
                                      formattedDate = 'Date inconnue';
                                    }
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          index == 0
                                              ? Colors.amber.withOpacity(0.3)
                                              : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            index == 0
                                                ? Colors.amber
                                                : Colors.grey,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Position
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color:
                                                index == 0
                                                    ? Colors.amber
                                                    : Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color:
                                                    index == 0
                                                        ? Colors.black
                                                        : Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        // Informations du joueur
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                playerName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (formattedDate.isNotEmpty)
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.access_time,
                                                      color: Colors.grey,
                                                      size: 12,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      formattedDate,
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),

                                        // Score
                                        Text(
                                          '$score pts',
                                          style: TextStyle(
                                            color:
                                                index == 0
                                                    ? Colors.amber
                                                    : Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white,
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

  Widget _buildModeButton(
    String label,
    IconData icon,
    int delay,
    VoidCallback onTap,
  ) {
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
    WidgetsBinding.instance.removeObserver(this);
    _titleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final shopService = context.watch<ShopService>();
    final isDarkMode = settings.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/start_screen_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(GamePositions.homeScreenPadding),
            child: Column(
              children: [
                // AppBar avec boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bouton boutique avec coins
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '💰 ${shopService.currentCoins}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Boutons paramètres et à propos côte à côte
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _navigateToSettings,
                        ),
                        const SizedBox(
                          width: 4,
                        ), // Espace réduit entre les boutons
                        IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // Titre du jeu avec animation
                SlideTransition(
                  position: _titleOffsetAnimation,
                  child: ScaleTransition(
                    scale: _titleScaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent, width: 3),
                      ),
                      child: const Text(
                        'DINO RUNNER',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: GamePositions.homeScreenTitleSpacing),

                // Boutons de jeu avec animation
                if (_showContent) ...[
                  _buildModeButton(
                    'Mode Infini',
                    Icons.all_inclusive,
                    0,
                    () => _navigateToGame(GameMode.infinite),
                  ),
                  _buildModeButton(
                    'Course Contre la Montre',
                    Icons.timer,
                    100,
                    () => _navigateToGame(GameMode.timeAttack),
                  ),
                  _buildModeButton(
                    'Défi Quotidien',
                    Icons.calendar_today,
                    200,
                    () => _navigateToGame(GameMode.challenge),
                  ),
                  _buildModeButton(
                    'Mode Hardcore',
                    Icons.whatshot,
                    300,
                    () => _navigateToGame(GameMode.hardcore),
                  ),
                ],

                const SizedBox(height: GamePositions.homeScreenButtonSpacing),

                // Bouton boutique
                if (_showContent)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Boutique',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                      onPressed: _navigateToShop,
                    ),
                  ),

                // Bouton meilleur score avec Consumer pour mise à jour automatique
                if (_showBestScoreButton)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: child,
                        ),
                      );
                    },
                    child: Consumer<ScoreService>(
                      builder: (context, scoreService, child) {
                        return FutureBuilder<int>(
                          future: scoreService.getBestScore(GameMode.infinite),
                          builder: (context, snapshot) {
                            final bestScore = snapshot.data ?? _bestScore;
                            return TextButton.icon(
                              icon: const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                              ),
                              label: Text(
                                'Meilleur Score: $bestScore',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                // Recharger les scores avant d'afficher le dialog
                                _loadBestScore();
                                _showScoreHistoryDialog();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                const SizedBox(height: GamePositions.homeScreenButtonSpacing),

                // Bannière publicitaire en bas
                if (_showContent)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Consumer<AdService>(
                      builder: (context, adService, child) {
                        return AdBanner(
                          adService: adService,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
