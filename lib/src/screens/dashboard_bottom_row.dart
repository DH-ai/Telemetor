import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../telemetor_ui/telemetor_ui.dart';
import '../data/notification_feed.dart';
import '../data/session_recorder.dart';
import '../data/stream_stats.dart';
import '../data/telemetry_hub.dart';
import '../models/telemetry_channel.dart';
import '../models/telemetry_sample.dart';

/// Bottom dashboard row: sessions, live values, map, notifications.
class DashboardBottomRow extends StatelessWidget {
  const DashboardBottomRow({super.key});

  static const double height = 168;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : DashboardBottomRow.height;

        return Container(
          height: rowHeight,
          decoration: BoxDecoration(
            border: Border(top: TDLBorders.divider(colors)),
            color: colors.background,
          ),
          padding: const EdgeInsets.all(TDLSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: _SessionsPane()),
              TDLSpacing.w(TDLSpacing.md),
              const Expanded(child: _LiveValuesPane()),
              TDLSpacing.w(TDLSpacing.md),
              const Expanded(child: TelemetryMapView(fill: true)),
              TDLSpacing.w(TDLSpacing.md),
              const Expanded(child: _NotificationsPane()),
            ],
          ),
        );
      },
    );
  }
}

class _SessionsPane extends StatelessWidget {
  const _SessionsPane();

  @override
  Widget build(BuildContext context) {
    final recorder = context.watch<SessionRecorder>();

    return TelemetrySessionTable(
      expand: true,
      sessions: [
        for (final session in recorder.sessions.take(3))
          TelemetrySessionEntry(
            name: session.name,
            date: session.formattedDate,
            size: session.formattedSize,
          ),
      ],
    );
  }
}

class _LiveValuesPane extends StatelessWidget {
  const _LiveValuesPane();

  @override
  Widget build(BuildContext context) {
    final hub = context.read<TelemetryHub>();
    final stats = context.read<StreamStats>();

    return ValueListenableBuilder<List<TelemetryChannel>>(
      valueListenable: hub.channelsNotifier,
      builder: (context, channels, _) {
        final named =
            channels.where((c) => c.name.trim().isNotEmpty).toList();
        final primary = named.take(6).toList();

        return _LiveGridBody(channels: primary, hub: hub, stats: stats);
      },
    );
  }
}

class _LiveGridBody extends StatelessWidget {
  const _LiveGridBody({
    required this.channels,
    required this.hub,
    required this.stats,
  });

  final List<TelemetryChannel> channels;
  final TelemetryHub hub;
  final StreamStats stats;

  @override
  Widget build(BuildContext context) {
    final text = context.tdlText;

    final uplink = ValueListenableBuilder<double>(
      valueListenable: stats.rowsPerSecond,
      builder: (context, rate, _) => Row(
        children: [
          Text('UPLINK ', style: text.caption),
          Text(
            '${(rate * 24 / 1024).toStringAsFixed(1)} kb/s',
            style: text.monoSmall,
          ),
        ],
      ),
    );

    if (channels.isEmpty) {
      return TDLPanel(
        title: 'Live Values',
        expandChild: true,
        padding: const EdgeInsets.all(TDLSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Waiting for data…', style: text.caption),
            TDLSpacing.h(TDLSpacing.sm),
            uplink,
          ],
        ),
      );
    }

    return TDLPanel(
      title: 'Live Values',
      expandChild: true,
      padding: const EdgeInsets.all(TDLSpacing.md),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: TDLSpacing.sm,
              runSpacing: TDLSpacing.sm,
              children: [
                for (final channel in channels)
                  _LiveCell(channel: channel, hub: hub),
              ],
            ),
            TDLSpacing.h(TDLSpacing.sm),
            Container(height: 1, color: context.tdlColors.borderSecondary),
            TDLSpacing.h(TDLSpacing.sm),
            uplink,
          ],
        ),
      ),
    );
  }
}

class _LiveCell extends StatelessWidget {
  const _LiveCell({required this.channel, required this.hub});

  final TelemetryChannel channel;
  final TelemetryHub hub;

  @override
  Widget build(BuildContext context) {
    final text = context.tdlText;

    return ValueListenableBuilder<TelemetrySample?>(
      valueListenable: hub.latest(channel.name),
      builder: (context, sample, _) {
        final unit = channel.unit.isEmpty ? null : channel.unit;
        final value =
            sample == null ? '—' : formatTelemetryValue(sample.value);
        return SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(channel.name.toUpperCase(), style: text.caption),
              Text(
                unit == null ? value : '$value $unit',
                style: text.mono,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationsPane extends StatelessWidget {
  const _NotificationsPane();

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<NotificationFeed>();

    return TelemetryNotificationFeed(
      notifications: feed.items.take(8).toList(),
      expand: true,
    );
  }
}
