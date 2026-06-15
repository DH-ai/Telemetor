import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../charts/telemetry_chart.dart';
import '../data/dashboard_controller.dart';
import '../data/stream_stats.dart';
import '../data/telemetry_hub.dart';
import '../models/telemetry_channel.dart';
import '../models/telemetry_sample.dart';
import '../network/telemetry_transport.dart';
import 'add_chart_dialog.dart';
import 'settings_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  @override
  Widget build(BuildContext context) {
    final transport = context.read<TelemetryTransport>();
    final controller = context.watch<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('T E L E M E T O R'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            tooltip: 'Add chart',
            onPressed: () => AddChartDialog.show(context, controller),
          ),
          _LayoutMenu(controller: controller),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeMode,
            builder: (context, mode, _) => IconButton(
              icon: Icon(
                  mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
              tooltip: 'Toggle light/dark mode',
              onPressed: () => themeMode.value =
                  mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Connection settings',
            onPressed: () => ConnectionSettingsDialog.show(context, transport),
          ),
        ],
      ),
      body: Column(
        children: [
          const _StatTileStrip(),
          Expanded(
            child: controller.fullscreenTile != null
                ? _FullscreenTile(
                    controller: controller,
                    tile: controller.fullscreenTile!,
                  )
                : _TileGrid(controller: controller),
          ),
          const _StatusBar(),
        ],
      ),
    );
  }
}

class _LayoutMenu extends StatelessWidget {
  const _LayoutMenu({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DashboardLayout>(
      icon: const Icon(Icons.dashboard_customize),
      tooltip: 'Layout',
      initialValue: controller.layout,
      onSelected: controller.setLayout,
      itemBuilder: (context) => const [
        PopupMenuItem(
            value: DashboardLayout.single, child: Text('Single column')),
        PopupMenuItem(
            value: DashboardLayout.dual, child: Text('Two columns')),
        PopupMenuItem(value: DashboardLayout.grid, child: Text('Grid')),
      ],
    );
  }
}

/// Horizontal strip of latest-value tiles, one per discovered channel.
class _StatTileStrip extends StatelessWidget {
  const _StatTileStrip();

  @override
  Widget build(BuildContext context) {
    final hub = context.read<TelemetryHub>();
    return ValueListenableBuilder<List<TelemetryChannel>>(
      valueListenable: hub.channelsNotifier,
      builder: (context, channels, _) {
        final named =
            channels.where((c) => c.name.trim().isNotEmpty).toList();
        if (named.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 68,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            scrollDirection: Axis.horizontal,
            itemCount: named.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                _StatTile(channel: named[index], hub: hub),
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.channel, required this.hub});

  final TelemetryChannel channel;
  final TelemetryHub hub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(channel.name, style: theme.textTheme.labelSmall),
            ValueListenableBuilder<TelemetrySample?>(
              valueListenable: hub.latest(channel.name),
              builder: (context, sample, _) => Text(
                sample == null
                    ? '—'
                    : '${_formatValue(sample.value)}'
                        '${channel.unit.isEmpty ? '' : ' ${channel.unit}'}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e9) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final tiles = controller.tiles;
    if (tiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No charts yet.'),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.add_chart),
              label: const Text('Add chart'),
              onPressed: () => AddChartDialog.show(context, controller),
            ),
          ],
        ),
      );
    }

    final gridDelegate = switch (controller.layout) {
      DashboardLayout.single =>
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisExtent: 320,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
      DashboardLayout.dual => const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 300,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
      DashboardLayout.grid => const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 480,
          mainAxisExtent: 260,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
    };

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: gridDelegate,
      itemCount: tiles.length,
      itemBuilder: (context, index) => _ChartTile(
        key: ValueKey(tiles[index].id),
        controller: controller,
        tile: tiles[index],
      ),
    );
  }
}

class _ChartTile extends StatelessWidget {
  const _ChartTile({
    super.key,
    required this.controller,
    required this.tile,
    this.fullscreen = false,
  });

  final DashboardController controller;
  final ChartTileConfig tile;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    final hub = context.read<TelemetryHub>();
    final channelsByName = {for (final c in hub.channels) c.name: c};
    final channels = [
      for (final name in tile.channelNames)
        channelsByName[name] ?? TelemetryChannel(name: name),
    ];
    final unit = channels.length == 1 ? channels.first.unit : '';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tile.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                icon: Icon(
                    fullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
                tooltip: fullscreen ? 'Exit fullscreen' : 'Fullscreen',
                onPressed: () => fullscreen
                    ? controller.exitFullscreen()
                    : controller.enterFullscreen(tile.id),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                icon: const Icon(Icons.close),
                tooltip: 'Remove chart',
                onPressed: () => controller.removeTile(tile.id),
              ),
            ],
          ),
          Expanded(
            child: TelemetryChart(
              hub: hub,
              channels: channels,
              title: '',
              unit: unit,
              showLegend: channels.length > 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenTile extends StatelessWidget {
  const _FullscreenTile({required this.controller, required this.tile});

  final DashboardController controller;
  final ChartTileConfig tile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _ChartTile(
        key: ValueKey('fullscreen-${tile.id}'),
        controller: controller,
        tile: tile,
        fullscreen: true,
      ),
    );
  }
}

/// Bottom status bar: connection state, endpoint, packet rate and drops.
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    final transport = context.read<TelemetryTransport>();
    final stats = context.read<StreamStats>();
    final theme = Theme.of(context);

    Widget item(IconData icon, Widget label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            label,
          ],
        );

    final labelStyle = theme.textTheme.labelSmall;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            StreamBuilder<TransportState>(
              stream: transport.states,
              initialData: transport.state,
              builder: (context, snapshot) {
                final state = snapshot.data ?? TransportState.disconnected;
                final color = switch (state) {
                  TransportState.connected => Colors.green,
                  TransportState.disconnected => theme.colorScheme.error,
                  _ => Colors.orange,
                };
                return item(
                  Icons.circle,
                  Text(
                    '${state.name} · ${transport.host}:${transport.port}',
                    style: labelStyle?.copyWith(color: color),
                  ),
                );
              },
            ),
            const Spacer(),
            ValueListenableBuilder<double>(
              valueListenable: stats.rowsPerSecond,
              builder: (context, rate, _) => item(
                Icons.speed,
                Text('${rate.toStringAsFixed(1)} rows/s', style: labelStyle),
              ),
            ),
            const SizedBox(width: 16),
            ValueListenableBuilder<int>(
              valueListenable: stats.totalRows,
              builder: (context, total, _) =>
                  item(Icons.numbers, Text('$total rows', style: labelStyle)),
            ),
            const SizedBox(width: 16),
            ValueListenableBuilder<int>(
              valueListenable: stats.droppedFrames,
              builder: (context, dropped, _) => item(
                Icons.warning_amber,
                Text('$dropped dropped', style: labelStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
