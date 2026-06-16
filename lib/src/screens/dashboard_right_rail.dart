import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../telemetor_ui/telemetor_ui.dart';
import '../data/session_tracker.dart';
import '../data/stream_stats.dart';
import '../data/telemetry_hub.dart';
import '../models/telemetry_channel.dart';
import '../models/telemetry_sample.dart';
import '../network/telemetry_transport.dart';

/// Right-side dashboard rail: channels, status, device, quick actions.
class DashboardRightRail extends StatelessWidget {
  const DashboardRightRail({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;

    return ColoredBox(
      color: colors.surface,
      child: const SingleChildScrollView(
        padding: EdgeInsets.all(TDLSpacing.md),
        child: PanelColumn(
          gap: TDLSpacing.md,
          children: [
            _ChannelListPane(),
            _StatusPane(),
            _DevicePane(),
            _ActionsPane(),
          ],
        ),
      ),
    );
  }
}

class _ChannelListPane extends StatelessWidget {
  const _ChannelListPane();

  @override
  Widget build(BuildContext context) {
    final hub = context.read<TelemetryHub>();
    final colors = context.tdlColors;

    return ValueListenableBuilder<List<TelemetryChannel>>(
      valueListenable: hub.channelsNotifier,
      builder: (context, channels, _) {
        final named =
            channels.where((c) => c.name.trim().isNotEmpty).toList();

        if (named.isEmpty) {
          return const TelemetryChannelList(channels: []);
        }

        return TDLPanel(
          title: 'Telemetry',
          padding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: named.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                color: colors.borderSecondary,
              ),
              itemBuilder: (context, index) => _ChannelRow(
                channel: named[index],
                hub: hub,
                color: colors.chartSeries[index % colors.chartSeries.length],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.channel,
    required this.hub,
    required this.color,
  });

  final TelemetryChannel channel;
  final TelemetryHub hub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = context.tdlText;

    return ValueListenableBuilder<TelemetrySample?>(
      valueListenable: hub.latest(channel.name),
      builder: (context, sample, _) {
        final entry = TelemetryChannelEntry(
          name: channel.name,
          value: sample == null ? '—' : formatTelemetryValue(sample.value),
          unit: channel.unit,
          color: color,
          active: sample != null,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TDLSpacing.lg,
            vertical: TDLSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: TDLSpacing.sm,
                height: TDLSpacing.sm,
                decoration: BoxDecoration(
                  color: entry.active ? entry.color : context.tdlColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              TDLSpacing.w(TDLSpacing.sm),
              Expanded(child: Text(entry.name, style: text.tableCell)),
              Text(
                entry.unit.isEmpty
                    ? entry.value
                    : '${entry.value} ${entry.unit}',
                style: text.mono,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusPane extends StatelessWidget {
  const _StatusPane();

  @override
  Widget build(BuildContext context) {
    final stats = context.read<StreamStats>();
    final session = context.read<SessionTracker>();

    return ValueListenableBuilder<double>(
      valueListenable: stats.rowsPerSecond,
      builder: (context, rate, _) {
        return ValueListenableBuilder<int>(
          valueListenable: stats.droppedFrames,
          builder: (context, dropped, _) {
            return ValueListenableBuilder<Duration>(
              valueListenable: session.uptime,
              builder: (context, uptime, _) {
                return ValueListenableBuilder<String>(
                  valueListenable: session.sessionId,
                  builder: (context, sessionId, _) {
                    return TelemetryStatusPanel(
                      rows: [
                        TelemetryStatusRow(
                          label: 'Packet Rate',
                          value: '${rate.toStringAsFixed(1)} Hz',
                        ),
                        TelemetryStatusRow(
                          label: 'Dropped Packets',
                          value: '$dropped',
                        ),
                        TelemetryStatusRow(
                          label: 'Uptime',
                          value: formatUptime(uptime),
                        ),
                        TelemetryStatusRow(
                          label: 'Session ID',
                          value: sessionId,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DevicePane extends StatelessWidget {
  const _DevicePane();

  @override
  Widget build(BuildContext context) {
    final transport = context.read<TelemetryTransport>();
    final stats = context.read<StreamStats>();

    return StreamBuilder<TransportState>(
      stream: transport.states,
      initialData: transport.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? TransportState.disconnected;
        final connected = state == TransportState.connected;

        return ValueListenableBuilder<double>(
          valueListenable: stats.rowsPerSecond,
          builder: (context, rate, _) {
            final signal = !connected
                ? 0
                : rate > 0
                    ? 4
                    : 2;
            return TelemetryDeviceCard(
              name: _deviceName(transport.host),
              live: connected,
              endpoint: '${transport.host}:${transport.port}',
              rateHz: connected
                  ? '${rate.toStringAsFixed(1)} Hz'
                  : null,
              signalStrength: signal,
            );
          },
        );
      },
    );
  }

  String _deviceName(String host) {
    if (host == '127.0.0.1' || host == 'localhost') return 'Local Source';
    return host;
  }
}

class _ActionsPane extends StatelessWidget {
  const _ActionsPane();

  @override
  Widget build(BuildContext context) {
    return TelemetryQuickActions(
      actions: [
        TelemetryAction(
          label: 'Start Recording',
          icon: Icons.fiber_manual_record,
          primary: true,
          onPressed: () => _toast(context, 'Recording not yet implemented'),
        ),
        TelemetryAction(
          label: 'Replay Session',
          icon: Icons.play_arrow,
          onPressed: () => _toast(context, 'Replay not yet implemented'),
        ),
        TelemetryAction(
          label: 'Export CSV',
          icon: Icons.download,
          onPressed: () => _toast(context, 'Export not yet implemented'),
        ),
      ],
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
