import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../telemetor_ui/telemetor_ui.dart';
import '../charts/telemetry_chart.dart';
import '../data/dashboard_controller.dart';
import '../data/telemetry_hub.dart';
import '../models/telemetry_channel.dart';
import '../models/telemetry_sample.dart';
import 'add_chart_dialog.dart';

/// Dashboard content pane — rendered inside [AppShell].
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();

    return MissionControlBody(
      padding: EdgeInsets.zero,
      child: Column(
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
        ],
      ),
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
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: TDLBorders.divider(context.tdlColors),
            ),
          ),
          height: 72,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              TDLSpacing.lg,
              TDLSpacing.sm,
              TDLSpacing.lg,
              TDLSpacing.sm,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: named.length,
            separatorBuilder: (_, __) => TDLSpacing.w(TDLSpacing.sm),
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
    final colors = context.tdlColors;
    final text = context.tdlText;

    return TDLPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: TDLSpacing.lg,
        vertical: TDLSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(channel.name.toUpperCase(), style: text.metricLabel),
          ValueListenableBuilder<TelemetrySample?>(
            valueListenable: hub.latest(channel.name),
            builder: (context, sample, _) => Text(
              sample == null
                  ? '—'
                  : '${_formatValue(sample.value)}'
                      '${channel.unit.isEmpty ? '' : ' ${channel.unit}'}',
              style: text.metricValue.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
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
            Text('No charts yet.', style: context.tdlText.tableCell),
            TDLSpacing.h(TDLSpacing.sm),
            FilledButton.icon(
              icon: const Icon(Icons.add_chart),
              label: const Text('ADD CHART'),
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
          crossAxisSpacing: TDLSpacing.md,
          mainAxisSpacing: TDLSpacing.md,
        ),
      DashboardLayout.dual => const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 300,
          crossAxisSpacing: TDLSpacing.md,
          mainAxisSpacing: TDLSpacing.md,
        ),
      DashboardLayout.grid => const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 480,
          mainAxisExtent: 260,
          crossAxisSpacing: TDLSpacing.md,
          mainAxisSpacing: TDLSpacing.md,
        ),
    };

    return GridView.builder(
      padding: TDLSpacing.panel,
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
    final colors = context.tdlColors;
    final text = context.tdlText;
    final channelsByName = {for (final c in hub.channels) c.name: c};
    final channels = [
      for (final name in tile.channelNames)
        channelsByName[name] ?? TelemetryChannel(name: name),
    ];
    final unit = channels.length == 1 ? channels.first.unit : '';

    return TDLPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: TDLBorders.divider(colors)),
            ),
            padding: TDLSpacing.panelHeader,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tile.title.toUpperCase(),
                    style: text.sectionTitle.copyWith(color: colors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TDLHeaderIconButton(
                  icon: fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  tooltip: fullscreen ? 'Exit fullscreen' : 'Fullscreen',
                  onPressed: () => fullscreen
                      ? controller.exitFullscreen()
                      : controller.enterFullscreen(tile.id),
                ),
                TDLHeaderIconButton(
                  icon: Icons.close,
                  tooltip: 'Remove chart',
                  onPressed: () => controller.removeTile(tile.id),
                ),
              ],
            ),
          ),
          Expanded(
            child: TelemetryChart(
              hub: hub,
              channels: channels,
              title: '',
              unit: unit,
              showLegend: channels.length > 1,
              palette: colors.chartSeries,
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
      padding: TDLSpacing.panel,
      child: _ChartTile(
        key: ValueKey('fullscreen-${tile.id}'),
        controller: controller,
        tile: tile,
        fullscreen: true,
      ),
    );
  }
}
