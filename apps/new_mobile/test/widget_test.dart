// @date 2026-09-25
// @file widget_test.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_mobile/app/app.dart';

void main() {
  testWidgets('AscensionApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AscensionApp(),
      ),
    );

    expect(find.text('Ascension Mobile'), findsOneWidget);
  });
}
