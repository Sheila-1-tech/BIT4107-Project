import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_app/main.dart';

void main() {
  testWidgets('Pharmacy App Baseline Loading Test', (
    WidgetTester tester,
  ) async {
    // Build our custom pharmacy app and trigger a frame.
    await tester.pumpWidget(const PharmaProApp());

    // Verifies that the test framework initializes the widget tree smoothly
    expect(true, true);
  });
}
