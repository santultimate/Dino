import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/score_service.dart';
import '../models/game_mode.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late ScoreService _scoreService;
  late TabController _tabController;
  final Map<GameMode, List<Map<String, dynamic>>> _scores = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scoreService = context.read<ScoreService>();
    _tabController = TabController(length: GameMode.values.length, vsync: this);
    _loadScores();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadScores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (final mode in GameMode.values) {
        _scores[mode] = await _scoreService.getTopScores(mode);
      }
    } catch (e) {
      debugPrint('Error loading scores: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text(
          '🏆 Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScores,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs:
                  GameMode.values.map((mode) {
                    return Tab(
                      child: Text(
                        _getModeDisplayName(mode),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    )
                    : TabBarView(
                      controller: _tabController,
                      children:
                          GameMode.values.map((mode) {
                            return _buildModeLeaderboard(mode);
                          }).toList(),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeLeaderboard(GameMode mode) {
    final scores = _scores[mode] ?? [];

    if (scores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun score enregistré',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jouez pour établir des records !',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: scores.length,
      itemBuilder: (context, index) {
        final score = scores[index];
        final isTopThree = index < 3;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isTopThree
                      ? _getTopThreeColors(index)
                      : [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isTopThree
                      ? _getTopThreeBorderColor(index)
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isTopThree
                        ? _getTopThreeBorderColor(index)
                        : Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isTopThree ? 18 : 16,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Score: ${score['score']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (isTopThree) ...[
                  Icon(
                    _getTopThreeIcon(index),
                    color: _getTopThreeBorderColor(index),
                    size: 20,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              'Niveau: ${score['level']} • ${_formatDate(score['date'])}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Niv. ${score['level']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getTopThreeColors(int index) {
    switch (index) {
      case 0: // 1er
        return [Colors.amber.withOpacity(0.3), Colors.amber.withOpacity(0.1)];
      case 1: // 2ème
        return [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.1)];
      case 2: // 3ème
        return [Colors.orange.withOpacity(0.3), Colors.orange.withOpacity(0.1)];
      default:
        return [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)];
    }
  }

  Color _getTopThreeBorderColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getTopThreeIcon(int index) {
    switch (index) {
      case 0:
        return Icons.emoji_events;
      case 1:
        return Icons.military_tech;
      case 2:
        return Icons.star;
      default:
        return Icons.star_border;
    }
  }

  String _getModeDisplayName(GameMode mode) {
    switch (mode) {
      case GameMode.infinite:
        return 'Infini';
      case GameMode.timeAttack:
        return 'Contre-la-montre';
      case GameMode.challenge:
        return 'Défi quotidien';
      case GameMode.hardcore:
        return 'Hardcore';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Date inconnue';
    }
  }
}
