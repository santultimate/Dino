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

    await _audioCache.loadAll([
      'background_music.mp3',
      'jump.wav',
      'hit.wav',
      'score.wav',
      'coin.mp3',
      'gameover.mp3',
    ]);

    _backgroundPlayer.onPlayerComplete.listen((_) {
      if (isMusicOn) _backgroundPlayer.resume();
    });

    _isInitialized = true;

    if (kDebugMode) print('✅ SoundManager initialized');
  }

  Future<void> playBackgroundMusic() async {
    if (!isMusicOn || !_isInitialized) return;
    try {
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.setVolume(musicVolume);
      await _backgroundPlayer.play(AssetSource('sounds/background_music.mp3'));
    } catch (e) {
      if (kDebugMode) print('❌ Error playing music: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    await _backgroundPlayer.pause();
  }

  Future<void> resumeBackgroundMusic() async {
    if (isMusicOn && _isInitialized) {
      await _backgroundPlayer.resume();
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _backgroundPlayer.stop();
  }

  Future<void> setMusicVolume(double volume) async {
    musicVolume = volume.clamp(0.0, 1.0);
    await _backgroundPlayer.setVolume(musicVolume);
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
    await playEffect('jump.wav');
  }

  Future<void> playCrashSound() async {
    await playEffect('hit.wav');
  }

  Future<void> playGameOverSound() async {
    await playEffect('gameover.mp3');
  }

  Future<void> playScoreSound() async {
    await playEffect('score.wav');
  }

  Future<void> playCoinSound() async {
    await playEffect('coin.mp3');
  }

  Future<void> dispose() async {
    await _backgroundPlayer.dispose();
    for (var player in _effectPlayers.values) {
      await player.dispose();
    }
    _effectPlayers.clear();
    _isInitialized = false;
  }
}
