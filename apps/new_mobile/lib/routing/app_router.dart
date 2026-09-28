// @date 2026-09-29
// @file app_router.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:new_mobile/features/auth/presentation/controllers/auth_state.dart';
import 'package:new_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:new_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:new_mobile/features/auth/presentation/screens/welcome_screen.dart';
import 'package:new_mobile/features/climb_session/presentation/screens/home_screen.dart';
import 'package:new_mobile/features/climb_session/presentation/screens/sessions_screen.dart';
import 'package:new_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:new_mobile/features/profile/presentation/screens/settings_screen.dart';
import 'package:new_mobile/features/training/presentation/screens/training_screen.dart';
import 'package:new_mobile/routing/routes.dart';
import 'package:new_mobile/routing/shell/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Listenable that notifies [GoRouter] when [authStateProvider] changes.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen(authStateProvider, (_, next) => notifyListeners());
  }

  final Ref ref;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Riverpod provider configuring [GoRouter] with 4 main navigation tabs and auth guards.
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.home.path,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      if (authState.isInitial) {
        return null;
      }

      final isAuthRoute = state.matchedLocation == AppRoute.welcome.path ||
          state.matchedLocation == AppRoute.login.path ||
          state.matchedLocation == AppRoute.register.path;

      if (!authState.isAuthenticated && !isAuthRoute) {
        return AppRoute.welcome.path;
      }

      if (authState.isAuthenticated && isAuthRoute) {
        return AppRoute.home.path;
      }

      return null;
    },
    routes: [
      // Auth routes (outside the navigation shell)
      GoRoute(
        path: AppRoute.welcome.path,
        name: AppRoute.welcome.name,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.register.path,
        name: AppRoute.register.name,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.settings.path,
        name: AppRoute.settings.name,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Main application tabs (4 tabs: Home, Sessions, Training, Profile)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home.path,
                name: AppRoute.home.name,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.sessions.path,
                name: AppRoute.sessions.name,
                builder: (context, state) => const SessionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.training.path,
                name: AppRoute.training.name,
                builder: (context, state) => const TrainingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.profile.path,
                name: AppRoute.profile.name,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
