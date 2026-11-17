// @date 2026-10-25
// @file settings_screen_golden_test.dart
// @brief Golden tests for ProfileScreen and SettingsScreen.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:mobile/features/profile/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helper.dart';

void main() {
  late SharedPreferences prefs;
  late TestAuthRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = TestAuthRepository();
  });

  const mobileConstraints = BoxConstraints.tightFor(width: 390, height: 844);

  group('Profile and Settings Screens Golden Tests', () {
    goldenTest(
      'renders ProfileScreen in dark and light modes',
      fileName: 'profile_screen',
      builder: () => GoldenTestGroup(
        scenarioConstraints: mobileConstraints,
        children: [
          GoldenTestScenario(
            name: 'Dark Theme',
            child: createTestableWidget(
              child: const ProfileScreen(),
              prefs: prefs,
              repo: repo,
              isDark: true,
            ),
          ),
          GoldenTestScenario(
            name: 'Light Theme',
            child: createTestableWidget(
              child: const ProfileScreen(),
              prefs: prefs,
              repo: repo,
              isDark: false,
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'renders SettingsScreen in dark and light modes',
      fileName: 'settings_screen',
      builder: () => GoldenTestGroup(
        scenarioConstraints: mobileConstraints,
        children: [
          GoldenTestScenario(
            name: 'Dark Theme',
            child: createTestableWidget(
              child: const SettingsScreen(),
              prefs: prefs,
              repo: repo,
              isDark: true,
            ),
          ),
          GoldenTestScenario(
            name: 'Light Theme',
            child: createTestableWidget(
              child: const SettingsScreen(),
              prefs: prefs,
              repo: repo,
              isDark: false,
            ),
          ),
        ],
      ),
    );
  });
}
