import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';




void main () {
  final data = dataCsv();
  List<List> csvData ;
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