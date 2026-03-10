import 'package:go_router/go_router.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/auth/presentation/pages/register_page.dart';
import 'package:mobile/shared/layout/mobile_layout.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthService(),
  redirect: (context, state) {
    final isLoggedIn = AuthService().isLoggedIn;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == '/login' || loc == '/register';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MobileLayout(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
  ],
);
