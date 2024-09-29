

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:async';
import 'package:csv/csv.dart';


void main (){
  runApp(const MyApp());
}

//

class MyApp extends StatelessWidget{


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


class MyHomePage extends StatelessWidget{
  final String title;
  const MyHomePage({super.key,required this.title});

  @override
  Widget build(BuildContext context){
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
      color:Theme.of(context).primaryColor,

      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(title),
        ),

        body:Row(
          children: [
            Expanded( // side bar
              child: Container(
                color: Colors.blue,
                margin: const EdgeInsets.all(10),
              ),
            ),
            Expanded(
              flex:4,
              child: Column(
                children: [
                  Expanded(// top bar
                    child: Container(
                      color: Colors.black,
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(20),
                      child: AltitudeChart(),

                    ),
                  ),
                  Expanded( // bottom bar
                    child: Container(
                      color: Colors.green,
                      margin: const EdgeInsets.all(10),

                    ),
                  ),
                ]
              )
            )
          ],

        ),

      ),

    );
  }
  List<FlSpot> x3func(){
    List <FlSpot> x3 = [];
    for (int i=0;i<10;i++){
      x3.add(FlSpot(i.toDouble(), i.toDouble()*i.toDouble()*i.toDouble()));
    }
    for (int i=10;i<20;i++){
      x3.add(FlSpot(i.toDouble(), 10*10*10*2-1*i.toDouble()*i.toDouble()*i.toDouble()));

    }
    return x3 ;
  }


}

class AltitudeChart extends StatefulWidget {

  const AltitudeChart({super.key});
  @override
  State<AltitudeChart> createState() => _AltitudeChartState();
}
class _AltitudeChartState extends State<AltitudeChart> {
  List



}


  @override
  Widget build(BuildContext context) {
    return LineChart(

      LineChartData(
          // minX: -100,
          // maxX: 30,30
          // minY: -100,
          // maxY: 100,
          // gridData: FlGridData(show: false), for the grid

          titlesData: const FlTitlesData(
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        lineBarsData: [LineChartBarData(
          spots: [FlSpot(1, 1)],
          color: Colors.red,
          // isStepLineChart: true,
          barWidth: 1,
          dotData: const FlDotData(show: false),
        ),
        ],
        backgroundColor: Colors.black



      ),


    );
  }
}