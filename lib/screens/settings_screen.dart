import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _settingsService;
  late final SoundService _soundService;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _settingsService = context.read<SettingsService>();
    _soundService = context.read<SoundService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer2<SettingsService, SoundService>(
        builder: (context, settings, sound, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance Section
              _buildSectionHeader('Apparence'),
              SettingsTile.switchTile(
                title: 'Mode sombre',
                subtitle: 'Activer le thème sombre',
                value: settings.isDarkMode,
                icon: Icons.dark_mode,
                onChanged: _handleDarkModeChange,
              ),
              SettingsTile.switchTile(
                title: 'Animations',
                subtitle: 'Activer les effets animés',
                value: settings.animationsEnabled,
                icon: Icons.animation,
                onChanged: settings.setAnimationsEnabled,
              ),
              const Divider(height: 24),
              
              // Audio Section
              _buildSectionHeader('Audio'),
              SettingsTile.switchTile(
                title: 'Musique',
                subtitle: 'Activer la musique de fond',
                value: sound.musicEnabled,
                icon: Icons.music_note,
                onChanged: sound.setMusicEnabled,
              ),
              SettingsTile.switchTile(
                title: 'Effets sonores',
                subtitle: 'Activer les sons du jeu',
                value: sound.soundEffectsEnabled,
                icon: Icons.volume_up,
                onChanged: sound.setSoundEffectsEnabled,
              ),
              SettingsTile.sliderTile(
                title: 'Volume musique',
                icon: Icons.volume_down,
                value: sound.musicVolume,
                onChanged: sound.setMusicVolume,
              ),
              SettingsTile.sliderTile(
                title: 'Volume effets',
                icon: Icons.volume_up,
                value: sound.soundEffectsVolume,
                onChanged: sound.setSoundEffectsVolume,
              ),
              const Divider(height: 24),
              
              // Game Section
              _buildSectionHeader('Jeu'),
              SettingsTile.dropdownTile<String>(
                title: 'Difficulté',
                icon: Icons.speed,
                value: settings.difficulty,
                items: const [
                  DropdownMenuItem(value: 'easy', child: Text('Facile')),
                  DropdownMenuItem(value: 'medium', child: Text('Moyen')),
                  DropdownMenuItem(value: 'hard', child: Text('Difficile')),
                ],
                onChanged: settings.setDifficulty,
              ),
              SettingsTile.actionTile(
                title: 'Réinitialiser la progression',
                icon: Icons.restart_alt,
                isDestructive: true,
                isLoading: _isResetting,
                onTap: () => _showResetConfirmation(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _handleDarkModeChange(bool value) async {
    try {
      await _settingsService.setDarkMode(value);
      // Optional: Add theme reload logic here if needed
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la modification du thème')),
        );
      }
    }
  }

  Future<void> _showResetConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la réinitialisation'),
        content: const Text('Voulez-vous vraiment réinitialiser toutes vos données de jeu ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réinitialiser', 
              style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed && mounted) {
      setState(() => _isResetting = true);
      try {
        await _settingsService.resetAllProgress();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Progression réinitialisée')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de la réinitialisation')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isResetting = false);
        }
      }
    }
  }
}