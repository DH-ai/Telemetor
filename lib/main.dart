import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/data/telemetry_hub.dart';
import 'src/data/transport_hub_binding.dart';
import 'src/network/tcp_ack_transport.dart';
import 'src/network/telemetry_transport.dart';
import 'src/screens/home_screen.dart';

const String defaultSocketHost = '127.0.0.1';
const int defaultSocketPort = 12345;

void main() {
  final hub = TelemetryHub();
  final transport =
      TcpAckTransport(host: defaultSocketHost, port: defaultSocketPort);
  bindTransportToHub(transport, hub);
  transport.connect();
  runApp(TelemetorApp(hub: hub, transport: transport));
}

class TelemetorApp extends StatelessWidget {
  const TelemetorApp({super.key, required this.hub, required this.transport});

  final TelemetryHub hub;
  final TelemetryTransport transport;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TelemetryHub>.value(value: hub),
        Provider<TelemetryTransport>.value(value: transport),
      ],
      child: const MaterialApp(
        title: 'Telemetor',
        home: HomeScreen(title: 'T E L E M E T O R'),
      ),
    );
  }
}
