import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:telemetor/src/network/tcp_ack_transport.dart';
import 'package:telemetor/src/network/telemetry_transport.dart';
import 'package:telemetor/src/network/transport_socket.dart';

class FakeSocket implements TransportSocket {
  final _incoming = StreamController<List<int>>();
  final List<String> written = [];
  bool closed = false;

  @override
  Stream<List<int>> get data => _incoming.stream;

  @override
  void write(String message) => written.add(message);

  @override
  Future<void> close() async {
    if (closed) return;
    closed = true;
    await _incoming.close();
  }

  /// Simulates the server sending [text].
  void serverSends(String text) => _incoming.add(utf8.encode(text));

  /// Simulates the server dropping the connection.
  Future<void> serverCloses() => _incoming.close();
}

/// Hands out queued fake sockets; throws when the queue is empty and
/// [failWhenEmpty] is set.
class FakeConnector {
  FakeConnector(this.sockets, {this.failWhenEmpty = false});

  final List<FakeSocket> sockets;
  final bool failWhenEmpty;
  int attempts = 0;

  Future<TransportSocket> call(String host, int port, Duration timeout) async {
    attempts++;
    if (sockets.isEmpty) {
      if (failWhenEmpty) throw const SocketFault();
      return Completer<TransportSocket>().future; // hang forever
    }
    return sockets.removeAt(0);
  }
}

class SocketFault implements Exception {
  const SocketFault();
}

const header = "HEADERS['alt', 'temp']:TYPES['F']";

TcpAckTransport makeTransport(FakeConnector connector,
    {Duration handshakeTimeout = const Duration(seconds: 15)}) {
  return TcpAckTransport(
    host: 'test-host',
    port: 1234,
    connector: connector.call,
    connectTimeout: const Duration(milliseconds: 100),
    handshakeTimeout: handshakeTimeout,
    initialBackoff: const Duration(milliseconds: 10),
    maxBackoff: const Duration(milliseconds: 40),
  );
}

/// Pumps the microtask/timer queue.
Future<void> pump([Duration duration = const Duration(milliseconds: 1)]) =>
    Future<void>.delayed(duration);

Future<void> completeHandshake(FakeSocket socket) async {
  socket.serverSends('ACK-CONNECT');
  await pump();
  socket.serverSends('ACK-EXCHANGE');
  await pump();
  socket.serverSends(header);
  await pump();
}

