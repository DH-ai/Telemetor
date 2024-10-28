import 'dart:convert';
import 'dart:io';
import 'dart:async';
// import 'dart:js_interop';
import 'dart:typed_data'; // for Uint8List

void connectToServer()async{
  Socket socket = await Socket.connect('localhost', 12345);
  print('Connected to server');
  bool ackStatus = false;


  String res = 'choot mara';
  var temp;
  socket.listen(
        (Uint8List data) {
          temp = data;
          res = String.fromCharCodes(data);

          // print('Server: $res');

        },
  );
  while (true)  {
    if (res == 'ACK-CONNECT'){
      print('Server: $res');

      await sendMessage(socket, 'ACK-CONNECT');


    }
    else if (res=="ACK-EXCHANGE"){
      print('Server: $res');
      await sendMessage(socket, 'ACK-EXCHANGE');
      print(res);
      await sendMessage(socket, 'ACK-COMPLETE');

    }
    else{
      print('Server: $res');
      print(temp);
      await Future.delayed(Duration(seconds: 2));



    }

  }
}

Future<void> sendMessage(Socket socket, String message) async {
  print('Client: $message');
  socket.write(message);
  await Future.delayed(Duration(seconds: 2));
}
void main(){

  connectToServer();




}