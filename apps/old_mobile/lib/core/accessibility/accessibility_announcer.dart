// @date 2026-03-18
// @file accessibility_announcer.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';

class AccessibilityAnnouncer {
  static Future<void> announce(BuildContext context, String message) async {
    if (!MediaQuery.supportsAnnounceOf(context)) {
      return;
    }
    await SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }
}
