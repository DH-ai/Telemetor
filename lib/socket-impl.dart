import 'dart:convert';
import 'dart:io';
import 'dart:async';


void connectToServer()async{
  Socket socket = await Socket.connect('localhost', 12345);
  print('Connected to server');
  var ACKSTATUS = false;



  socket.listen((List<int> event) {
    var data = utf8.decode(event);
    switch(data){
      case 'ACK-CONNECT':
        socket.write('ACK-CONNECT');
        break;
      case 'ACK-EXCHANGE':
        socket.write('ACK-EXCHANGE');
        break;
      default:
        print('Server: $data');
        ACKSTATUS = true;
        break;

    }
    if (ACKSTATUS){
      socket.write('ACK-COMPLETE');
    }

  });



}


void main(){

  connectToServer();




}