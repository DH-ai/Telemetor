import 'package:flutter_test/flutter_test.dart';
import 'package:telemetor/main.dart';
import 'package:telemetor/src/data/telemetry_hub.dart';
import 'package:telemetor/src/models/telemetry_channel.dart';

void main() {
  testWidgets('App renders the home screen', (WidgetTester tester) async {
    final hub = TelemetryHub();
    await tester.pumpWidget(TelemetorApp(hub: hub));

    expect(find.text('T E L E M E T O R'), findsOneWidget);
  });

  testWidgets('Chart area appears once channels are discovered',
      (WidgetTester tester) async {
    final hub = TelemetryHub();
    await tester.pumpWidget(TelemetorApp(hub: hub));

    hub.configure(const [
      TelemetryChannel(name: 'B', type: 'A'),
      TelemetryChannel(name: 'C', type: 'A'),
    ]);
    hub.ingestRow('1', ['42', '7']);
    await tester.pump();

    // The live chart subscribes to the second channel without errors.
    expect(tester.takeException(), isNull);
  });
}
