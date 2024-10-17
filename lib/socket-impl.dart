import 'dart:io';

void main() async {
  // Connect to the server
  final socket = await Socket.connect('localhost', 12345);
  print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

  // Send data to the server
  socket.writeln('Hello, Server!');

  // Listen for responses from the server
  socket.listen(
    (data) {
      print('Server: ${String.fromCharCodes(data).trim()}');
    },
    onDone: () {
      print('Server closed the connection');
      socket.destroy();
    },
  );
}
