// Bisimo widget test

import 'package:flutter_test/flutter_test.dart';
import 'package:bisimo/app.dart';

void main() {
  testWidgets('Bisimo app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BisimoApp());

    // Verify that app name is shown on splash screen
    expect(find.text('Bisimo'), findsOneWidget);
  });
}
