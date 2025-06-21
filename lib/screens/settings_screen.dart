// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settingsService;
  late SoundService _soundService;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
              _buildSectionHeader('Apparence'),
              SwitchListTile(
                title: const Text('Mode sombre'),
                subtitle: const Text('Activer le thème sombre'),
                value: settings.isDarkMode,
                secondary: const Icon(Icons.dark_mode),
                onChanged: _handleDarkModeChange,
              ),
              SwitchListTile(
                title: const Text('Animations'),
                subtitle: const Text('Activer les effets animés'),
                value: settings.animationsEnabled,
                secondary: const Icon(Icons.animation),
                onChanged: settings.setAnimationsEnabled,
              ),
              const Divider(height: 32),

              _buildSectionHeader('Audio'),
              SwitchListTile(
                title: const Text('Musique'),
                subtitle: const Text('Activer la musique de fond'),
                value: sound.musicEnabled,
                secondary: const Icon(Icons.music_note),
                onChanged: sound.setMusicEnabled,
              ),
              SwitchListTile(
                title: const Text('Effets sonores'),
                subtitle: const Text('Activer les sons du jeu'),
                value: sound.soundEffectsEnabled,
                secondary: const Icon(Icons.volume_up),
                onChanged: sound.setSoundEffectsEnabled,
              ),
              ListTile(
                title: const Text('Volume musique'),
                leading: const Icon(Icons.volume_down),
                subtitle: Slider(
                  value: sound.musicVolume,
                  onChanged: sound.setMusicVolume,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: (sound.musicVolume * 100).round().toString(),
                ),
              ),
              ListTile(
                title: const Text('Volume effets'),
                leading: const Icon(Icons.volume_up),
                subtitle: Slider(
                  value: sound.soundEffectsVolume,
                  onChanged: sound.setSoundEffectsVolume,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: (sound.soundEffectsVolume * 100).round().toString(),
                ),
              ),
              const Divider(height: 32),

              _buildSectionHeader('Jeu'),
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Difficulté'),
                trailing: DropdownButton<String>(
                  value: settings.difficulty,
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Facile')),
                    DropdownMenuItem(value: 'medium', child: Text('Moyen')),
                    DropdownMenuItem(value: 'hard', child: Text('Difficile')),
                  ],
                  onChanged: (String? value) {
                  if (value != null) {
                      settings.setDifficulty(value);
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt, color: Colors.red),
                title: const Text(
                  'Réinitialiser la progression',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _isResetting ? null : () => _showResetConfirmation(context),
                trailing: _isResetting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
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
                child: const Text(
                  'Réinitialiser',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

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
