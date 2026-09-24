// @date 2026-09-25
// @file app.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:new_mobile/app/app_theme.dart';
import 'package:new_mobile/app/env.dart';

class AscensionApp extends ConsumerWidget {
  const AscensionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppEnv.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.materialDark(),
      builder: (context, child) {
        return FTheme(
          data: AppTheme.dark(),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const Scaffold(
        body: Center(
          child: Text('Ascension Mobile'),
        ),
      ),
    );
  }
}
