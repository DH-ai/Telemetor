import 'package:flutter/material.dart';

// import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:async';
import 'csv_parser.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:core';
import 'package:csv/csv.dart';

/*
*Map for longitudnal and latitudnal Google Maps Api
*
*/

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telemetor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const MyHomePage(title: 'Telemetor'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
      color: Theme.of(context).primaryColor,
      child: Scaffold(
        appBar: AppBar(
          // Need to make a statefull appBar for status, packets and various information to be displayed
          centerTitle: true,
          title: Text(title),
        ),
        body: const Padding(
          padding: EdgeInsets.fromLTRB(10, 10, 70, 10),
          child: RowApp(),
        ),
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
          color: Theme.of(context).primaryColor,
          margin: const EdgeInsets.all(10),
          child: Dashboard(),
        ),
      ),
      Expanded(
        child: Container(
          color: Theme.of(context).primaryColor,
          margin: const EdgeInsets.all(10),
          child: Container(
              margin: const EdgeInsets.all(10), child: CharMainScreen()),
        ),
      ),
    ]);
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // AltitudeChart(),
        Expanded(
          child: Container(
            // height: 200,
            width: 200,
            child: const Text(
                style: TextStyle(color: Color(0xFFc2255c)), 'Hello World'),
            color: Colors.blue,
          ),
        ),
      ],
    );
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
        child: Row(
          children: <Widget>[
            Expanded(

              child: Container(
                child: AspectRatio(aspectRatio: 16/15,child: Altitude(),) ,
              ),
            ),
            Expanded(
              child: Temperature(),
            ),
            Expanded(
              child: Velocity(),
            ),
          ],
        ),
      ),
      Expanded(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Acceleration(),
            ),
            Expanded(
              child: Gyroscope(),
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
      margin: const EdgeInsets.all(10),
      child: AltitudeChart(),
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
      child: AltitudeChart(),
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
      child: AltitudeChart(),
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
      child: AltitudeChart(),
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
      child: AltitudeChart(),
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
  late List<String> Headers;
  late List<String> Types;
  Packets(this.Headers, this.Types);

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
}
class PacketHandler{
  // To-do
  /*
  * 1. Reading packet info from the buffer
  * 2. For each packet create meaningful data
  * 3. methods for handling the packet data graceful
  * 4. error management
  * */
}
