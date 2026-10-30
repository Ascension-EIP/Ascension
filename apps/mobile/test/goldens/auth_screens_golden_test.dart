// @date 2026-10-30
// @file auth_screens_golden_test.dart
// @brief Golden tests for WelcomeScreen, LoginScreen and RegisterScreen.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:mobile/features/auth/presentation/screens/welcome_screen.dart';
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

  group('Auth Screens Golden Tests', () {
    goldenTest(
      'renders WelcomeScreen in dark and light modes',
      fileName: 'welcome_screen',
      builder: () => GoldenTestGroup(
        scenarioConstraints: mobileConstraints,
        children: [
          GoldenTestScenario(
            name: 'Dark Theme',
            child: createTestableWidget(
              child: const WelcomeScreen(),
              prefs: prefs,
              repo: repo,
              isDark: true,
            ),
          ),
          GoldenTestScenario(
            name: 'Light Theme',
            child: createTestableWidget(
              child: const WelcomeScreen(),
              prefs: prefs,
              repo: repo,
              isDark: false,
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'renders LoginScreen in dark and light modes',
      fileName: 'login_screen',
      builder: () => GoldenTestGroup(
        scenarioConstraints: mobileConstraints,
        children: [
          GoldenTestScenario(
            name: 'Dark Theme',
            child: createTestableWidget(
              child: const LoginScreen(),
              prefs: prefs,
              repo: repo,
              isDark: true,
            ),
          ),
          GoldenTestScenario(
            name: 'Light Theme',
            child: createTestableWidget(
              child: const LoginScreen(),
              prefs: prefs,
              repo: repo,
              isDark: false,
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'renders RegisterScreen in dark and light modes',
      fileName: 'register_screen',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(
          width: 390,
          height: 950,
        ),
        children: [
          GoldenTestScenario(
            name: 'Dark Theme',
            child: createTestableWidget(
              child: const RegisterScreen(),
              prefs: prefs,
              repo: repo,
              isDark: true,
            ),
          ),
          GoldenTestScenario(
            name: 'Light Theme',
            child: createTestableWidget(
              child: const RegisterScreen(),
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
