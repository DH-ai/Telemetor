import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../charts/altitude_chart.dart';
import '../data/telemetry_hub.dart';
import '../models/telemetry_channel.dart';
import '../network/telemetry_transport.dart';
import '../theme/app_colors.dart';
import 'settings_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final transport = context.read<TelemetryTransport>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        centerTitle: true,
        title: Text(title),
        actions: [
          _ConnectionStateIcon(transport: transport),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Connection settings',
            onPressed: () => ConnectionSettingsDialog.show(context, transport),
          ),
        ],
      ),
      body: const _HomeBody(),
      backgroundColor: AppColors.scaffoldBackground,
    );
  }
}

class _ConnectionStateIcon extends StatelessWidget {
  const _ConnectionStateIcon({required this.transport});

  final TelemetryTransport transport;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TransportState>(
      stream: transport.states,
      initialData: transport.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? TransportState.disconnected;
        final (icon, color) = switch (state) {
          TransportState.connected => (Icons.cloud_done, Colors.greenAccent),
          TransportState.connecting ||
          TransportState.handshaking ||
          TransportState.reconnecting =>
            (Icons.cloud_sync, Colors.amberAccent),
          TransportState.disconnected => (Icons.cloud_off, Colors.redAccent),
        };
        return Tooltip(
          message: state.name,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(icon, color: color),
          ),
        );
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      AspectRatio(
        aspectRatio: 3 / 10,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.panelBackground, width: 2),
          ),
          margin: const EdgeInsets.all(10),
          alignment: Alignment.centerLeft,
          constraints: const BoxConstraints(minWidth: 200, minHeight: 600),
          child: const SidePanel(),
        ),
      ),
      Expanded(
        child: Container(
          color: AppColors.chartBackground,
          margin: const EdgeInsets.all(40),
          child: const ChartGrid(),
        ),
      ),
    ]);
  }
}

class SidePanel extends StatelessWidget {
  const SidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200, minHeight: 200),
      child: const Text(
        'Hello World',
        style: TextStyle(color: AppColors.accent),
      ),
    );
  }
}

/// Main chart area: Altitude, Temperature, Velocity, Acceleration and
/// Gyroscope tiles. Only Temperature plots live data in this prototype;
/// it follows the second discovered channel (matching the old behavior of
/// plotting the second column of each row).
class ChartGrid extends StatelessWidget {
  const ChartGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final hub = context.read<TelemetryHub>();
    return Column(children: <Widget>[
      Expanded(
        flex: 2,
        child: Row(
          children: <Widget>[
            const Expanded(
              child: AspectRatio(aspectRatio: 16 / 15, child: AltitudeTile()),
            ),
            Expanded(
              child: AspectRatio(
                aspectRatio: 16 / 15,
                child: ValueListenableBuilder<List<TelemetryChannel>>(
                  valueListenable: hub.channelsNotifier,
                  builder: (context, channels, _) {
                    if (channels.isEmpty) {
                      return const TemperatureTile(child: SizedBox());
                    }
                    final channel =
                        channels.length > 1 ? channels[1] : channels.first;
                    return TemperatureTile(
                      child: AltitudeChart(
                        key: ValueKey(channel.name),
                        sampleStream: hub.stream(channel.name),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Expanded(
              child: AspectRatio(aspectRatio: 16 / 15, child: VelocityTile()),
            ),
          ],
        ),
      ),
      const Expanded(
        flex: 3,
        child: Row(
          children: <Widget>[
            Expanded(
              child: AspectRatio(aspectRatio: 16 / 13, child: GyroscopeTile()),
            ),
            Expanded(
              child:
                  AspectRatio(aspectRatio: 16 / 13, child: AccelerationTile()),
            ),
          ],
        ),
      ),
    ]);
  }
}

class AltitudeTile extends StatelessWidget {
  const AltitudeTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Container(
        margin: const EdgeInsets.all(10),
        color: Colors.black,
      ),
    );
  }
}

class TemperatureTile extends StatelessWidget {
  const TemperatureTile({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Colors.black,
      child: SizedBox(height: 200, width: 200, child: child),
    );
  }
}

class VelocityTile extends StatelessWidget {
  const VelocityTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Colors.black,
      child: const SizedBox(height: 200, width: 200),
    );
  }
}

class AccelerationTile extends StatelessWidget {
  const AccelerationTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Colors.black,
      child: const SizedBox(height: 200, width: 200),
    );
  }
}

class GyroscopeTile extends StatelessWidget {
  const GyroscopeTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Colors.black,
      child: const SizedBox(
        height: 200,
        width: 200,
        child: Text('Gyroscope'),
      ),
    );
  }
}
