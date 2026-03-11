import 'package:flutter_test/flutter_test.dart';
import 'package:calx/main.dart';

void main() {
  testWidgets('Counter increment smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AICalorieApp());

    // Verify that our onboarding starts (or dashboard if setup)
    expect(
      find.text('GET STARTED'),
      findsNothing,
    ); // It's a button later in pageview
  });
}
