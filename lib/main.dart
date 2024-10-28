import 'package:flutter/material.dart';

// import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:async';
import 'csv_parser.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:ffi';
import 'dart:core';
import 'package:csv/csv.dart';
import 'package:logger/logger.dart';
import 'dart:typed_data'; // for Uint8List

/*
*Map for longitudnal and latitudnal Google Maps Api
*
*/
var logger =Logger() ;

void main() {
  runApp(const MyApp());
  var netobj=NetworkHandler();
  netobj.connectToServer();
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(

        child:ClipRect(

          child: Container(
            constraints: const BoxConstraints(
              minWidth: 400, // Set your minimum width
              minHeight: 600,

            ),
            child: const AppClass(),
          ),
        )

    );
  }
}

class AppClass extends StatelessWidget {
  const AppClass({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:LayoutBuilder(
          builder: (context,constraints ) {
            return Container(
              constraints: const BoxConstraints(
                minWidth: 400, // Set your minimum width
                minHeight: 600, // Set your minimum height
              ),
              child: const MyHomePage(title: 'T E L E M E T O R'),

            );
          }

    ),
    );
  }
}


class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),\
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff1e1e1e),
          // Need to make a statefull appBar for status, packets and various information to be displayed
          centerTitle: true,
          title: Text(title),
        ),
        body: RowApp(),
        backgroundColor: Color(0xff424242),
      ),
    );
  }

  List<FlSpot> x3func() {
    List<FlSpot> x3 = [];
    for (int i = 0; i < 10; i++) {
      x3.add(FlSpot(i.toDouble(), i.toDouble() * i.toDouble() * i.toDouble()));
    }
    for (int i = 10; i < 20; i++) {
      x3.add(FlSpot(i.toDouble(),
          10 * 10 * 10 * 2 - 1 * i.toDouble() * i.toDouble() * i.toDouble()));
    }
    return x3;
  }
}
class TopHeader extends AppBar{
  TopHeader({super.key, required String title}):super(title: Text(title),centerTitle: true);

}
class RowApp extends StatelessWidget {
  const RowApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      AspectRatio(
        aspectRatio: 3 / 10,
        child: Container(
          decoration:  BoxDecoration(
            color: Color(0xff212121),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(0xff212121), width: 2),




          ),
          // padding: EdgeInsets.all(10),
          margin: EdgeInsets.all(10),
          alignment: Alignment.centerLeft,
          constraints: const BoxConstraints(
            minWidth: 200,
            minHeight: 600,
          ),


          // color: Color(0xff1e1e1e),
          // margin: const EdgeInsets.Rall(10),
          child: Dashboard(),
        ),
      ),
      Expanded(

        child: Container(
          color: Color(0xff1e1e1e),
          margin: const EdgeInsets.all(40),
          child: Container(
              // margin: const EdgeInsets.all(10),
              child: CharMainScreen()),
        ),
      ),
    ]);
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Flexible(
        child:Container(
            constraints:const BoxConstraints(
              minWidth: 200,
              minHeight: 200,
            ),

            // height: 200,
            // width: 200,
            // color: Colors.black,
            child: const Text(
                style: TextStyle(color: Color(0xff1ccc9d)), 'Hello World'),

    ));
  }
}
// this is our main screen where ALtitude , Temperature, Velocity, Accelerattion, Gyroscope Values as of now

class CharMainScreen extends StatelessWidget {
  const CharMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Expanded(

        child: Column(children: <Widget>[

      Expanded(
        flex: 2,
        child: Row(
          children: <Widget>[
            Expanded(

              child: Container(
                child: AspectRatio(aspectRatio: 16/15,child: Altitude(),) ,
              ),
            ),
            Expanded(
              child: AspectRatio(aspectRatio: 16/15,child: Temperature(),)
            ),
            Expanded(
              child: AspectRatio(aspectRatio: 16/15,child: Velocity(),)
            ),
          ],
        ),
      ),
      Expanded(
        flex: 3,
        child: Row(
          children: <Widget>[
            Expanded(
              child: AspectRatio(aspectRatio: 16/13,child: Gyroscope(),)
            ),
            Expanded(
              child: AspectRatio(aspectRatio: 16/13,child: Acceleration(),) ,
            ),
          ],
        ),
      ),
    ]));
  }
}

class Altitude extends StatelessWidget {
  const Altitude({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      width: 10,
      margin: const EdgeInsets.all(10),
      // color: Colors.red,
      child:  SizedBox(

        child: SizedBox(
          height: 10,
          width: 10,
          child: Container(
            margin: const EdgeInsets.all(10),
            height: 10,
            width: 10,
            color: Colors.black,

          ),

        ),

      ),
      // AccelerationChart(),
    );
  }
}

class Temperature extends StatelessWidget {
  const Temperature({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Colors.black,
      child: const SizedBox(
        height: 200,
        width: 200,

      ),
      // AccelerationChart(),
    );
  }
}

class Velocity extends StatelessWidget {
  const Velocity({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Colors.black,
      child: const SizedBox(
        height: 200,
        width: 200,

      ),
      // AccelerationChart(),
    );
  }
}

class Acceleration extends StatelessWidget {
  const Acceleration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Color(0xff000000),
      child: const SizedBox(
        height: 200,
        width: 200,

      ),
      // AccelerationChart(),
    );
  }
}

class Gyroscope extends StatelessWidget {
  const Gyroscope({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Colors.black,
      child: const SizedBox(
        height: 200,
        width: 200,
        child: Text('Gyroscope'),


      ),
      // AccelerationChart(),
    );
  }
}

class AltitudeChart extends StatefulWidget {
  const AltitudeChart({super.key});

  @override
  State<AltitudeChart> createState() => _AltitudeChartState();
}

