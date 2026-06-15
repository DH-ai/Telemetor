import '../models/telemetry_channel.dart';

/// Connection lifecycle of a [TelemetryTransport].
enum TransportState {
  disconnected,
  connecting,
  handshaking,
  connected,
  reconnecting,
}

/// A parsed message from the telemetry stream.
sealed class TelemetryPacket {
  const TelemetryPacket();
}

/// The stream's schema announcement: which channels exist.
final class HeaderPacket extends TelemetryPacket {
  const HeaderPacket(this.channels);

  final List<TelemetryChannel> channels;
}

/// One acknowledged frame of data rows.
final class DataPacket extends TelemetryPacket {
  const DataPacket({required this.ackNumber, required this.rows});

  final int ackNumber;
  final List<List<String>> rows;
}

/// Abstract source of telemetry packets over some wire.
///
/// Implementations own the connection lifecycle: [connect] starts the
/// transport and keeps it alive (reconnecting as needed) until
/// [disconnect] is called.
abstract interface class TelemetryTransport {
  String get host;
  int get port;

  TransportState get state;

  /// Emits every state change. Broadcast.
  Stream<TransportState> get states;

  /// Parsed packets from the wire. Broadcast.
  Stream<TelemetryPacket> get packets;

  /// Human-readable connection/protocol errors. Broadcast.
  Stream<String> get errors;

  Future<void> connect();

  Future<void> disconnect();

  /// Points the transport at a new endpoint. If currently running, drops
  /// the connection and reconnects to the new host/port immediately.
  Future<void> setEndpoint({String? host, int? port});
}
