import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../charts/telemetry_chart.dart';
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
      body: const _ChartGrid(),
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

/// One [TelemetryChart] tile per discovered channel. The fully featured
/// dashboard (add/remove tiles, layouts, stat tiles) lands in G1-M5.
class _ChartGrid extends StatelessWidget {
  const _ChartGrid();

  @override
  Widget build(BuildContext context) {
    final hub = context.read<TelemetryHub>();
    return ValueListenableBuilder<List<TelemetryChannel>>(
      valueListenable: hub.channelsNotifier,
      builder: (context, channels, _) {
        final named =
            channels.where((c) => c.name.trim().isNotEmpty).toList();
        if (named.isEmpty) {
          return const Center(
            child: Text(
              'Waiting for channels…',
              style: TextStyle(color: AppColors.accent),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 480,
            mainAxisExtent: 260,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: named.length,
          itemBuilder: (context, index) {
            final channel = named[index];
            return Card(
              color: AppColors.panelBackground,
              child: TelemetryChart(
                key: ValueKey(channel.name),
                hub: hub,
                channels: [channel],
                title: channel.name,
                unit: channel.unit,
              ),
            );
          },
        );
      },
    );
  }
}
