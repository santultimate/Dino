import 'package:flutter/material.dart';
import '../models/power_up_type.dart';

class GameOverDialog extends StatefulWidget {
  final int score;
  final int? highScore;
  final String mode;
  final int level;
  final VoidCallback onReplay;
  final VoidCallback onMenu;
  final Function(String) onSaveScore;
  final bool showNameInput;
  final int bestScore;
  final List<PowerUpType>? powerUpsUsed;

  const GameOverDialog({
    super.key,
    required this.score,
    this.highScore,
    required this.mode,
    required this.level,
    required this.onReplay,
    required this.onMenu,
    required this.onSaveScore,
    this.showNameInput = true,
    required this.bestScore,
    this.powerUpsUsed,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  final TextEditingController _nameController = TextEditingController();
  bool _scoreSaved = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleSaveScore() {
    if (_scoreSaved) return;

    final name = _nameController.text.trim().isEmpty
        ? "Anonyme"
        : _nameController.text.trim();

    widget.onSaveScore(name);
    setState(() => _scoreSaved = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Score sauvegardé!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = widget.highScore != null && widget.score > widget.highScore!;
    final isNewBestScore = widget.score >= widget.bestScore;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.greenAccent, width: 2),
          ),
          title: Column(
            children: [
              const Text(
                '🎮 Game Over',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Mode: ${widget.mode} • Niveau ${widget.level}',
                style: TextStyle(
                  color: Colors.greenAccent.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Score: ${widget.score}',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Meilleur perso: ${widget.highScore ?? '-'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  'Meilleur global: ${widget.bestScore}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                if (isNewHighScore || isNewBestScore) ...[
                  const SizedBox(height: 8),
                  if (isNewHighScore)
                    _buildRecordIndicator('NOUVEAU RECORD PERSO!', Colors.amber),
                  if (isNewBestScore)
                    _buildRecordIndicator('NOUVEAU RECORD GLOBAL!', Colors.greenAccent),
                ],
                if (widget.powerUpsUsed != null && widget.powerUpsUsed!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Power-Ups Utilisés:',
                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.powerUpsUsed!
                        .map((powerUp) => Chip(
                              label: Text(
                                powerUp.displayName,
                                style: const TextStyle(color: Colors.black),
                              ),
                              avatar: Image.asset(
                                powerUp.iconPath,
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                              ),
                              backgroundColor: Colors.greenAccent,
                            ))
                        .toList(),
                  ),
                ],
                if (widget.showNameInput && !_scoreSaved) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    maxLength: 20,
                    decoration: InputDecoration(
                      hintText: "Entrez votre nom",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _handleSaveScore,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text("SAUVEGARDER"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                if (_scoreSaved)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Score enregistré',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: [
            TextButton.icon(
              onPressed: widget.onReplay,
              icon: const Icon(Icons.replay),
              label: const Text('REJOUER'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.greenAccent,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: widget.onMenu,
              icon: const Icon(Icons.menu),
              label: const Text('MENU'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordIndicator(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}