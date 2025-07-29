// lib/services/sound_service.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/sound_type.dart';

class SoundService with ChangeNotifier {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _bgPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _effectPlayers = {};
  final AudioCache _audioCache = AudioCache(prefix: 'assets/sounds/');

  bool _isInitialized = false;
  bool _isMusicOn = true;
  bool _areEffectsOn = true;
  double _musicVolume = 0.5;
  double _effectsVolume = 0.7;

  // Getters for settings screen
  bool get musicEnabled => _isMusicOn;
  bool get soundEffectsEnabled => _areEffectsOn;
  double get musicVolume => _musicVolume;
  double get soundEffectsVolume => _effectsVolume;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _audioCache.loadAll([
        'background.mp3',
        'jump.mp3',
        'hit.mp3',
        'coin.mp3',
        'gameover.mp3',
      ]);

      // Configuration de la musique de fond en loop
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(_musicVolume);

      _isInitialized = true;
      if (kDebugMode) print('🎵 SoundService initialized');

      // Ne pas démarrer automatiquement la musique de fond
      // Elle sera démarrée uniquement quand on entre en mode jeu
    } catch (e) {
      if (kDebugMode) print('⚠️ Error initializing SoundService: $e');
    }
  }

  Future<void> playBackgroundMusic() async {
    if (!_isInitialized || !_isMusicOn) return;

    try {
      // Vérifier si la musique est déjà en cours de lecture
      final state = _bgPlayer.state;
      if (state == PlayerState.playing) {
        if (kDebugMode) print('🎵 Background music already playing');
        return; // Éviter les appels multiples
      }

      await _bgPlayer.play(AssetSource('sounds/background.mp3'));
      if (kDebugMode) print('🎵 Background music started');
    } catch (e) {
      if (kDebugMode) print('⚠️ Could not play background music: $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      final state = _bgPlayer.state;
      if (state == PlayerState.stopped) {
        return; // Pas de log si déjà arrêté
      }

      await _bgPlayer.stop();
      if (kDebugMode) print('⏹️ Background music stopped');
    } catch (e) {
      if (kDebugMode) print('⚠️ Error stopping background music: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      final state = _bgPlayer.state;
      if (state == PlayerState.paused || state == PlayerState.stopped) {
        return; // Pas de log si déjà en pause
      }

      await _bgPlayer.pause();
      if (kDebugMode) print('⏸️ Background music paused');
    } catch (e) {
      if (kDebugMode) print('⚠️ Error pausing background music: $e');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (!_isMusicOn) return;

    try {
      // Vérifier si la musique est déjà en cours de lecture
      final state = _bgPlayer.state;
      if (state == PlayerState.playing) {
        if (kDebugMode) print('🎵 Background music already playing');
        return; // Éviter les appels multiples
      }

      if (state == PlayerState.paused) {
        await _bgPlayer.resume();
        if (kDebugMode) print('▶️ Background music resumed');
      } else {
        // Si arrêté, redémarrer
        await playBackgroundMusic();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Error resuming background music: $e');
    }
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    try {
      await _bgPlayer.setVolume(_musicVolume);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('⚠️ Error setting music volume: $e');
    }
  }

  Future<void> setSoundEffectsVolume(double volume) async {
    _effectsVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicOn = enabled;
    if (enabled) {
      await playBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }
    notifyListeners();
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    _areEffectsOn = enabled;
    notifyListeners();
  }

  Future<void> toggleMusic(bool isOn) async {
    await setMusicEnabled(isOn);
  }

  void toggleEffects(bool isOn) {
    setSoundEffectsEnabled(isOn);
  }

  Future<void> playSoundEffect(SoundType type) async {
    if (!_isInitialized || !_areEffectsOn) return;

    String fileName;
    switch (type) {
      case SoundType.jump:
        fileName = 'jump.mp3';
        break;
      case SoundType.collision:
        fileName = 'hit.mp3';
        break;
      case SoundType.powerUp:
        fileName = 'coin.mp3';
        break;
      case SoundType.coin:
        fileName = 'coin.mp3';
        break;
      case SoundType.gameover:
        fileName = 'gameover.mp3';
        break;
    }

    await playEffect(fileName);
  }

  Future<void> playEffect(String fileName) async {
    try {
      // Arrêter l'effet précédent s'il existe
      _effectPlayers[fileName]?.stop();

      final player = AudioPlayer();
      _effectPlayers[fileName] = player;

      await player.setVolume(_effectsVolume);
      await player.play(AssetSource('sounds/$fileName'));

      player.onPlayerComplete.listen((_) {
        player.dispose();
        _effectPlayers.remove(fileName);
      });
    } catch (e) {
      if (kDebugMode) print('⚠️ Error playing effect $fileName: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _bgPlayer.dispose();
      for (final player in _effectPlayers.values) {
        await player.dispose();
      }
      _effectPlayers.clear();
      _isInitialized = false;
      if (kDebugMode) print('🔇 SoundService disposed');
    } catch (e) {
      if (kDebugMode) print('⚠️ Error disposing SoundService: $e');
    }
  }
}
