import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';

import '../data/data_queue.dart';

final Logger _logger = Logger();

/// Handles the TCP connection and the ACK handshake with the Python server.
///
/// Protocol (see Backend/ACK.md):
///   server -> ACK-CONNECT,  client -> ACK-CONNECT
///   server -> ACK-EXCHANGE, client -> ACK-EXCHANGE
///   server -> HEADERS{...}:TYPES{...}, client -> ACK-COMPLETE
///   then data frames `[...]::ACK(n)` answered with `::ACK(n)`.
///
/// Prototype implementation: G1-M3 replaces this with a proper
/// TelemetryTransport interface with reconnect and error surfacing.
class NetworkHandler {
  NetworkHandler({required this.host, required this.port});

  final String host;
  final int port;
  bool ackStatus = false;

  Future<void> connect() async {
    try {
      final socket = await Socket.connect(host, port);
      _logger.i(
          'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      await _acknowledge(socket);
      ackStatus = true;
    } catch (e) {
      _logger.e('Connection failed: $e');
    }
  }

  Future<void> _acknowledge(Socket socket) async {
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
    } else if (ack.contains('HEAD') && lastAck == 'ACK-EXCHANGE') {
      final match =
          RegExp(r'HEADERS\[([^}]+)\]:TYPES\[([^}]+)\]').firstMatch(ack);
      _logger.i('Headers: ${match?.group(1)}; Types: ${match?.group(2)}');
      _send(socket, 'ACK-COMPLETE');
      onComplete();
      return lastAck;
    }
    _logger.e('Acknowledgement failed: server sent $ack');
    return lastAck;
  }

  void _handleDataFrame(Socket socket, String frame) {
    final match = RegExp(r'\[(.*?)\]::ACK\((\d+)\)').firstMatch(frame);
    final payload = match?.group(1);
    final ackNum = match?.group(2);
    if (payload == null || ackNum == null) {
      _logger.e('Malformed data frame: $frame');
      return;
    }
    _send(socket, '::ACK($ackNum)');
    for (final row in RegExp(r'\[(.*?)\]').allMatches(payload)) {
      dataQueue.add(row.group(1)!);
    }
  }

  void _send(Socket socket, String message) {
    socket.write(message);
  }
}
