import 'package:flutter_test/flutter_test.dart';

import 'package:quickeats/main.dart';

void main() {
  testWidgets('QuickEats app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const QuickEatsApp());

    expect(find.text('QuickEats'), findsOneWidget);
  });
}