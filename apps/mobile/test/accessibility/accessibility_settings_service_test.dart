import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/accessibility/accessibility_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccessibilitySettingsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads default values', () async {
      final service = AccessibilitySettingsService();
      await service.resetToDefaults();
      await service.init();

      expect(service.textScale, 1.0);
      expect(service.highContrast, false);
      expect(service.reducedMotion, false);
      expect(service.simplifiedInterface, false);
      expect(service.captionsEnabled, true);
      expect(service.hapticIntensity, HapticIntensity.medium);
      expect(service.readingSpeed, 1.0);
      expect(service.dyslexiaProfile, false);
      expect(service.reducedInterruptions, false);
      expect(service.appLanguage, AppLanguage.french);
    });

    test('persists updated values', () async {
      final service = AccessibilitySettingsService();
      await service.init();

      await service.setTextScale(1.8);
      await service.setHighContrast(true);
      await service.setReducedMotion(true);
      await service.setSimplifiedInterface(true);
      await service.setCaptionsEnabled(false);
      await service.setHapticIntensity(HapticIntensity.strong);
      await service.setReadingSpeed(1.5);
      await service.setDyslexiaProfile(true);
      await service.setReducedInterruptions(true);
      await service.setAppLanguage(AppLanguage.english);

      final reloaded = AccessibilitySettingsService();
      await reloaded.init();

      expect(reloaded.textScale, 1.8);
      expect(reloaded.highContrast, true);
      expect(reloaded.reducedMotion, true);
      expect(reloaded.simplifiedInterface, true);
      expect(reloaded.captionsEnabled, false);
      expect(reloaded.hapticIntensity, HapticIntensity.strong);
      expect(reloaded.readingSpeed, 1.5);
      expect(reloaded.dyslexiaProfile, true);
      expect(reloaded.reducedInterruptions, true);
      expect(reloaded.appLanguage, AppLanguage.english);
    });
  });
}
