import 'package:flutter_test/flutter_test.dart';

import 'package:telemetor/main.dart';

void main() {
  testWidgets('App renders the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TelemetorApp());

    expect(find.text('T E L E M E T O R'), findsOneWidget);
  });
}
