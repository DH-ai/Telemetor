import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:async';
import 'package:csv/csv.dart';
import 'dart:math';

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
          centerTitle: true,
          title: Text(title),
        ),
        body: const Padding(
    padding: EdgeInsets.fromLTRB(10,10,70,10),
    child:  RowApp(),
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
    return Row(

      children: [
        Expanded(
          // side bar
          child: Container(
            color: Theme.of(context).primaryColor,
            margin: const EdgeInsets.all(10),
          ),
        ),
        Expanded(
            flex: 4,
            child: Column(children: [
              Expanded(
                // top bar
                child:  Container(
                  // color: Colors.black,
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          // color: Colors.black,
                          margin: const EdgeInsets.all(10),
                          // padding: const EdgeInsets.all(20),
                          child: const AltitudeChart(),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          // color: Colors.black,
                          margin: const EdgeInsets.all(10),
                          // padding: const EdgeInsets.all(20),
                          child: const AltitudeChart(),
                        ),
                      ),
                    ],
                  ),

                ),
              ),
              Expanded(
                // bottom bar
                child: Container(
                  color: Theme.of(context).primaryColor,
                  margin: const EdgeInsets.all(10),
                  child: const AltitudeChart(),
                ),
              ),
            ]))
      ],
    );
  }
}

class AltitudeChart extends StatefulWidget {
  const AltitudeChart({super.key});
  @override
  State<AltitudeChart> createState() => _AltitudeChartState();
}

class _AltitudeChartState extends State<AltitudeChart> {
  final List<FlSpot> _datapoints = [const FlSpot(0, 0)];

  double _time = 0;
  double? y_max = 10;
  double? y_min = 10;

  double _altitudeValues(double time) {
    return (time*sin(time)).toDouble() / 5;
  }

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _time += 1;
        // print(_time);
        double altVal = _altitudeValues(_time);
        _datapoints.add(FlSpot(_time, altVal));
        y_max = y_max ?? altVal;
        y_max = max(y_max!, altVal);
        y_min = y_min ?? altVal;
        y_min = min(y_min!, altVal);
        if (_time > 90) {
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
        minX: 0,
        maxX: 100,
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






