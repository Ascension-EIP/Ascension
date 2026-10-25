// @date 2026-10-25
// @file main.dart
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const AscensionApp(),
    ),
  );
}
