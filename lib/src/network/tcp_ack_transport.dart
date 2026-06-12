import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'telemetry_transport.dart';
import 'transport_socket.dart';
import 'wire_parser.dart';

enum _HandshakePhase { expectConnect, expectExchange, expectHeader, streaming }

/// [TelemetryTransport] over the frozen TCP+ACK protocol (Backend/ACK.md).
///
/// Handshake:
///   server -> ACK-CONNECT,  client -> ACK-CONNECT
///   server -> ACK-EXCHANGE, client -> ACK-EXCHANGE
///   server -> HEADERS[...]:TYPES[...], client -> ACK-COMPLETE
/// Streaming: frames `[row][row]...::ACK(n)` are each answered `::ACK(n)`.
///
/// The transport keeps itself alive after [connect]: connection failures
/// and drops trigger automatic reconnects with exponential backoff until
/// [disconnect] is called. Incoming bytes are buffered, so frames split or
/// merged by TCP segmentation are handled correctly.
class TcpAckTransport implements TelemetryTransport {
  TcpAckTransport({
    required String host,
    required int port,
    SocketConnector connector = ioSocketConnector,
    this.connectTimeout = const Duration(seconds: 10),
    this.handshakeTimeout = const Duration(seconds: 15),
    this.initialBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
  })  : _host = host,
        _port = port,
        _connector = connector;

  final SocketConnector _connector;
  final Duration connectTimeout;
  final Duration handshakeTimeout;
  final Duration initialBackoff;
  final Duration maxBackoff;

  String _host;
  int _port;

  @override
  String get host => _host;

  @override
  int get port => _port;

  final _stateController = StreamController<TransportState>.broadcast();
  final _packetController = StreamController<TelemetryPacket>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  TransportState _state = TransportState.disconnected;

  @override
  TransportState get state => _state;

  @override
  Stream<TransportState> get states => _stateController.stream;

  @override
  Stream<TelemetryPacket> get packets => _packetController.stream;

  @override
  Stream<String> get errors => _errorController.stream;

  bool _shouldRun = false;
  bool _loopRunning = false;
  TransportSocket? _socket;
  StreamSubscription<List<int>>? _subscription;
  Timer? _handshakeTimer;
  Completer<void>? _sessionDone;
  Duration _backoff = Duration.zero;

  final StringBuffer _rxBuffer = StringBuffer();
  _HandshakePhase _phase = _HandshakePhase.expectConnect;

  static final RegExp _framePattern = RegExp(r'(.*?)::ACK\((\d+)\)');

  @override
  Future<void> connect() async {
    _shouldRun = true;
    if (_loopRunning) return;
    _loopRunning = true;
    _backoff = Duration.zero;
    // Fire and forget: the loop owns the connection until disconnect().
    unawaited(_runLoop());
  }

  @override
  Future<void> disconnect() async {
    _shouldRun = false;
    await _teardownSocket();
    _setState(TransportState.disconnected);
  }

  @override
  Future<void> setEndpoint({String? host, int? port}) async {
    _host = host ?? _host;
    _port = port ?? _port;
    _backoff = Duration.zero;
    if (_shouldRun) {
      // Drop the current session; the run loop reconnects to the new
      // endpoint right away.
      await _teardownSocket();
    }
  }

  Future<void> _runLoop() async {
    while (_shouldRun) {
      if (_backoff > Duration.zero) {
        _setState(TransportState.reconnecting);
        await Future<void>.delayed(_backoff);
        if (!_shouldRun) break;
      }

      _setState(TransportState.connecting);
      try {
        final socket = await _connector(_host, _port, connectTimeout);
        if (!_shouldRun) {
          await socket.close();
          break;
        }
        await _runSession(socket);
      } catch (e) {
        _emitError('Connection to $_host:$_port failed: $e');
      }

      if (_shouldRun) {
        _bumpBackoff();
      }
    }
    _loopRunning = false;
    if (!_shouldRun) {
      _setState(TransportState.disconnected);
    }
  }

