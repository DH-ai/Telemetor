import 'dart:io';

/// Minimal socket abstraction so transports can be unit-tested with fakes.
abstract interface class TransportSocket {
  Stream<List<int>> get data;

  void write(String message);

  Future<void> close();
}

/// Creates a connected [TransportSocket] or throws on failure/timeout.
typedef SocketConnector = Future<TransportSocket> Function(
    String host, int port, Duration timeout);

/// Production connector backed by dart:io.
Future<TransportSocket> ioSocketConnector(
    String host, int port, Duration timeout) async {
  final socket = await Socket.connect(host, port, timeout: timeout);
  return _IoTransportSocket(socket);
}

class _IoTransportSocket implements TransportSocket {
  _IoTransportSocket(this._socket);

  final Socket _socket;

  @override
  Stream<List<int>> get data => _socket;

  @override
  void write(String message) => _socket.write(message);

  @override
  Future<void> close() async {
    _socket.destroy();
  }
}
