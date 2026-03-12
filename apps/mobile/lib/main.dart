import 'package:flutter/material.dart';
import 'package:mobile/core/audio/audio_service.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().loadBaseUrl();
  await AuthService().init();
  AudioService().init(); // lancé en arrière-plan, ne bloque pas le démarrage
  runApp(const AscensionApp());
}

class AscensionApp extends StatelessWidget {
  const AscensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ascension',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