  /// Runs one connected session until the socket dies or is torn down.
  Future<void> _runSession(TransportSocket socket) async {
    _socket = socket;
    _rxBuffer.clear();
    _phase = _HandshakePhase.expectConnect;
    _setState(TransportState.handshaking);

    final done = Completer<void>();
    _sessionDone = done;

    _handshakeTimer = Timer(handshakeTimeout, () {
      _emitError('Handshake timed out after ${handshakeTimeout.inSeconds}s');
      unawaited(_teardownSocket());
    });

    _subscription = socket.data.listen(
      (chunk) {
        try {
          _onBytes(utf8.decode(chunk));
        } catch (e) {
          _emitError('Failed to process incoming data: $e');
        }
      },
      onError: (Object e) {
        _emitError('Socket error: $e');
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
      cancelOnError: true,
    );

    await done.future;
    await _teardownSocket();
  }

  void _onBytes(String text) {
    _rxBuffer.write(text);
    var progressed = true;
    while (progressed) {
      progressed = switch (_phase) {
        _HandshakePhase.expectConnect => _consumeToken('ACK-CONNECT', () {
            _send('ACK-CONNECT');
            _phase = _HandshakePhase.expectExchange;
          }),
        _HandshakePhase.expectExchange => _consumeToken('ACK-EXCHANGE', () {
            _send('ACK-EXCHANGE');
            _phase = _HandshakePhase.expectHeader;
          }),
        _HandshakePhase.expectHeader => _consumeHeader(),
        _HandshakePhase.streaming => _consumeDataFrame(),
      };
    }
  }

  /// Consumes [token] from the buffer if present. Returns whether progress
  /// was made.
  bool _consumeToken(String token, void Function() onFound) {
    final buffered = _rxBuffer.toString();
    final index = buffered.indexOf(token);
    if (index < 0) return false;
    _replaceBuffer(buffered.substring(index + token.length));
    onFound();
    return true;
  }

  bool _consumeHeader() {
    final buffered = _rxBuffer.toString();
    final end = WireParser.headerEnd(buffered);
    if (end < 0) return false;
    final channels = WireParser.parseHeader(buffered);
    _replaceBuffer(buffered.substring(end));
    if (channels == null) {
      _emitError('Unparseable header packet: $buffered');
      return false;
    }
    _send('ACK-COMPLETE');
    _packetController.add(HeaderPacket(channels));
    _phase = _HandshakePhase.streaming;
    _handshakeTimer?.cancel();
    _backoff = Duration.zero;
    _setState(TransportState.connected);
    return true;
  }

  bool _consumeDataFrame() {
    final buffered = _rxBuffer.toString();
    final match = _framePattern.firstMatch(buffered);
    if (match == null) return false;
    _replaceBuffer(buffered.substring(match.end));

    final frame = match.group(0)!;
    final parsed = WireParser.parseDataFrame(frame);
    if (parsed == null) {
      // Still acknowledge so the server does not stall on retries.
      final ackNumber = match.group(2)!;
      _send('::ACK($ackNumber)');
      _emitError('Malformed data frame: $frame');
      return true;
    }
    _send('::ACK(${parsed.ackNumber})');
    _packetController
        .add(DataPacket(ackNumber: parsed.ackNumber, rows: parsed.rows));
    return true;
  }

  void _replaceBuffer(String remainder) {
    _rxBuffer.clear();
    _rxBuffer.write(remainder);
  }

  void _send(String message) {
    try {
      _socket?.write(message);
    } catch (e) {
      _emitError('Failed to send "$message": $e');
    }
  }

  void _bumpBackoff() {
    if (_backoff == Duration.zero) {
      _backoff = initialBackoff;
    } else {
      final doubled = _backoff * 2;
      _backoff = Duration(
          milliseconds: min(doubled.inMilliseconds, maxBackoff.inMilliseconds));
    }
  }

  Future<void> _teardownSocket() async {
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      await socket.close();
    }
    final done = _sessionDone;
    _sessionDone = null;
    if (done != null && !done.isCompleted) {
      done.complete();
    }
  }

  void _setState(TransportState next) {
    if (_state == next) return;
    _state = next;
    _stateController.add(next);
  }

  void _emitError(String message) {
    if (_errorController.hasListener) {
      _errorController.add(message);
    }
  }

  /// Releases all resources. The transport cannot be reused afterwards.
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _packetController.close();
    await _errorController.close();
  }
}
