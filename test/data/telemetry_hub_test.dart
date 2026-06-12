import 'package:flutter_test/flutter_test.dart';
import 'package:telemetor/src/data/telemetry_hub.dart';
import 'package:telemetor/src/models/telemetry_channel.dart';
import 'package:telemetor/src/models/telemetry_sample.dart';

void main() {
  final fixedTime = DateTime(2026, 1, 1, 12);

  TelemetryHub makeHub() => TelemetryHub(clock: () => fixedTime);

  group('TelemetryHub.configure', () {
    test('exposes the channel list and notifies listeners', () {
      final hub = makeHub();
      var notified = 0;
      hub.channelsNotifier.addListener(() => notified++);

      hub.configure(const [
        TelemetryChannel(name: 'alt', type: 'F'),
        TelemetryChannel(name: 'temp', type: 'F'),
      ]);

      expect(hub.channels.map((c) => c.name), ['alt', 'temp']);
      expect(notified, 1);
    });

    test('closes streams of channels that disappear on reconfigure',
        () async {
      final hub = makeHub();
      hub.configure(const [TelemetryChannel(name: 'gone', type: 'F')]);
      var closed = false;
      hub.stream('gone').listen((_) {}, onDone: () => closed = true);

      hub.configure(const [TelemetryChannel(name: 'kept', type: 'F')]);
      await Future<void>.delayed(Duration.zero);

      expect(closed, isTrue);
    });
  });

  group('TelemetryHub.ingestRow', () {
    test('routes values to channels by type tag and emits samples', () async {
      final hub = makeHub();
      hub.configure(const [
        TelemetryChannel(name: 'alt', type: 'F'),
        TelemetryChannel(name: 'temp', type: 'F'),
        TelemetryChannel(name: 'lat', type: 'S'),
      ]);

      final altSamples = <TelemetrySample>[];
      final latSamples = <TelemetrySample>[];
      hub.stream('alt').listen(altSamples.add);
      hub.stream('lat').listen(latSamples.add);

      hub.ingestRow('F', ['100.5', '21']);
      hub.ingestRow('S', ['32.9']);
      await Future<void>.delayed(Duration.zero);

      expect(altSamples.single.value, 100.5);
      expect(altSamples.single.timestamp, fixedTime);
      expect(latSamples.single.value, 32.9);
    });

    test('falls back to the only group when the tag is unknown', () async {
      // Single-group streams (e.g. the simulated A,B,C,D,E csv) put data in
      // the first column rather than a tag.
      final hub = makeHub();
      hub.configure(const [
        TelemetryChannel(name: 'B', type: 'A'),
        TelemetryChannel(name: 'C', type: 'A'),
      ]);
      final samples = <TelemetrySample>[];
      hub.stream('B').listen(samples.add);

      hub.ingestRow('17', ['42', '7']);
      await Future<void>.delayed(Duration.zero);

      expect(samples.single.value, 42);
    });

    test('drops rows whose tag matches no group when several exist',
        () async {
      final hub = makeHub();
      hub.configure(const [
        TelemetryChannel(name: 'alt', type: 'F'),
        TelemetryChannel(name: 'lat', type: 'S'),
      ]);
      final samples = <TelemetrySample>[];
      hub.stream('alt').listen(samples.add);

      hub.ingestRow('X', ['1']);
      await Future<void>.delayed(Duration.zero);

      expect(samples, isEmpty);
    });

    test('skips non-numeric values but keeps the rest of the row', () async {
      final hub = makeHub();
      hub.configure(const [
        TelemetryChannel(name: 'v', type: 'S'),
        TelemetryChannel(name: 'fixType', type: 'S'),
        TelemetryChannel(name: 'altAbl', type: 'S'),
      ]);
      final v = <TelemetrySample>[];
      final fixType = <TelemetrySample>[];
      final altAbl = <TelemetrySample>[];
      hub.stream('v').listen(v.add);
      hub.stream('fixType').listen(fixType.add);
      hub.stream('altAbl').listen(altAbl.add);

      hub.ingestRow('S', ['0.02', "b'ROV'", '86.01']);
      await Future<void>.delayed(Duration.zero);

      expect(v.single.value, 0.02);
      expect(fixType, isEmpty);
      expect(altAbl.single.value, 86.01);
    });

    test('ignores extra values beyond the channel count', () async {
      final hub = makeHub();
      hub.configure(const [TelemetryChannel(name: 'a', type: 'F')]);
      final samples = <TelemetrySample>[];
      hub.stream('a').listen(samples.add);

      hub.ingestRow('F', ['1', '2', '3']);
      await Future<void>.delayed(Duration.zero);

      expect(samples.single.value, 1);
    });

    test('updates the latest-value notifier', () {
      final hub = makeHub();
      hub.configure(const [TelemetryChannel(name: 'alt', type: 'F')]);

      expect(hub.latest('alt').value, isNull);
      hub.ingestRow('F', ['55']);
      expect(hub.latest('alt').value?.value, 55);
      hub.ingestRow('F', ['56']);
      expect(hub.latest('alt').value?.value, 56);
    });
  });

  group('TelemetryHub.stream', () {
    test('is a broadcast stream: all listeners receive every sample',
        () async {
      final hub = makeHub();
      hub.configure(const [TelemetryChannel(name: 'alt', type: 'F')]);
      final first = <double>[];
      final second = <double>[];
      hub.stream('alt').listen((s) => first.add(s.value));
      hub.stream('alt').listen((s) => second.add(s.value));

      hub.ingestRow('F', ['1']);
      hub.ingestRow('F', ['2']);
      await Future<void>.delayed(Duration.zero);

      expect(first, [1, 2]);
      expect(second, [1, 2]);
    });

    test('can be subscribed before configure', () async {
      final hub = makeHub();
      final samples = <TelemetrySample>[];
      hub.stream('alt').listen(samples.add);

      hub.configure(const [TelemetryChannel(name: 'alt', type: 'F')]);
      hub.ingestRow('F', ['9']);
      await Future<void>.delayed(Duration.zero);

      expect(samples.single.value, 9);
    });
  });

  test('dispose closes all channel streams', () async {
    final hub = makeHub();
    hub.configure(const [TelemetryChannel(name: 'alt', type: 'F')]);
    var closed = false;
    hub.stream('alt').listen((_) {}, onDone: () => closed = true);

    hub.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(closed, isTrue);
  });
}
