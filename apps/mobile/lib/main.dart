import 'package:flutter/material.dart';
import 'package:mobile/layout/mobile_layout.dart';

void main() {
  runApp(const AscensionApp());
}

class AscensionApp extends StatelessWidget {
  const AscensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ascension',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.light,
          surface: Colors.white,
          onSurface: Colors.black,
          secondary: const Color(0xFF00B5D3),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.dark,
          surface: Color(0xFF0E1626),
          onSurface: Colors.white,
          secondary: const Color(0xFF00B5D3),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: MobileLayout(),
    );
  }
}
