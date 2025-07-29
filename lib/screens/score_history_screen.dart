import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/score_service.dart';
import '../models/game_mode.dart';

class ScoreHistoryScreen extends StatefulWidget {
  final GameMode mode;

  const ScoreHistoryScreen({super.key, required this.mode});

  @override
  State<ScoreHistoryScreen> createState() => _ScoreHistoryScreenState();
}

class _ScoreHistoryScreenState extends State<ScoreHistoryScreen> {
  late ScoreService _scoreService;
  List<Map<String, dynamic>> _scores = [];
  bool _isLoading = true;
  int _bestScore = 0;
  int _totalGames = 0;
  double _averageScore = 0.0;

  @override
  void initState() {
    super.initState();
    _scoreService = context.read<ScoreService>();
    _loadScoreHistory();
  }

  Future<void> _loadScoreHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _scores = await _scoreService.getTopScores(widget.mode);

      if (_scores.isNotEmpty) {
        _bestScore = _scores.first['score'] as int;
        _totalGames = _scores.length;
        _averageScore =
            _scores.map((s) => s['score'] as int).reduce((a, b) => a + b) /
            _totalGames;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
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
        title: Text(
          '📊 Historique - ${_getModeDisplayName(widget.mode)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScoreHistory,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
              : _scores.isEmpty
              ? _buildEmptyState()
              : Column(
                children: [
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildScoreList()),
                ],
              ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Meilleur Score',
            _bestScore.toString(),
            Icons.emoji_events,
            Colors.amber,
          ),
          _buildStatItem(
            'Parties Jouées',
            _totalGames.toString(),
            Icons.games,
            Colors.green,
          ),
          _buildStatItem(
            'Moyenne',
            _averageScore.toStringAsFixed(0),
            Icons.trending_up,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScoreList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _scores.length,
      itemBuilder: (context, index) {
        final score = _scores[index];
        final isTopThree = index < 3;
        final rank = index + 1;

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
                  '$rank',
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
                    '${score['score']} points',
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Niveau: ${score['level']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDate(score['date']),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Aucun historique disponible',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jouez pour créer votre historique !',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Commencer à jouer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
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
      return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date inconnue';
    }
  }
}