void main() {
  group('handshake', () {
    test('walks the full ACK sequence and emits the header packet', () async {
      final socket = FakeSocket();
      final transport = makeTransport(FakeConnector([socket]));
      final packets = <TelemetryPacket>[];
      final states = <TransportState>[];
      transport.packets.listen(packets.add);
      transport.states.listen(states.add);

      await transport.connect();
      await pump();
      expect(transport.state, TransportState.handshaking);

      socket.serverSends('ACK-CONNECT');
      await pump();
      expect(socket.written, ['ACK-CONNECT']);

      socket.serverSends('ACK-EXCHANGE');
      await pump();
      expect(socket.written, ['ACK-CONNECT', 'ACK-EXCHANGE']);

      socket.serverSends(header);
      await pump();
      expect(socket.written.last, 'ACK-COMPLETE');
      expect(transport.state, TransportState.connected);

      final headerPacket = packets.single as HeaderPacket;
      expect(headerPacket.channels.map((c) => c.name), ['alt', 'temp']);
      expect(states, [
        TransportState.connecting,
        TransportState.handshaking,
        TransportState.connected,
      ]);

      await transport.dispose();
    });

    test('handshake timeout tears the session down and retries', () async {
      final silent = FakeSocket();
      final good = FakeSocket();
      final transport = makeTransport(
        FakeConnector([silent, good]),
        handshakeTimeout: const Duration(milliseconds: 30),
      );

      await transport.connect();
      // Wait past the 30 ms handshake timeout plus the 10 ms backoff so the
      // second socket is live, but well before its own timer expires.
      await pump(const Duration(milliseconds: 50));

      expect(silent.closed, isTrue);
      await completeHandshake(good);
      expect(transport.state, TransportState.connected);

      await transport.dispose();
    });
  });

  group('streaming', () {
    test('acknowledges data frames and emits rows', () async {
      final socket = FakeSocket();
      final transport = makeTransport(FakeConnector([socket]));
      final packets = <TelemetryPacket>[];
      transport.packets.listen(packets.add);

      await transport.connect();
      await completeHandshake(socket);

      socket.serverSends("[['1', '2'], ['3', '4']]::ACK(0)");
      await pump();

      expect(socket.written.last, '::ACK(0)');
      final data = packets.whereType<DataPacket>().single;
      expect(data.ackNumber, 0);
      expect(data.rows, [
        ['1', '2'],
        ['3', '4'],
      ]);

      await transport.dispose();
    });

    test('reassembles frames split across TCP chunks', () async {
      final socket = FakeSocket();
      final transport = makeTransport(FakeConnector([socket]));
      final packets = <DataPacket>[];
      transport.packets
          .listen((p) => p is DataPacket ? packets.add(p) : null);

      await transport.connect();
      await completeHandshake(socket);

      socket.serverSends("[['10', '2");
      await pump();
      expect(packets, isEmpty);
      socket.serverSends("0']]::ACK(3)");
      await pump();

      expect(packets.single.rows, [
        ['10', '20'],
      ]);
      expect(socket.written.last, '::ACK(3)');

      await transport.dispose();
    });

    test('handles several frames arriving in one chunk', () async {
      final socket = FakeSocket();
      final transport = makeTransport(FakeConnector([socket]));
      final packets = <DataPacket>[];
      transport.packets
          .listen((p) => p is DataPacket ? packets.add(p) : null);

      await transport.connect();
      await completeHandshake(socket);

      socket.serverSends("[['1']]::ACK(0)[['2']]::ACK(1)");
      await pump();

      expect(packets.map((p) => p.ackNumber), [0, 1]);
      expect(socket.written.sublist(socket.written.length - 2),
          ['::ACK(0)', '::ACK(1)']);

      await transport.dispose();
    });
  });

  group('reconnect', () {
    test('retries with backoff after a failed connection attempt', () async {
      final good = FakeSocket();
      final connector = FakeConnector([], failWhenEmpty: true);
      final transport = makeTransport(connector);
      final errors = <String>[];
      final states = <TransportState>[];
      transport.errors.listen(errors.add);
      transport.states.listen(states.add);

      await transport.connect();
      await pump(const Duration(milliseconds: 25));
      expect(connector.attempts, greaterThan(1));
      expect(errors, isNotEmpty);
      expect(states, contains(TransportState.reconnecting));

      connector.sockets.add(good);
      await pump(const Duration(milliseconds: 100));
      await completeHandshake(good);
      expect(transport.state, TransportState.connected);

      await transport.dispose();
    });

    test('reconnects when the server drops an established session',
        () async {
      final first = FakeSocket();
      final second = FakeSocket();
      final transport = makeTransport(FakeConnector([first, second]));

      await transport.connect();
      await completeHandshake(first);
      expect(transport.state, TransportState.connected);

      await first.serverCloses();
      await pump(const Duration(milliseconds: 60));

      await completeHandshake(second);
      expect(transport.state, TransportState.connected);

      await transport.dispose();
    });
  });

  group('disconnect', () {
    test('stops the transport and prevents reconnects', () async {
      final socket = FakeSocket();
      final connector = FakeConnector([socket], failWhenEmpty: true);
      final transport = makeTransport(connector);

      await transport.connect();
      await completeHandshake(socket);

      await transport.disconnect();
      expect(transport.state, TransportState.disconnected);
      expect(socket.closed, isTrue);

      final attemptsAfterDisconnect = connector.attempts;
      await pump(const Duration(milliseconds: 60));
      expect(connector.attempts, attemptsAfterDisconnect);

      await transport.dispose();
    });
  });

  group('setEndpoint', () {
    test('updates host/port and reconnects the live session', () async {
      final first = FakeSocket();
      final second = FakeSocket();
      final connector = FakeConnector([first, second]);
      final transport = makeTransport(connector);

      await transport.connect();
      await completeHandshake(first);

      await transport.setEndpoint(host: 'new-host', port: 999);
      await pump(const Duration(milliseconds: 60));

      expect(transport.host, 'new-host');
      expect(transport.port, 999);
      expect(first.closed, isTrue);
      await completeHandshake(second);
      expect(transport.state, TransportState.connected);
      expect(connector.attempts, 2);

      await transport.dispose();
    });

    test('only stores the endpoint when not running', () async {
      final connector = FakeConnector([]);
      final transport = makeTransport(connector);

      await transport.setEndpoint(host: 'stored', port: 4321);

      expect(transport.host, 'stored');
      expect(transport.port, 4321);
      expect(connector.attempts, 0);

      await transport.dispose();
    });
  });
}
