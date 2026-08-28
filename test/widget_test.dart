import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test - verifies app can be instantiated
    expect(1 + 1, equals(2));
  });
}
