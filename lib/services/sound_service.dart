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

    await _audioCache.loadAll([
      'background.mp3',
      'jump.mp3',
      'hit.mp3',
      'coin.mp3',
      'gameover.mp3',
    ]);

    _bgPlayer.onPlayerComplete.listen((_) {
      if (_isMusicOn) _bgPlayer.resume();
    });

    _isInitialized = true;
    if (kDebugMode) print('🎵 SoundService initialized');
  }

  Future<void> playBackgroundMusic() async {
    if (!_isInitialized || !_isMusicOn) return;
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgPlayer.setVolume(_musicVolume);
    await _bgPlayer.play(AssetSource('sounds/background.mp3'));
  }

  Future<void> stopBackgroundMusic() async {
    await _bgPlayer.stop();
  }

  Future<void> pauseBackgroundMusic() async {
    await _bgPlayer.pause();
  }

  Future<void> resumeBackgroundMusic() async {
    if (_isMusicOn) {
      await _bgPlayer.resume();
    }
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _bgPlayer.setVolume(_musicVolume);
    notifyListeners();
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
    final player = AudioPlayer();
    _effectPlayers[fileName] = player;
    await player.setVolume(_effectsVolume);
    final file = await _audioCache.loadAsFile(fileName);
    await player.play(DeviceFileSource(file.path));
  }

  Future<void> dispose() async {
    await _bgPlayer.dispose();
    for (final player in _effectPlayers.values) {
      await player.dispose();
    }
    _effectPlayers.clear();
    _isInitialized = false;
  }
}
