import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';

import '../data/telemetry_hub.dart';
import 'wire_parser.dart';

final Logger _logger = Logger();

/// Handles the TCP connection and the ACK handshake with the Python server.
///
/// Protocol (see Backend/ACK.md):
///   server -> ACK-CONNECT,  client -> ACK-CONNECT
///   server -> ACK-EXCHANGE, client -> ACK-EXCHANGE
///   server -> HEADERS{...}:TYPES{...}, client -> ACK-COMPLETE
///   then data frames `[...]::ACK(n)` answered with `::ACK(n)`.
///
/// Parsed rows are pushed straight into the [TelemetryHub] (event-driven,
/// no intermediate queue). Prototype implementation: G1-M3 replaces this
/// with a proper TelemetryTransport interface with reconnect and error
/// surfacing.
class NetworkHandler {
  NetworkHandler({required this.host, required this.port, required this.hub});

  final String host;
  final int port;
  final TelemetryHub hub;
  bool ackStatus = false;

  Future<void> connect() async {
    try {
      final socket = await Socket.connect(host, port);
      _logger.i(
          'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      _listen(socket);
      ackStatus = true;
    } catch (e) {
      _logger.e('Connection failed: $e');
    }
  }

  void _listen(Socket socket) {
    var handshakeDone = false;
    String? lastAck;

    socket.listen((Uint8List data) {
      final message = utf8.decode(data);
      if (handshakeDone) {
        _handleDataFrame(socket, message);
      } else {
        lastAck = _handleHandshake(socket, message, lastAck,
            onComplete: () => handshakeDone = true);
      }
    });
  }

  String? _handleHandshake(Socket socket, String ack, String? lastAck,
      {required void Function() onComplete}) {
    if (ack == 'ACK-CONNECT') {
      _send(socket, 'ACK-CONNECT');
      return ack;
    } else if (ack == 'ACK-EXCHANGE') {
      _send(socket, 'ACK-EXCHANGE');
      return ack;
    } else if (WireParser.isHeaderPacket(ack) && lastAck == 'ACK-EXCHANGE') {
      final channels = WireParser.parseHeader(ack);
      if (channels == null) {
        _logger.e('Unparseable header packet: $ack');
        return lastAck;
      }
      _logger.i('Discovered channels: ${channels.map((c) => c.name)}');
      hub.configure(channels);
      _send(socket, 'ACK-COMPLETE');
      onComplete();
      return lastAck;
    }
    _logger.e('Acknowledgement failed: server sent $ack');
    return lastAck;
  }

  void _handleDataFrame(Socket socket, String frame) {
    final parsed = WireParser.parseDataFrame(frame);
    if (parsed == null) {
      _logger.e('Malformed data frame: $frame');
      return;
    }
    _send(socket, '::ACK(${parsed.ackNumber})');
    for (final row in parsed.rows) {
      if (row.isEmpty) continue;
      hub.ingestRow(row.first, row.sublist(1));
    }
  }

  void _send(Socket socket, String message) {
    socket.write(message);
  }
}
