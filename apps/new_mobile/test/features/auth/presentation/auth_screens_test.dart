// @date 2026-09-29
// @file auth_screens_test.dart
// @brief Widget tests for WelcomeScreen, LoginScreen and RegisterScreen.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:new_mobile/app/app_theme.dart';
import 'package:new_mobile/core/errors/failures.dart';
import 'package:new_mobile/core/l10n/app_localizations.dart';
import 'package:new_mobile/core/storage/local_storage_service.dart';
import 'package:new_mobile/core/utils/result.dart';
import 'package:new_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:new_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:new_mobile/features/auth/domain/entities/user.dart';
import 'package:new_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:new_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:new_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:new_mobile/features/auth/presentation/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthRepository implements AuthRepository {
  Result<AuthSession>? loginResult;
  Result<AuthSession>? registerResult;

  String? lastLoginIdentifier;
  String? lastLoginPassword;
  String? lastRegisterUsername;
  String? lastRegisterFirstName;
  String? lastRegisterLastName;
  String? lastRegisterEmail;

  @override
  Future<Result<AuthSession>> login({
    required String identifier,
    required String password,
    bool remember = true,
  }) async {
    lastLoginIdentifier = identifier;
    lastLoginPassword = password;
    return loginResult ??
        const Success(
          AuthSession(
            accessToken: 'dummy_acc',
            refreshToken: 'dummy_ref',
            tokenType: 'Bearer',
            expiresIn: 3600,
            user: User(
              id: 'u1',
              username: 'tester',
              email: 'test@ascension.app',
              firstName: 'Test',
              lastName: 'User',
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
    lastRegisterUsername = username;
    lastRegisterFirstName = firstName;
    lastRegisterLastName = lastName;
    lastRegisterEmail = email;
    return registerResult ??
        const Success(
          AuthSession(
            accessToken: 'dummy_acc',
            refreshToken: 'dummy_ref',
            tokenType: 'Bearer',
            expiresIn: 3600,
            user: User(
              id: 'u2',
              username: 'new_tester',
              email: 'new@ascension.app',
              firstName: 'New',
              lastName: 'Tester',
            ),
          ),
        );
  }

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<bool> hasValidSession() async => false;
}

Widget createTestableWidget({
  required Widget child,
  required SharedPreferences prefs,
  required FakeAuthRepository repo,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => FTheme(
        data: AppTheme.dark(),
        child: child!,
      ),
      home: child,
    ),
  );
}

void main() {
  late FakeAuthRepository fakeRepo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeRepo = FakeAuthRepository();
  });

  group('WelcomeScreen Widget Tests', () {
    testWidgets('renders brand identity, title, slogan, and actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestableWidget(
          child: const WelcomeScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ascension'), findsOneWidget);
      expect(find.text('Visualise the invisible!'), findsOneWidget);
      expect(find.widgetWithText(FButton, 'Sign In'), findsOneWidget);
      expect(find.widgetWithText(FButton, 'Sign Up'), findsOneWidget);
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all login elements and actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestableWidget(
          child: const LoginScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsAtLeastNWidgets(1));
      expect(find.text('Email or Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows validation error when submitting empty fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestableWidget(
          child: const LoginScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      final signInButton = find.widgetWithText(FButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsAtLeastNWidgets(1));
      expect(fakeRepo.lastLoginIdentifier, isNull);
    });

    testWidgets('calls login on repository when fields are populated', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestableWidget(
          child: const LoginScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(EditableText);
      await tester.enterText(textFields.first, 'alex@climber.com');
      await tester.enterText(textFields.last, 'mypassword');
      await tester.pumpAndSettle();

      final signInButton = find.widgetWithText(FButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastLoginIdentifier, equals('alex@climber.com'));
      expect(fakeRepo.lastLoginPassword, equals('mypassword'));
    });

    testWidgets('displays error alert when login fails', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeRepo.loginResult = const Error(AuthFailure('Invalid identifier or password'));

      await tester.pumpWidget(
        createTestableWidget(
          child: const LoginScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(EditableText);
      await tester.enterText(textFields.first, 'bad@user.com');
      await tester.enterText(textFields.last, 'wrong');
      await tester.pumpAndSettle();

      final signInButton = find.widgetWithText(FButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Invalid identifier or password'), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders all registration fields in correct order', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestableWidget(
          child: const RegisterScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign Up'), findsAtLeastNWidgets(1));
      expect(find.text('First name'), findsOneWidget);
      expect(find.text('Last name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
    });

    testWidgets('automatically generates username from first and last name', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestableWidget(
          child: const RegisterScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(EditableText);
      // at(0): firstName, at(1): lastName, at(2): username
      await tester.enterText(textFields.at(0), 'Alex');
      await tester.pumpAndSettle();
      expect(find.text('alex'), findsOneWidget);

      await tester.enterText(textFields.at(1), 'Hon');
      await tester.pumpAndSettle();
      expect(find.text('alex_hon'), findsOneWidget);
    });

    testWidgets('validates required fields on submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestableWidget(
          child: const RegisterScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      final signUpButton = find.widgetWithText(FButton, 'Sign Up');
      await tester.ensureVisible(signUpButton);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsAtLeastNWidgets(2));
      expect(fakeRepo.lastRegisterUsername, isNull);
    });

    testWidgets('validates password mismatch and invalid email format', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestableWidget(
          child: const RegisterScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(EditableText);
      // firstName, lastName, username, email, password, confirmPassword
      await tester.enterText(textFields.at(0), 'Alex');
      await tester.enterText(textFields.at(1), 'Hon');
      await tester.enterText(textFields.at(3), 'not-an-email');
      await tester.enterText(textFields.at(4), 'pass1');
      await tester.enterText(textFields.at(5), 'pass2');
      await tester.pumpAndSettle();

      final signUpButton = find.widgetWithText(FButton, 'Sign Up');
      await tester.ensureVisible(signUpButton);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('submits valid registration and triggers repository', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestableWidget(
          child: const RegisterScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(EditableText);
      // firstName, lastName, username, email, password, confirmPassword
      await tester.enterText(textFields.at(0), 'Alex');
      await tester.enterText(textFields.at(1), 'Hon');
      await tester.enterText(textFields.at(3), 'alex@climber.com');
      await tester.enterText(textFields.at(4), 'secure_password');
      await tester.enterText(textFields.at(5), 'secure_password');
      await tester.pumpAndSettle();

      final signUpButton = find.widgetWithText(FButton, 'Sign Up');
      await tester.ensureVisible(signUpButton);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastRegisterFirstName, equals('Alex'));
      expect(fakeRepo.lastRegisterLastName, equals('Hon'));
      expect(fakeRepo.lastRegisterUsername, equals('alex_hon'));
      expect(fakeRepo.lastRegisterEmail, equals('alex@climber.com'));
    });
  });
}
