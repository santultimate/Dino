import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _gradientAnimation;
  Future<List<Map<String, dynamic>>>? _scoresFuture;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadScores();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _gradientAnimation = ColorTween(
      begin: Colors.black,
      end: Colors.green.shade900,
    ).animate(_controller);
  }

  void _loadScores() {
    _scoresFuture = _fetchTopScores();
  }

  Future<List<Map<String, dynamic>>> _fetchTopScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresData = prefs.getStringList('top_scores') ?? [];

    return scoresData
        .map((jsonString) => _parseScore(jsonString))
        .whereType<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) => b['score'].compareTo(a['score']))
      ..take(5).toList();
  }

  Map<String, dynamic>? _parseScore(String jsonString) {
    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      return {
        'score': decoded['score'] as int,
        'mode': decoded['mode'] as String,
        'date': decoded['date'] as String,
      };
    } catch (e) {
      debugPrint('Error parsing score: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _gradientAnimation.value,
          appBar: _buildAppBar(),
          body: _buildBody(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      title: const Text(
        '🏆 Classement',
        style: TextStyle(color: Colors.greenAccent),
      ),
      iconTheme: const IconThemeData(color: Colors.greenAccent),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _scoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          return _buildLeaderboard(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Aucun score enregistré.',
        style: TextStyle(color: Colors.white70, fontSize: 18),
      ),
    );
  }

  Widget _buildLeaderboard(List<Map<String, dynamic>> scores) {
    return ListView.builder(
      itemCount: scores.length,
      itemBuilder: (context, index) => _buildScoreItem(index, scores[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }

  Widget _buildScoreItem(int index, Map<String, dynamic> score) {
    final rankColor = _getRankColor(index);
    final icon = _getRankIcon(index);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            rankColor.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rankColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: rankColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: rankColor.withOpacity(0.3),
            child: Icon(icon, color: rankColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${score['score']} pts',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${score['mode']} • ${_formatDate(score['date'])}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      return DateFormat('dd MMM yyyy - HH:mm').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  Color _getRankColor(int index) {
    const colors = [
      Colors.amberAccent,    // Or
      Colors.grey,          // Argent
      Colors.brown,         // Bronze
      Colors.greenAccent,   // Default
    ];
    return colors[index.clamp(0, colors.length - 1)];
  }

  IconData _getRankIcon(int index) {
    const icons = [
      Icons.emoji_events,      // 1st
      Icons.military_tech,     // 2nd
      Icons.workspace_premium, // 3rd
      Icons.star,              // Others
    ];
    return icons[index.clamp(0, icons.length - 1)];
  }
}