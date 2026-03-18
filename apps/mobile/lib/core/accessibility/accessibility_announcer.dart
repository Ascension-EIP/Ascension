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
