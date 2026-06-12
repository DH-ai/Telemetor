import 'dart:async';

import '../network/telemetry_transport.dart';
import 'telemetry_hub.dart';

/// Routes transport packets into the hub: header packets (re)configure the
/// channel set, data packets become per-channel samples.
StreamSubscription<TelemetryPacket> bindTransportToHub(
    TelemetryTransport transport, TelemetryHub hub) {
  return transport.packets.listen((packet) {
    switch (packet) {
      case HeaderPacket(:final channels):
        hub.configure(channels);
      case DataPacket(:final rows):
        for (final row in rows) {
          if (row.isEmpty) continue;
          hub.ingestRow(row.first, row.sublist(1));
        }
    }
  });
}
