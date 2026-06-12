import 'package:flutter/material.dart';

import 'src/network/network_handler.dart';
import 'src/screens/home_screen.dart';

const String socketHost = '127.0.0.1';
const int socketPort = 12345;

void main() {
  runApp(const TelemetorApp());
  NetworkHandler(host: socketHost, port: socketPort).connect();
}

class TelemetorApp extends StatelessWidget {
  const TelemetorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Telemetor',
      home: HomeScreen(title: 'T E L E M E T O R'),
    );
  }
}
