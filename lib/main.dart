import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/data/telemetry_hub.dart';
import 'src/network/network_handler.dart';
import 'src/screens/home_screen.dart';

const String socketHost = '127.0.0.1';
const int socketPort = 12345;

void main() {
  final hub = TelemetryHub();
  runApp(TelemetorApp(hub: hub));
  NetworkHandler(host: socketHost, port: socketPort, hub: hub).connect();
}

class TelemetorApp extends StatelessWidget {
  const TelemetorApp({super.key, required this.hub});

  final TelemetryHub hub;

  @override
  Widget build(BuildContext context) {
    return Provider<TelemetryHub>.value(
      value: hub,
      child: const MaterialApp(
        title: 'Telemetor',
        home: HomeScreen(title: 'T E L E M E T O R'),
      ),
    );
  }
}
