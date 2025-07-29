import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _effectPlayers = {};
  final AudioCache _audioCache = AudioCache(prefix: 'assets/sounds/');

  bool _isInitialized = false;
  bool isMusicOn = true;
  bool areEffectsOn = true;
  double musicVolume = 0.5;
  double effectsVolume = 0.7;

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
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.setVolume(musicVolume);

      _isInitialized = true;
      if (kDebugMode) print('✅ SoundManager initialized');
    } catch (e) {
      if (kDebugMode) print('❌ Error initializing SoundManager: $e');
    }
  }

  Future<void> playBackgroundMusic() async {
    if (!isMusicOn || !_isInitialized) return;
    try {
      await _backgroundPlayer.play(AssetSource('sounds/background.mp3'));
      if (kDebugMode) print('🎵 Background music started');
    } catch (e) {
      if (kDebugMode) print('❌ Error playing background music: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await _backgroundPlayer.pause();
      if (kDebugMode) print('⏸️ Background music paused');
    } catch (e) {
      if (kDebugMode) print('❌ Error pausing background music: $e');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (isMusicOn && _isInitialized) {
      try {
        await _backgroundPlayer.resume();
        if (kDebugMode) print('▶️ Background music resumed');
      } catch (e) {
        if (kDebugMode) print('❌ Error resuming background music: $e');
      }
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer.stop();
      if (kDebugMode) print('⏹️ Background music stopped');
    } catch (e) {
      if (kDebugMode) print('❌ Error stopping background music: $e');
    }
  }

  Future<void> setMusicVolume(double volume) async {
    musicVolume = volume.clamp(0.0, 1.0);
    try {
      await _backgroundPlayer.setVolume(musicVolume);
    } catch (e) {
      if (kDebugMode) print('❌ Error setting music volume: $e');
    }
  }

  void setEffectsVolume(double volume) {
    effectsVolume = volume.clamp(0.0, 1.0);
  }

  Future<void> toggleMusic(bool isOn) async {
    isMusicOn = isOn;
    if (isOn) {
      await playBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }
  }

  void toggleEffects(bool isOn) {
    areEffectsOn = isOn;
  }

  Future<void> playEffect(String fileName) async {
    if (!areEffectsOn || !_isInitialized) return;

    try {
      // Arrêter l'effet précédent s'il existe
      _effectPlayers[fileName]?.stop();

      final player = AudioPlayer();
      _effectPlayers[fileName] = player;

      await player.setVolume(effectsVolume);
      await player.play(AssetSource('sounds/$fileName'));

      player.onPlayerComplete.listen((_) {
        player.dispose();
        _effectPlayers.remove(fileName);
      });
    } catch (e) {
      if (kDebugMode) print('❌ Error playing effect $fileName: $e');
    }
  }

  Future<void> playJumpSound() async {
    await playEffect('jump.mp3');
  }

  Future<void> playCrashSound() async {
    await playEffect('hit.mp3');
  }

  Future<void> playGameOverSound() async {
    await playEffect('gameover.mp3');
  }

  Future<void> playScoreSound() async {
    await playEffect('coin.mp3');
  }

  Future<void> playCoinSound() async {
    await playEffect('coin.mp3');
  }

  Future<void> playHitSound() async {
    await playEffect('hit.mp3');
  }

  Future<void> dispose() async {
    try {
      await _backgroundPlayer.dispose();
      for (var player in _effectPlayers.values) {
        await player.dispose();
      }
      _effectPlayers.clear();
      _isInitialized = false;
      if (kDebugMode) print('🔇 SoundManager disposed');
    } catch (e) {
      if (kDebugMode) print('❌ Error disposing SoundManager: $e');
    }
  }
}
