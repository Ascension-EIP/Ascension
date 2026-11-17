// @date 2026-11-13
// @file test_helper.dart
// @brief Shared helpers, mock providers and wrappers for widget and golden tests.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:forui/forui.dart';
import 'package:mobile/app/app_theme.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/entities/auth_session.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/climb_session/data/repositories/climb_session_repository_impl.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:mobile/features/climb_session/domain/repositories/climb_session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestAuthRepository implements AuthRepository {
  Result<AuthSession>? loginResult;
  Result<AuthSession>? registerResult;
  Result<void>? logoutResult;

  String? lastLoginIdentifier;
  String? lastLoginPassword;
  String? lastRegisterUsername;
  String? lastRegisterFirstName;
  String? lastRegisterLastName;
  String? lastRegisterEmail;
  bool logoutCalled = false;

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
  Future<Result<void>> logout() async {
    logoutCalled = true;
    return logoutResult ?? const Success(null);
  }

  @override
  Future<bool> hasValidSession() async => true;
}

class TestClimbSessionRepository implements ClimbSessionRepository {
  ClimbSession? activeSession;
  final List<ClimbSession> previousSessions;
  final List<ClimbAnalysisSummary> previousAnalyses;

  TestClimbSessionRepository({
    this.activeSession,
    List<ClimbSession>? previousSessions,
    List<ClimbAnalysisSummary>? previousAnalyses,
  }) : previousSessions = previousSessions ?? [],
       previousAnalyses = previousAnalyses ?? [];

  @override
  Future<Result<ClimbSession?>> getActiveSession() async =>
      Success(activeSession);

  @override
  Future<Result<List<ClimbSession>>> getPreviousSessions({
    int limit = 50,
    int offset = 0,
  }) async => Success(previousSessions);

  @override
  Future<Result<ClimbSession>> getSessionDetails(String sessionId) async {
    final session =
        (activeSession?.id == sessionId ? activeSession : null) ??
        previousSessions.firstWhere((s) => s.id == sessionId);
    return Success(session);
  }

  @override
  Future<Result<List<ClimbAnalysisSummary>>> getPreviousAnalyses({
    int limit = 50,
    int offset = 0,
  }) async => Success(previousAnalyses);

  @override
  Future<Result<ClimbSession>> startSession({
    required String name,
    String? location,
    String? gymId,
    DateTime? startedAt,
    required ClimbSessionVisibility visibility,
    String? notes,
  }) async {
    final session = ClimbSession(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      location: location,
      gymId: gymId,
      notes: notes,
      startedAt: startedAt ?? DateTime.now(),
      visibility: visibility,
      analyses: const [],
    );
    activeSession = session;
    return Success(session);
  }

  @override
  Future<Result<ClimbSession>> endSession(
    String sessionId, {
    DateTime? endedAt,
    String? name,
    String? notes,
  }) async {
    final session =
        (activeSession?.id == sessionId ? activeSession : null) ??
        previousSessions.firstWhere((s) => s.id == sessionId);
    final ended = session.copyWith(
      endedAt: endedAt ?? DateTime.now(),
      name: name ?? session.name,
      notes: notes ?? session.notes,
    );
    if (activeSession?.id == sessionId) {
      activeSession = null;
    }
    final index = previousSessions.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      previousSessions[index] = ended;
    } else {
      previousSessions.insert(0, ended);
    }
    return Success(ended);
  }

  @override
  Future<Result<ClimbSession>> updateSession(
    String sessionId, {
    String? title,
    String? notes,
    DateTime? endedAt,
  }) async {
    final index = previousSessions.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      final updated = previousSessions[index].copyWith(
        name: title ?? previousSessions[index].name,
        notes: notes ?? previousSessions[index].notes,
        endedAt: endedAt ?? previousSessions[index].endedAt,
      );
      previousSessions[index] = updated;
      return Success(updated);
    }
    if (activeSession?.id == sessionId) {
      final updated = activeSession!.copyWith(
        name: title ?? activeSession!.name,
        notes: notes ?? activeSession!.notes,
        endedAt: endedAt ?? activeSession!.endedAt,
      );
      activeSession = updated;
      return Success(updated);
    }
    return const Error(ServerFailure('Session not found'));
  }

  @override
  Future<Result<void>> addAnalysisToActiveSession(
    ClimbAnalysisSummary analysis,
  ) async {
    if (activeSession != null) {
      activeSession = activeSession!.copyWith(
        analyses: [...activeSession!.analyses, analysis],
      );
    }
    previousAnalyses.insert(0, analysis);
    return const Success(null);
  }

  @override
  Future<Result<void>> linkAnalysisToSession({
    required String sessionId,
    required String analysisId,
  }) async => const Success(null);

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    if (activeSession?.id == sessionId) {
      activeSession = null;
    }
    previousSessions.removeWhere((s) => s.id == sessionId);
    return const Success(null);
  }
}

Widget createTestableWidget({
  required Widget child,
  SharedPreferences? prefs,
  AuthRepository? repo,
  ClimbSessionRepository? climbSessionRepo,
  Locale locale = const Locale('en'),
  bool isDark = true,
  List<Override> additionalOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
      if (repo != null) authRepositoryProvider.overrideWithValue(repo),
      climbSessionRepositoryProvider.overrideWithValue(
        climbSessionRepo ?? TestClimbSessionRepository(),
      ),
      ...additionalOverrides,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => FTheme(
        data: isDark ? AppTheme.dark() : AppTheme.light(),
        child: Material(type: MaterialType.transparency, child: child!),
      ),
      home: child,
    ),
  );
}
