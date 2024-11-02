import 'dart:collection';

import 'package:flutter/material.dart';

// import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:async';
import 'csv_parser.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:ffi';
import 'dart:async';
import 'dart:core';
import 'package:csv/csv.dart';
import 'package:logger/logger.dart';
import 'dart:typed_data'; // for Uint8List

/*
*Map for longitudnal and latitudnal Google Maps Api
* BUGS
*   1. The header is coming inside the queue on first run not after restart for some reason
*/
var Header;
var Type;
const SocketHost = '127.0.0.1';
const SocketPort = 12345;
var logger = Logger();

Queue<String> dataQueue = Queue<String>();

void main() {
  runApp(const MyApp());
  var networkHandler = NetworkHandler(host: SocketHost, port: SocketPort);
  networkHandler.connect();
}

Future<void> printvalue() async {
  while (true) {
    if (dataQueue.isNotEmpty) {
      print(dataQueue.removeFirst());
    }
    await Future.delayed(Duration(seconds: 1));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ClipRect(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 400, // Set your minimum width
          minHeight: 600,
        ),
        child: const AppClass(),
      ),
    ));
  }
}

class AppClass extends StatelessWidget {
  const AppClass({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LayoutBuilder(builder: (context, constraints) {
        return Container(
          constraints: const BoxConstraints(
            minWidth: 400, // Set your minimum width
            minHeight: 600, // Set your minimum height
          ),
          child: const MyHomePage(title: 'T E L E M E T O R'),
        );
      }),
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

class TopHeader extends AppBar {
  TopHeader({super.key, required String title})
      : super(title: Text(title), centerTitle: true);
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
          decoration: BoxDecoration(
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
        child: Container(
      constraints: const BoxConstraints(
        minWidth: 200,
        minHeight: 200,
      ),

      // height: 200,
      // width: 200,
      // color: Colors.black,
      child:
          const Text(style: TextStyle(color: Color(0xff1ccc9d)), 'Hello World'),
    ));
  }
}
// this is our main screen where ALtitude , Temperature, Velocity, Accelerattion, Gyroscope Values as of now

class CharMainScreen extends StatelessWidget {
  CharMainScreen({super.key}) {
    dataProvider();
  }

  final queue = dataQueue;
  StreamController<List<int>> streamController = StreamController<List<int>>();

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(children: <Widget>[
      Expanded(
        flex: 2,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                child: AspectRatio(
                  aspectRatio: 16 / 15,
                  child: Altitude(),
                ),
              ),
            ),
            Expanded(
                child: AspectRatio(
              aspectRatio: 16 / 15,
              child: Temperature(stream: streamController),
            )),
            Expanded(
                child: AspectRatio(
              aspectRatio: 16 / 15,
              child: Velocity(),
            )),
          ],
        ),
      ),
      const Expanded(
        flex: 3,
        child: Row(
          children: <Widget>[
            Expanded(
                child: AspectRatio(
              aspectRatio: 16 / 13,
              child: Gyroscope(),
            )),
            Expanded(
              child: AspectRatio(
                aspectRatio: 16 / 13,
                child: Acceleration(),
              ),
            ),
          ],
        ),
      ),
    ]));
  }

  void dataProvider() async {
    while (true) {
      if (queue.isNotEmpty) {
        var temp = queue.removeFirst();
        List<int> tempInt = [];
        RegExp reg = RegExp(r'\b(\d{2})\b');
        var match = reg.allMatches(temp);
        for (var i in match) {
          tempInt.add(int.parse(i.group(0)!));
        }
        streamController.add(tempInt);
      }
      await Future.delayed(Duration(seconds: 2));
    }
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
      child: SizedBox(
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
  StreamController<List<int>> stream;

  Temperature({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
        stream: stream.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            logger.i(snapshot.data);
            // logger.i(snapshot.);
            Future.delayed(Duration(seconds: 2));
            return Container(
              margin: const EdgeInsets.all(10),
              color: Colors.black,
              child: SizedBox(
                height: 200,
                width: 200,
                child:
                    AltitudeChart(x: snapshot.data![0], y: snapshot.data![1]),
              ),
              // AccelerationChart(),
            );
          } else {
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
        });
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

// 1. passing the data
// 2. passing the respective x and y index to its respective chart ex(acc vs time)
// 3. title
// 4. x and y indexes actually
// 5. able to plot multiple charts in single chart
// 6. legend option
// 7. color option

class DataPlotterClass extends StatefulWidget {
  final List<List<dynamic>> data;
  final int xIndex;
  final List<int> yIndex;
  final String title;
  final bool legend;

  //will look into it later
  const DataPlotterClass(
      {super.key,
      required this.data,
      required this.xIndex,
      required this.yIndex,
      required this.title,
      required this.legend});

  @override
  State<DataPlotterClass> createState() => _DataPlotterClassState();
}

class _DataPlotterClassState extends State<DataPlotterClass> {
  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Hello World'),
    );
  }
}

class AltitudeChart extends StatefulWidget {
  int x;
  int y;

  AltitudeChart({super.key, required this.x, required this.y});

  @override
  State<AltitudeChart> createState() => _AltitudeChartState(x, y);
}

class _AltitudeChartState extends State<AltitudeChart> {
  final List<FlSpot> _datapoints = [];
  final List<FlSpot> _datapoints2 = [];
  var x;
  var y;
  final String filePath = 'D:/Obfuscation/telemetor/Backend/rocket.csv';

