import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetor/main.dart';
import 'package:telemetor/src/charts/telemetry_chart.dart';
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
  testWidgets('App renders the dashboard scaffold', (tester) async {
    final hub = TelemetryHub();
    await tester.pumpWidget(TelemetorApp(hub: hub, transport: idleTransport()));

    expect(find.text('T E L E M E T O R'), findsOneWidget);
    expect(find.text('No charts yet.'), findsOneWidget);
    expect(find.textContaining('rows/s'), findsOneWidget);
    expect(find.textContaining('disconnected'), findsOneWidget);
  });

  testWidgets('Discovered channels seed chart tiles and stat tiles',
      (tester) async {
    final hub = TelemetryHub();
    await tester.pumpWidget(TelemetorApp(hub: hub, transport: idleTransport()));

    hub.configure(const [
      TelemetryChannel(name: 'alt', type: 'F'),
      TelemetryChannel(name: 'temp', type: 'F'),
    ]);
    hub.ingestRow('F', ['42', '21']);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(TelemetryChart), findsNWidgets(2));
    expect(find.text('42'), findsOneWidget); // alt stat tile
    expect(find.text('21'), findsOneWidget); // temp stat tile
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tiles can be removed and re-added at runtime', (tester) async {
    final hub = TelemetryHub();
    await tester.pumpWidget(TelemetorApp(hub: hub, transport: idleTransport()));

    hub.configure(const [TelemetryChannel(name: 'alt', type: 'F')]);
    await tester.pump();
    expect(find.byType(TelemetryChart), findsOneWidget);

    await tester.tap(find.byTooltip('Remove chart'));
    await tester.pump();
    expect(find.byType(TelemetryChart), findsNothing);

    await tester.tap(find.byTooltip('Add chart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('alt').last);
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.byType(TelemetryChart), findsOneWidget);
  });

  testWidgets('Fullscreen shows a single tile and exits back to the grid',
      (tester) async {
    final hub = TelemetryHub();
    await tester.pumpWidget(TelemetorApp(hub: hub, transport: idleTransport()));

    hub.configure(const [
      TelemetryChannel(name: 'alt', type: 'F'),
      TelemetryChannel(name: 'temp', type: 'F'),
    ]);
    await tester.pump();
    expect(find.byType(TelemetryChart), findsNWidgets(2));

    await tester.tap(find.byTooltip('Fullscreen').first);
    await tester.pump();
    expect(find.byType(TelemetryChart), findsOneWidget);

    await tester.tap(find.byTooltip('Exit fullscreen'));
    await tester.pump();
    expect(find.byType(TelemetryChart), findsNWidgets(2));
  });

  testWidgets('Theme toggle switches between dark and light mode',
      (tester) async {
    final hub = TelemetryHub();
    await tester.pumpWidget(TelemetorApp(hub: hub, transport: idleTransport()));

    expect(
        Theme.of(tester.element(find.text('T E L E M E T O R'))).brightness,
        Brightness.dark);

    await tester.tap(find.byTooltip('Toggle light/dark mode'));
    await tester.pumpAndSettle();

    expect(
        Theme.of(tester.element(find.text('T E L E M E T O R'))).brightness,
        Brightness.light);
  });
}
