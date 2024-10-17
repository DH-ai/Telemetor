import 'dart:io';
import 'dart:async';
// Future<String> fetchData() async {
//   await Future.delayed(Duration(seconds: 1));
//   return 'Data fetched!';
// }
//
// void main() {
//   fetchData().then((data) {
//     print(data);
//     return 'Processing complete!';
//   }).then((message) {
//     print("${message}sasa");
//   }).catchError((error) {
//     print('An error occurred: $error');
//   });
// }\

// Possible options we have
// 1. Use a StreamController

void main() {
  // Creating a stream controller
  final controller = StreamController<String>();

  // Listening to the stream
  controller.stream.listen((data) {
    print('Received: $data');
  });

  // Adding data to the stream
  controller.add('Hello');
  controller.add('World');

  controller.close(); // Close the stream to avoid memory leaks
}