  _AltitudeChartState(this.x, this.y);

  double y_min = 0;
  double y_max = 100;
  double x_min = 0;
  double x_max = 100;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _datapoints.add(FlSpot(x.toDouble(), y.toDouble()));
        // print(_datapoints);
      });
    });

    // _startTimer();
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
        minX: x_min,
        maxX: x_max,
        minY: y_min,
        maxY: y_max,
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
          // LineChartBarData(
          //   spots: _datapoints2,
          //   isCurved: true,
          //   color: Colors.blueGrey,
          //   barWidth: 1,
          //   isStrokeCapRound: true,
          //   dotData: const FlDotData(show: false),
          //
          //   // isStrokeCapRound: true,
          // )
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

class Packets {
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

class NetworkHandler {
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
  late Packets packet;
  final String host;
  final int port;
  final timeout = 10;

  NetworkHandler({required this.host, required this.port});

  Future<void> connect() async {
    // socket object
    final serverSocket = await Socket.connect(host, port);

    logger.i(
        'Connected to: ${serverSocket.remoteAddress.address}:${serverSocket.remotePort}');

    // Acknowledgement

    logger.i('ACKNOWLEDGEMENT Started');
    await Future.delayed(Duration(seconds: 2));
    try {
      await acknowledge(serverSocket);
      logger.i('Acknowledgement Completed');
      logger.i("Initializing data transfer");

      //now here i want to make a function call to the function that will recive the continous data and broadcast it to the respective widgets

      ackStatus = true;
    } catch (e) {
      logger.e('Acknowledgement Failed $e');

      logger.e("retrying.....");
      Future.delayed(Duration(seconds: 3));
    }
  }

  Future<bool> acknowledge(Socket socket) async {
    // Acknowledgement
    bool ackstatus = false;
    var last_ack;
    logger.i("Socket.listen()");
    await Future.delayed(Duration(seconds: 2));

    socket.listen((Uint8List data) async {
      if (ackstatus) {
        var dataNew = utf8.decode(data);

        //        \[(.*?)\]::ACK\((\d+)\) to extract the ack number and data
        //        \[(.*?)\] \\ to de group the data
        RegExp reg1 = RegExp(r'\[(.*?)\]::ACK\((\d+)\)');
        RegExp reg2 = RegExp(r'\[(.*?)\]');
        final match1 = reg1.firstMatch(dataNew);
        String? dataString = match1?.group(1);

        int? AckNum = int.parse((match1?.group(2))!);
        sendMessage(socket, '::ACK($AckNum)');
        final match2 = reg2.allMatches(dataString!);
        List<dynamic> dataVal = [];
        for (var match in match2) {
          dataQueue.add((match.group(1)!));
        }
      } else {
        final ack = utf8.decode(data);
        logger.i('Received: $ack Now wait 10 seconds');
        await Future.delayed(Duration(seconds: 10));

        if (ack == 'ACK-CONNECT') {
          sendMessage(socket, 'ACK-CONNECT');
          last_ack = ack;
        } else if (ack == 'ACK-EXCHANGE') {
          sendMessage(socket, 'ACK-EXCHANGE');
          last_ack = ack;
        } else if (ack.contains("HEAD") && last_ack == 'ACK-EXCHANGE') {
          RegExp regex = RegExp(r'HEADERS\[([^}]+)\]:TYPES\[([^}]+)\]');
          final match = regex.firstMatch(ack);
          final headers = match?.group(1);
          final types = match?.group(2);
          logger.i('Received: $headers');
          logger.i('Received: $types');
          sendMessage(socket, 'ACK-COMPLETE');
          ackstatus = true;
          // ReciveMessages(socket, headers!, types!);
          // subscription?.cancel(); // i cannot do this -_-
          logger.i("Stream closed");
          // data process

          // exit listen loop
        } else {
          logger.e('Acknowledgement Failed: Server sent $ack');
          logger.i("Retrying....");
        }
      }
    });

    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // print("JEJALDJSALKJDLSAJDLSJALKJKLSJDKJSAKDJLKASJDLSALDJASLJDASJDLASKDJ");
    // if (await _receiveData(socket) == 'ACK-CONNECT') {
    //   await sendMessage(socket, 'ACK-CONNECT');
    //   print(socket.last); //
    //   print(await _receiveData(socket)); // need to figure out alternative for this
    //   ackstatus = true;
    // } else {
    //   logger.e('Acknowledgement Failed');
    // }
    // Future.delayed(Duration(seconds: 2));

    return ackstatus;
  }

  Future<void> handleMessages(Socket socket, headers, types) async {
    logger.i("Handling Messages");
    Future.delayed(Duration(seconds: 15));
  }

  List<E> _processPacket<E>(String packet) {
    final regex = RegExp(r'HEADERS\{([^}]*)\}:TYPES\{([^}]*)\}');
    final match = regex.firstMatch(packet);
    final headers = match?.group(1);
    final types = match?.group(2);
    return [headers, types] as List<E>;
  }

  Future<void> sendMessage(Socket socket, String message) async {
    // logger.i('Sending: $message');
    socket.write(message);
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<String> _receiveData(Socket serverSocket) async {
    final response = await serverSocket.first;

    return utf8.decode(response);
  }
}

class PacketHandler {
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
