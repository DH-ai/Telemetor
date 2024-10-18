import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data'; // for Uint8List

void connectToServer()async{
  Socket socket = await Socket.connect('localhost', 12345);
  print('Connected to server');
  bool ackStatus = false;


  String res = '';

  socket.listen(
      (Uint8List data) {
        res = String.fromCharCodes(data);
        // print('Server: $res');

      },
  );
  print(res);


}


void main(){

  connectToServer();




}