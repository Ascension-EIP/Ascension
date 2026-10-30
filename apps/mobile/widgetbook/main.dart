// @date 2026-10-30
// @file main.dart
// @brief Interactive component & screen catalog sandbox for Ascension mobile app.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:mobile/app/app_theme.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/entities/auth_session.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:mobile/features/auth/presentation/screens/welcome_screen.dart';
import 'package:mobile/features/climb_session/presentation/screens/home_screen.dart';
import 'package:mobile/features/climb_session/presentation/screens/sessions_screen.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:mobile/features/profile/presentation/screens/settings_screen.dart';
import 'package:mobile/features/training/presentation/screens/training_screen.dart';
import 'package:mobile/features/video_upload/presentation/screens/record_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgetbook/widgetbook.dart';

class _WidgetbookFakeAuthRepository implements AuthRepository {
  @override
  Future<Result<AuthSession>> login({
    required String identifier,
    required String password,
    bool remember = true,
  }) async {
    return const Success(
      AuthSession(
        accessToken: 'mock_token',
        refreshToken: 'mock_refresh',
        tokenType: 'Bearer',
        expiresIn: 3600,
        user: User(
          id: 'wb_user',
          username: 'climber',
          email: 'climber@ascension.app',
          firstName: 'Alex',
          lastName: 'Ondra',
        ),
      ),
    );
  }

  @override
  Future<Result<AuthSession>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    bool remember = true,
  }) async {
    return const Success(
      AuthSession(
        accessToken: 'mock_token',
        refreshToken: 'mock_refresh',
        tokenType: 'Bearer',
        expiresIn: 3600,
        user: User(
          id: 'wb_new_user',
          username: 'new_climber',
          email: 'new@ascension.app',
          firstName: 'New',
          lastName: 'Climber',
        ),
      ),
    );
  }

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<bool> hasValidSession() async => true;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          _WidgetbookFakeAuthRepository(),
        ),
      ],
      child: const AscensionWidgetbookApp(),
    ),
  );
}

class AscensionWidgetbookApp extends StatelessWidget {
  const AscensionWidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        WidgetbookFolder(
          name: 'Authentication',
          children: [
            WidgetbookComponent(
              name: 'WelcomeScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Overview',
                  builder: (context) => const WelcomeScreen(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'LoginScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const LoginScreen(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'RegisterScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const RegisterScreen(),
                ),
              ],
            ),
          ],
        ),
        WidgetbookFolder(
          name: 'Profile & Settings',
          children: [
            WidgetbookComponent(
              name: 'ProfileScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Overview',
                  builder: (context) => const ProfileScreen(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'SettingsScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Overview',
                  builder: (context) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
        WidgetbookFolder(
          name: 'Main Features',
          children: [
            WidgetbookComponent(
              name: 'HomeScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Overview',
                  builder: (context) => const HomeScreen(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'SessionsScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Overview',
                  builder: (context) => const SessionsScreen(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'TrainingScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Overview',
                  builder: (context) => const TrainingScreen(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'RecordScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Overview',
                  builder: (context) => const RecordScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
      addons: [
        ThemeAddon<FThemeData>(
          themes: [
            WidgetbookTheme(
              name: 'Dark Theme (Ascension)',
              data: AppTheme.dark(),
            ),
            WidgetbookTheme(name: 'Light Theme', data: AppTheme.light()),
          ],
          themeBuilder: (context, theme, child) =>
              FTheme(data: theme, child: child),
        ),
        LocalizationAddon(
          locales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
        TextScaleAddon(min: 0.8, max: 2.0),
        ViewportAddon(Viewports.all),
        InspectorAddon(),
      ],
    );
  }
}
