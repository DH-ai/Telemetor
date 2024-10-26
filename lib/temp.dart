import 'dart:io';
import 'dart:typed_data';

// regex""
/*
* \[([^}]*)\]
*
*void main() {
  String text = "HEADERS{header1,header2,header3}:TYPES{type1,type2,type3}";

  // Create a regular expression to match the pattern
  RegExp regex = RegExp(r'HEADERS\{([^}]*)\}:TYPES\{([^}]*)\}');

  // Use the firstMatch method to find matches
  RegExpMatch? match = regex.firstMatch(text);

  if (match != null) {
    // Group 1 captures headers, Group 2 captures types
    String headersPart = match.group(1)!;
    String typesPart = match.group(2)!;

    // Convert the comma-separated values into lists
    List<String> headers = headersPart.split(',');
    List<String> types = typesPart.split(',');

    print("Headers: $headers");
    print("Types: $types");
  } else {
    print("No match found.");
  }
}

*
*
* */



void main() async {

  // connect to the socket server
  final socket = await Socket.connect('localhost', 4567);
  print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

  // listen for responses from the server
  socket.listen(

    // handle data from the server
        (Uint8List data) {
      final serverResponse = String.fromCharCodes(data);
      print('Server: $serverResponse');
    },

    // handle errors
    onError: (error) {
      print(error);
      socket.destroy();
    },

    // handle server ending connection
    onDone: () {
      print('Server left.');
      socket.destroy();
    },
  );

  // send some messages to the server
  await sendMessage(socket, 'Knock, knock.');
  await sendMessage(socket, 'Banana');
  await sendMessage(socket, 'Banana');
  await sendMessage(socket, 'Banana');
  await sendMessage(socket, 'Banana');
  await sendMessage(socket, 'Banana');
  await sendMessage(socket, 'Orange');
  await sendMessage(socket, "Orange you glad I didn't say banana again?");
}

Future<void> sendMessage(Socket socket, String message) async {
  print('Client: $message');
  socket.write(message);
  await Future.delayed(Duration(seconds: 2));
}