class _AltitudeChartState extends State<AltitudeChart> {
  final List<FlSpot> _datapoints = [];

  final String filePath = 'D:/Obfuscation/telemetor/Backend/rocket.csv';

  // time coloumn
  // altitude column
  // final data = CsvHandler().readCsv(_AltitudeChartState().filePath);
  int _currentIndex = 2;

  late List<List<dynamic>> _csvData;
  double _time = 0;
  double _altitude = 0;
  double? y_min = -10;

  double? y_max = 3000;

  double? x_min = 100;

  double? x_max = 40000;

  @override
  void initState() {
    super.initState();
    _loadData();

    // _startTimer();
  }

  Future<void> _loadData() async {
    _csvData = await CsvHandler().readCsv(filePath);

    _startTimer();
  }

  void _startTimer() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_currentIndex < _csvData.length) {
          if (_csvData[_currentIndex][0] == _csvData[1][0]) {
            _currentIndex++;
          } else {
            // print("${timer.tick}  $_currentIndex ${_csvData[_currentIndex][4]}");
            _time = double.parse(_csvData[_currentIndex][1].toString()) -
                double.parse(_csvData[14][1].toString()) +
                1;
            _altitude = double.parse(_csvData[_currentIndex][4].toString());
            y_max = max(y_max!, _altitude);
            y_min = min(y_min!, _altitude);
            x_max = max(x_max!, _time);
            x_min = min(x_min!, _time);
            _datapoints.add(FlSpot(_time, _altitude));
            _currentIndex++;
          }
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        // gridData: const FlGridData(show: false), no grids
        // borderData: FlBorderData(show: true),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minX: x_min!,
        maxX: x_max!,
        minY: y_min!,
        maxY: y_max!,
        lineBarsData: [
          LineChartBarData(
            spots: _datapoints,
            isCurved: true,
            color: Colors.red,
            barWidth: 1,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),

            // isStrokeCapRound: true,
          ),
        ],
      ),
    );
  }
}

class CsvHandler {
  // Read CSV file and return List of Maps
  Future<List<List<dynamic>>> readCsv(String filePath) async {
    final input = File(filePath).openRead();
    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    // // first 2 rows are headers
    //
    // final header1 = fields[0].map((header) => header.toString()).toList();
    // final header2 = fields[1].map((header) => header.toString()).toList();
    // final type1 = fields[0][0].toString();
    // final type2 = fields[1][0].toString();
    //
    // List<List> csvData = [];
    //
    // for (int iter = 2; iter < fields.length; iter++) {
    //   var row = fields[iter].map((row) => row.toString()).toList();
    //   csvData.add(row);
    // }

    return fields;
  }

// Write data to CSV file
// Future<void> writeCsv(String filePath, List<List<dynamic>> data) async {
//   String csv = const ListToCsvConverter().convert(data);
//   final file = File(filePath);
//   await file.writeAsString(csv);
// }

// Append data to an existing CSV file
// Future<void> appendCsv(String filePath, List<List<dynamic>> data) async {
//   String csv = const ListToCsvConverter().convert(data);
//   final file = File(filePath);
//   await file.writeAsString(csv, mode: FileMode.append);
// }
}

class Packets{
  /*
  * 1. Header
  * 2. Type
  * 3. Data
   */
  late List<String> headers;
  late List<String> types;
  late String data;
  Packets({required this.data});

}
class NetworkHandler{
  // Responsible for handling the network
  /*
  * 1.Establish and manage socket connections.
  * 2. Timeouts
  * 3. Error Handling
  * 4. Retry Mechanism
  * 5. ACK mechanism
  * 6. Handling Incoming Outgoing data
  * 7. Add Incoming Packet to Buffer
  * 8. logging useful events
  *
  * */
  bool ackStatus = false;
  late Packets packet ;

  Future<Socket> connectToServer()async {
    Socket socket = await Socket.connect('localhost', 12345);
    logger.i('Connected to server');
    late String res='' ;
    socket.listen(
          (Uint8List data) {
        res = String.fromCharCodes(data);
        logger.i('Server: $res');
      },
    );
    final data = await _receiveData(socket);
    if (data == 'ACK-CONNECT'){
      logger.i('Server: $data');
      await sendMessage(socket, 'ACK-CONNECT');
      print("dsadsa");
      // Step 2: Wait for ACK-EXCHANGE
      final exchangeResponse = await _receiveData(socket);
      if (exchangeResponse=="ACK-EXCHANGE"){
        // logger.i('Server: $exchangeResponse');
        await sendMessage(socket, 'ACK-EXCHANGE');
        final res = await _receiveData(socket);
        logger.i('Server: $res');
        var temp = _processPacket(res);
        logger.i('Server: $temp');
        await sendMessage(socket, 'ACK-COMPLETE');





      }
      else{
          logger.i('Server: ${_receiveData(socket)} ');
      }

    }
    return socket;
  }
  List<E> _processPacket<E>(String packet){
    final regex = RegExp(r'HEADERS\{([^}]*)\}:TYPES\{([^}]*)\}');
    final match = regex.firstMatch(packet);
    final headers = match?.group(1);
    final types = match?.group(2);
    return [headers, types] as List<E>;
  }
  Future<void> sendMessage(Socket socket, String message) async {
    logger.i('Sending: $message');
    socket.write(message);
    await Future.delayed(Duration(seconds: 2));
  }
  Future<String> _receiveData(Socket serverSocket) async {
    final response = await serverSocket.first;
    return utf8.decode(response);
  }
}
class PacketHandler{
  // To-do
  /*
  * 1. Reading packet info from the buffer
  * 2. For each packet create meaningful data
  * 3. methods for handling the packet data graceful
  * 4. error management
  * */
  late List<String> header;
  late List<String> type;
  PacketHandler({required this.header, required this.type});
}
