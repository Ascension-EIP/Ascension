// @date 2026-10-25
// @file flutter_test_config.dart
// @brief Global configuration for Flutter tests and golden testing with Alchemist.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:async';

import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: true,
      ),
      ciGoldensConfig: CiGoldensConfig(
        enabled: true,
      ),
    ),
    run: testMain,
  );
}
