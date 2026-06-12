import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:telemetor/src/data/stream_stats.dart';
import 'package:telemetor/src/models/telemetry_channel.dart';
import 'package:telemetor/src/network/telemetry_transport.dart';

/// Minimal transport stub that lets tests inject packets.
class StubTransport implements TelemetryTransport {
  final _packets = StreamController<TelemetryPacket>.broadcast();

  void emit(TelemetryPacket packet) => _packets.add(packet);

  @override
  Stream<TelemetryPacket> get packets => _packets.stream;

  @override
  String get host => 'stub';
  @override
  int get port => 0;
  @override
  TransportState get state => TransportState.connected;
  @override
  Stream<TransportState> get states => const Stream.empty();
  @override
  Stream<String> get errors => const Stream.empty();
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> setEndpoint({String? host, int? port}) async {}

  Future<void> close() => _packets.close();
}

DataPacket frame(int ack, int rowCount) => DataPacket(
      ackNumber: ack,
      rows: [
        for (var i = 0; i < rowCount; i++) ['1', '2'],
      ],
    );

void main() {
  late StubTransport transport;
  late StreamStats stats;
  var now = DateTime(2026, 1, 1, 12);

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    transport = StubTransport();
    stats = StreamStats(transport, clock: () => now);
  });

  tearDown(() async {
    stats.dispose();
    await transport.close();
  });

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('counts rows and computes the windowed rate', () async {
    transport.emit(frame(0, 10));
    transport.emit(frame(1, 15));
    await pump();

    expect(stats.totalRows.value, 25);
    // 25 rows over the 5 s window.
    expect(stats.rowsPerSecond.value, 5.0);
  });

  test('old events fall out of the rate window', () async {
    transport.emit(frame(0, 50));
    await pump();
    expect(stats.rowsPerSecond.value, 10.0);

    now = now.add(const Duration(seconds: 10));
    transport.emit(frame(1, 5));
    await pump();

    expect(stats.rowsPerSecond.value, 1.0);
    expect(stats.totalRows.value, 55);
  });

  test('detects dropped frames via ACK gaps', () async {
    transport.emit(frame(0, 1));
    transport.emit(frame(1, 1));
    transport.emit(frame(4, 1)); // 2 and 3 lost
    await pump();

    expect(stats.droppedFrames.value, 2);
  });

  test('retransmissions of the same ACK are not drops', () async {
    transport.emit(frame(0, 1));
    transport.emit(frame(0, 1));
    transport.emit(frame(1, 1));
    await pump();

    expect(stats.droppedFrames.value, 0);
  });

  test('header packet resets the ACK sequence (reconnect)', () async {
    transport.emit(frame(7, 1));
    await pump();
    transport.emit(const HeaderPacket([TelemetryChannel(name: 'alt')]));
    transport.emit(frame(0, 1)); // would look like a regression otherwise
    await pump();

    expect(stats.droppedFrames.value, 0);
  });
}
