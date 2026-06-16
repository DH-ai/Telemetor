import 'package:flutter/widgets.dart';

import '../components/tdl_panel.dart';
import '../tdl_context.dart';
import '../tokens/spacing.dart';

/// One row in [TelemetryChannelList].
class TelemetryChannelEntry {
  const TelemetryChannelEntry({
    required this.name,
    required this.value,
    this.unit = '',
    this.color,
    this.active = true,
  });

  final String name;
  final String value;
  final String unit;
  final Color? color;
  final bool active;
}

/// Scrollable list of active telemetry channels with live values.
class TelemetryChannelList extends StatelessWidget {
  const TelemetryChannelList({
    super.key,
    required this.channels,
    this.maxHeight = 220,
  });

  final List<TelemetryChannelEntry> channels;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return TDLPanel(
      title: 'Telemetry',
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: channels.isEmpty
            ? Padding(
                padding: TDLSpacing.panel,
                child: Text(
                  'No channels yet.',
                  style: context.tdlText.caption,
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: channels.length,
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  color: context.tdlColors.borderSecondary,
                ),
                itemBuilder: (context, index) =>
                    _ChannelRow(entry: channels[index]),
              ),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.entry});

  final TelemetryChannelEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;
    final dotColor = entry.color ?? colors.chartSeries.first;

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
              color: entry.active ? dotColor : colors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          TDLSpacing.w(TDLSpacing.sm),
          Expanded(
            child: Text(
              entry.name,
              style: text.tableCell,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            entry.unit.isEmpty ? entry.value : '${entry.value} ${entry.unit}',
            style: text.mono,
          ),
        ],
      ),
    );
  }
}
