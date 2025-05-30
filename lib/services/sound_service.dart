import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isMuted = false;

  Future<void> playBackgroundMusic() async {
    if (_isMuted) return;
    await _bgmPlayer.play(AssetSource('sounds/bgm.mp3'));
    await _bgmPlayer.setVolume(0.5);
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> pauseBackgroundMusic() async {
    await _bgmPlayer.pause();
  }

  Future<void> resumeBackgroundMusic() async {
    if (_isMuted) return;
    await _bgmPlayer.resume();
  }

  Future<void> stopBackgroundMusic() async {
    await _bgmPlayer.stop();
  }

  Future<void> playSoundEffect(String soundFile) async {
    if (_isMuted) return;
    await _sfxPlayer.play(AssetSource('sounds/$soundFile'));
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgmPlayer.setVolume(0);
      _sfxPlayer.setVolume(0);
    } else {
      _bgmPlayer.setVolume(0.5);
      _sfxPlayer.setVolume(1.0);
    }
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}