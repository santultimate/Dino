import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static final AudioPlayer _backgroundPlayer = AudioPlayer();
  static final Map<String, AudioPlayer> _effectPlayers = {};
  static final AudioCache _audioCache = AudioCache(prefix: 'assets/sounds/');

  static bool _isMusicOn = true;
  static bool _areEffectsOn = true;
  static double _musicVolume = 0.5;
  static double _effectsVolume = 0.7;
  static bool _isInitialized = false;

  /// Initialise le gestionnaire audio (à appeler au lancement de l'app)
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _audioCache.loadAll([
      'background_music.mp3',
      'jump.wav',
      'hit.wav',
      'score.wav',
      // Ajoutez tous vos fichiers audio ici
    ]);
    
    _backgroundPlayer.onPlayerComplete.listen((_) {
      if (_isMusicOn) _backgroundPlayer.resume();
    });

    _isInitialized = true;
    if (kDebugMode) {
      print('SoundManager initialized');
    }
  }

  /// Configure le volume de la musique (0.0 à 1.0)
  static Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _backgroundPlayer.setVolume(_musicVolume);
  }

  /// Configure le volume des effets (0.0 à 1.0)
  static void setEffectsVolume(double volume) {
    _effectsVolume = volume.clamp(0.0, 1.0);
  }

  /// Active/désactive la musique
  static Future<void> toggleMusic(bool isOn) async {
    _isMusicOn = isOn;
    if (_isMusicOn) {
      await playBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }
  }

  /// Active/désactive les effets sonores
  static void toggleEffects(bool isOn) {
    _areEffectsOn = isOn;
  }

  /// Joue la musique de fond en boucle
  static Future<void> playBackgroundMusic() async {
    if (!_isMusicOn || !_isInitialized) return;

    try {
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.setVolume(_musicVolume);
      await _backgroundPlayer.play(AssetSource('sounds/background_music.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing background music: $e');
      }
    }
  }

  /// Stoppe la musique de fond
  static Future<void> stopBackgroundMusic() async {
    await _backgroundPlayer.stop();
  }

  /// Joue un effet sonore
  static Future<void> playEffect(String fileName) async {
    if (!_areEffectsOn || !_isInitialized) return;

    try {
      // Arrête le son précédent s'il est encore en cours
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
      if (kDebugMode) {
        print('Error playing sound effect $fileName: $e');
      }
    }
  }

  /// Libère toutes les ressources audio
  static Future<void> dispose() async {
    await _backgroundPlayer.dispose();
    for (final player in _effectPlayers.values) {
      await player.dispose();
    }
    _effectPlayers.clear();
    _isInitialized = false;
  }
}