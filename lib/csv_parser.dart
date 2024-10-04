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
  );
  (data as Future).then((value){
    List<List<int>> nullRow = [];
    print(int.parse((value[0][18]).toString()));
    for ( int i = 0; i < value.length; i++) {
      nullRow.add(nullChecker(value[i]));
    }
    print("done");
    // print(nullRow)




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

List<int> nullChecker(List<dynamic> data) {
  List<int> rowNum= [];
  for (int i = 0; i < data.length; i++) {
    if (data[i] == ' time') {
      rowNum.add(i);
    }
  }
  return rowNum;
}