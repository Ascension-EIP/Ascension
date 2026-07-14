import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService extends ChangeNotifier {
  AudioService._internal();
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  static const String _prefKey = 'music_enabled';
  static const String _assetPath = 'assets/audio/ascension.mp3';

  final AudioPlayer _player = AudioPlayer();
  bool _musicEnabled = false;

  bool get musicEnabled => _musicEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _musicEnabled = prefs.getBool(_prefKey) ?? false;

    await _player.setAsset(_assetPath);
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(0.4);

    if (_musicEnabled) {
      _player.play(); // intentionnellement non-awaité
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);

    if (enabled) {
      await _player.play();
    } else {
      await _player.pause();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
