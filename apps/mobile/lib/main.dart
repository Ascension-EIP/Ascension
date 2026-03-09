import 'package:flutter/material.dart';
import 'package:mobile/shared/layout/mobile_layout.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().loadBaseUrl();
  runApp(const AscensionApp());
}

class AscensionApp extends StatelessWidget {
  const AscensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ascension',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const MobileLayout(),
    );
  }
}
