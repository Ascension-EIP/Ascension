import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HapticIntensity { off, light, medium, strong }

enum AppLanguage { french, english }

class AccessibilitySettingsService extends ChangeNotifier {
  AccessibilitySettingsService._internal();
  static final AccessibilitySettingsService _instance =
      AccessibilitySettingsService._internal();
  factory AccessibilitySettingsService() => _instance;

  static const String _textScaleKey = 'a11y_text_scale';
  static const String _highContrastKey = 'a11y_high_contrast';
  static const String _reducedMotionKey = 'a11y_reduced_motion';
  static const String _simplifiedInterfaceKey = 'a11y_simplified_interface';
  static const String _captionsEnabledKey = 'a11y_captions_enabled';
  static const String _hapticIntensityKey = 'a11y_haptic_intensity';
  static const String _readingSpeedKey = 'a11y_reading_speed';
  static const String _dyslexiaProfileKey = 'a11y_dyslexia_profile';
  static const String _reducedInterruptionsKey = 'a11y_reduced_interruptions';
  static const String _appLanguageKey = 'a11y_app_language';

  static const double minTextScale = 0.9;
  static const double maxTextScale = 2.0;
  static const double minReadingSpeed = 0.75;
  static const double maxReadingSpeed = 2.0;

  bool _ready = false;
  double _textScale = 1.0;
  bool _highContrast = false;
  bool _reducedMotion = false;
  bool _simplifiedInterface = false;
  bool _captionsEnabled = true;
  HapticIntensity _hapticIntensity = HapticIntensity.medium;
  double _readingSpeed = 1.0;
  bool _dyslexiaProfile = false;
  bool _reducedInterruptions = false;
  AppLanguage _appLanguage = AppLanguage.french;

  bool get isReady => _ready;
  double get textScale => _textScale;
  bool get highContrast => _highContrast;
  bool get reducedMotion => _reducedMotion;
  bool get simplifiedInterface => _simplifiedInterface;
  bool get captionsEnabled => _captionsEnabled;
  HapticIntensity get hapticIntensity => _hapticIntensity;
  double get readingSpeed => _readingSpeed;
  bool get dyslexiaProfile => _dyslexiaProfile;
  bool get reducedInterruptions => _reducedInterruptions;
  AppLanguage get appLanguage => _appLanguage;
  Locale get locale => switch (_appLanguage) {
    AppLanguage.french => const Locale('fr'),
    AppLanguage.english => const Locale('en'),
  };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _textScale = (prefs.getDouble(_textScaleKey) ?? 1.0).clamp(
      minTextScale,
      maxTextScale,
    );
    _highContrast = prefs.getBool(_highContrastKey) ?? false;
    _reducedMotion = prefs.getBool(_reducedMotionKey) ?? false;
    _simplifiedInterface = prefs.getBool(_simplifiedInterfaceKey) ?? false;
    _captionsEnabled = prefs.getBool(_captionsEnabledKey) ?? true;
    _hapticIntensity = HapticIntensity.values.byName(
      prefs.getString(_hapticIntensityKey) ?? HapticIntensity.medium.name,
    );
    _readingSpeed = (prefs.getDouble(_readingSpeedKey) ?? 1.0).clamp(
      minReadingSpeed,
      maxReadingSpeed,
    );
    _dyslexiaProfile = prefs.getBool(_dyslexiaProfileKey) ?? false;
    _reducedInterruptions = prefs.getBool(_reducedInterruptionsKey) ?? false;
    _appLanguage = AppLanguage.values.byName(
      prefs.getString(_appLanguageKey) ?? AppLanguage.french.name,
    );
    _ready = true;
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    _textScale = value.clamp(minTextScale, maxTextScale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, _textScale);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
    notifyListeners();
  }

  Future<void> setReducedMotion(bool value) async {
    _reducedMotion = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reducedMotionKey, value);
    notifyListeners();
  }

  Future<void> setSimplifiedInterface(bool value) async {
    _simplifiedInterface = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simplifiedInterfaceKey, value);
    notifyListeners();
  }

  Future<void> setCaptionsEnabled(bool value) async {
    _captionsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_captionsEnabledKey, value);
    notifyListeners();
  }

  Future<void> setHapticIntensity(HapticIntensity value) async {
    _hapticIntensity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hapticIntensityKey, value.name);
    notifyListeners();
  }

  Future<void> setReadingSpeed(double value) async {
    _readingSpeed = value.clamp(minReadingSpeed, maxReadingSpeed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_readingSpeedKey, _readingSpeed);
    notifyListeners();
  }

  Future<void> setDyslexiaProfile(bool value) async {
    _dyslexiaProfile = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dyslexiaProfileKey, value);
    notifyListeners();
  }

  Future<void> setReducedInterruptions(bool value) async {
    _reducedInterruptions = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reducedInterruptionsKey, value);
    notifyListeners();
  }

  Future<void> setAppLanguage(AppLanguage value) async {
    _appLanguage = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appLanguageKey, value.name);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_textScaleKey);
    await prefs.remove(_highContrastKey);
    await prefs.remove(_reducedMotionKey);
    await prefs.remove(_simplifiedInterfaceKey);
    await prefs.remove(_captionsEnabledKey);
    await prefs.remove(_hapticIntensityKey);
    await prefs.remove(_readingSpeedKey);
    await prefs.remove(_dyslexiaProfileKey);
    await prefs.remove(_reducedInterruptionsKey);
    await prefs.remove(_appLanguageKey);

    _textScale = 1.0;
    _highContrast = false;
    _reducedMotion = false;
    _simplifiedInterface = false;
    _captionsEnabled = true;
    _hapticIntensity = HapticIntensity.medium;
    _readingSpeed = 1.0;
    _dyslexiaProfile = false;
    _reducedInterruptions = false;
    _appLanguage = AppLanguage.french;

    notifyListeners();
  }
}
