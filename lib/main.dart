

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
                      color: Colors.red,
                      margin: const EdgeInsets.all(10),
                      child: LineChart(
                        LineChartData(

                        ),
                      ),

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
}