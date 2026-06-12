import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/data/dashboard_controller.dart';
import 'src/data/stream_stats.dart';
import 'src/data/telemetry_hub.dart';
import 'src/data/transport_hub_binding.dart';
import 'src/network/tcp_ack_transport.dart';
import 'src/network/telemetry_transport.dart';
import 'src/screens/dashboard_screen.dart';
import 'src/theme/app_theme.dart';

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

class TelemetorApp extends StatefulWidget {
  const TelemetorApp({super.key, required this.hub, required this.transport});

  final TelemetryHub hub;
  final TelemetryTransport transport;

  @override
  State<TelemetorApp> createState() => _TelemetorAppState();
}

class _TelemetorAppState extends State<TelemetorApp> {
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.dark);
  late final DashboardController _dashboard =
      DashboardController(hub: widget.hub);
  late final StreamStats _stats = StreamStats(widget.transport);

  @override
  void dispose() {
    _themeMode.dispose();
    _dashboard.dispose();
    _stats.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TelemetryHub>.value(value: widget.hub),
        Provider<TelemetryTransport>.value(value: widget.transport),
        Provider<StreamStats>.value(value: _stats),
        ChangeNotifierProvider<DashboardController>.value(value: _dashboard),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeMode,
        builder: (context, mode, _) => MaterialApp(
          title: 'Telemetor',
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: mode,
          home: DashboardScreen(themeMode: _themeMode),
        ),
      ),
    );
  }
}
