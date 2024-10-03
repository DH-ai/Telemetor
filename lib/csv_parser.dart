import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:core';
import 'package:csv/csv.dart';





void main () {
  final data = dataCsv();
  List<List> csvData=[] ;
  data.then(
    (value) {
      csvData = value;
      // print(csvData);
    }
  ).whenComplete(
    () {

      print("done");

    }
  );
  (data as Future).then((value){
    List<int> nullRow = nullChecker(value[0]);

  });
}

Future<List<List<dynamic>>> dataCsv() async {
  final input =   File('D:/Obfuscation/telemetor/Backend/rocket.csv').openRead();


  final fields = await input
      .transform(utf8.decoder)
      .transform(const CsvToListConverter())
      .toList();
  // time
  fields[0][1]=' time';
  // print(fields[0]);
  return fields;

}

List<int> nullChecker(List<int> data) {
  List<int> rowNum= [];
  for (int i = 0; i < data.length; i++) {
    if (data[i] == null) {
      rowNum.add(i);
    }
  }
  return rowNum;
}