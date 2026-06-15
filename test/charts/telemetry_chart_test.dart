import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetor/src/charts/telemetry_chart.dart';
import 'package:telemetor/src/data/telemetry_hub.dart';
import 'package:telemetor/src/models/telemetry_channel.dart';

const altChannel = TelemetryChannel(name: 'alt', type: 'F', unit: 'm');
const tempChannel = TelemetryChannel(name: 'temp', type: 'F', unit: 'C');

Widget host(Widget chart) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 600, height: 400, child: chart)),
    );

void main() {
  late TelemetryHub hub;
  var now = DateTime(2026, 1, 1, 12);

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    hub = TelemetryHub(clock: () => now);
    hub.configure(const [altChannel, tempChannel]);
  });

  tearDown(() => hub.dispose());

  testWidgets('shows title with unit and a placeholder before data',
      (tester) async {
    await tester.pumpWidget(host(TelemetryChart(
      hub: hub,
      channels: const [altChannel],
      title: 'Altitude',
      unit: 'm',
    )));

    expect(find.text('Altitude (m)'), findsOneWidget);
    expect(find.text('Waiting for data…'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('plots samples after they arrive', (tester) async {
    await tester.pumpWidget(host(TelemetryChart(
      hub: hub,
      channels: const [altChannel],
      title: 'Altitude',
    )));

    hub.ingestRow('F', ['10', '21']);
    now = now.add(const Duration(milliseconds: 100));
    hub.ingestRow('F', ['12', '22']);
    await tester.pump(const Duration(milliseconds: 50));

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final spots = chart.data.lineBarsData.single.spots;
    expect(spots.length, 2);
    expect(spots.map((s) => s.y), [10, 12]);
  });

  testWidgets('renders one series per channel with a legend', (tester) async {
    await tester.pumpWidget(host(TelemetryChart(
      hub: hub,
      channels: const [altChannel, tempChannel],
      title: 'Combined',
    )));

    hub.ingestRow('F', ['10', '21']);
    await tester.pump(const Duration(milliseconds: 50));

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.length, 2);
    expect(find.text('alt'), findsOneWidget);
    expect(find.text('temp'), findsOneWidget);
    // Distinct palette colors per series.
    expect(chart.data.lineBarsData[0].color,
        isNot(chart.data.lineBarsData[1].color));
  });

  testWidgets('legend can be disabled', (tester) async {
    await tester.pumpWidget(host(TelemetryChart(
      hub: hub,
      channels: const [altChannel],
      title: 'Altitude',
      showLegend: false,
    )));

    expect(find.text('alt'), findsNothing);
  });

  testWidgets('drops samples outside the sliding time window',
      (tester) async {
    await tester.pumpWidget(host(TelemetryChart(
      hub: hub,
      channels: const [altChannel],
      title: 'Altitude',
      timeWindow: const Duration(seconds: 10),
    )));

    hub.ingestRow('F', ['1', '0']); // will fall out of the window
    now = now.add(const Duration(seconds: 60));
    hub.ingestRow('F', ['2', '0']);
    now = now.add(const Duration(seconds: 1));
    hub.ingestRow('F', ['3', '0']);
    await tester.pump(const Duration(milliseconds: 50));

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final spots = chart.data.lineBarsData.single.spots;
    expect(spots.map((s) => s.y), [2, 3]);
  });

  testWidgets('auto-scales the y axis around the visible data',
      (tester) async {
    await tester.pumpWidget(host(TelemetryChart(
      hub: hub,
      channels: const [altChannel],
      title: 'Altitude',
    )));

    hub.ingestRow('F', ['-50', '0']);
    hub.ingestRow('F', ['150', '0']);
    await tester.pump(const Duration(milliseconds: 50));

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.minY, lessThan(-50));
    expect(chart.data.maxY, greaterThan(150));
  });

  testWidgets('decimates large series to at most maxPoints', (tester) async {
    await tester.pumpWidget(host(TelemetryChart(
      hub: hub,
      channels: const [altChannel],
      title: 'Altitude',
      maxPoints: 100,
    )));

    for (var i = 0; i < 500; i++) {
      hub.ingestRow('F', ['$i', '0']);
      now = now.add(const Duration(milliseconds: 10));
    }
    await tester.pump(const Duration(milliseconds: 50));

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots.length,
        lessThanOrEqualTo(100));
  });

  testWidgets('coalesces bursts of samples into throttled repaints',
      (tester) async {
    await tester.pumpWidget(host(TelemetryChart(
      hub: hub,
      channels: const [altChannel],
      title: 'Altitude',
      minRepaintInterval: const Duration(milliseconds: 100),
    )));

    // First sample paints immediately (no recent paint).
    hub.ingestRow('F', ['1', '0']);
    await tester.pump(const Duration(milliseconds: 10));
    var chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots.length, 1);

    // A burst within the interval is deferred...
    hub.ingestRow('F', ['2', '0']);
    hub.ingestRow('F', ['3', '0']);
    await tester.pump(const Duration(milliseconds: 10));
    chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots.length, 1);

    // ...and lands once the interval elapses, as a single repaint.
    await tester.pump(const Duration(milliseconds: 120));
    chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots.length, 3);
  });

  testWidgets('is wrapped in a RepaintBoundary', (tester) async {
    await tester.pumpWidget(host(TelemetryChart(
      hub: hub,
      channels: const [altChannel],
      title: 'Altitude',
    )));

    expect(
      find.descendant(
        of: find.byType(TelemetryChart),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
  });
}
