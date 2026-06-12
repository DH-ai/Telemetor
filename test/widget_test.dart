import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:telemetor/main.dart';
import 'package:telemetor/src/data/telemetry_hub.dart';
import 'package:telemetor/src/models/telemetry_channel.dart';
import 'package:telemetor/src/network/tcp_ack_transport.dart';
import 'package:telemetor/src/network/transport_socket.dart';

/// A transport that never connects; good enough for widget tests.
TcpAckTransport idleTransport() => TcpAckTransport(
      host: 'localhost',
      port: 1,
      connector: (host, port, timeout) =>
          Completer<TransportSocket>().future,
    );

void main() {
  testWidgets('App renders the home screen', (WidgetTester tester) async {
    final hub = TelemetryHub();
    await tester.pumpWidget(TelemetorApp(hub: hub, transport: idleTransport()));

    expect(find.text('T E L E M E T O R'), findsOneWidget);
  });

  testWidgets('Chart area appears once channels are discovered',
      (WidgetTester tester) async {
    final hub = TelemetryHub();
    await tester.pumpWidget(TelemetorApp(hub: hub, transport: idleTransport()));

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
