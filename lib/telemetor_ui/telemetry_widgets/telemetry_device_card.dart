import 'package:flutter/widgets.dart';

import '../components/tdl_panel.dart';
import '../tdl_context.dart';
import '../tokens/spacing.dart';

/// Connected device summary card.
class TelemetryDeviceCard extends StatelessWidget {
  const TelemetryDeviceCard({
    super.key,
    required this.name,
    required this.live,
    required this.endpoint,
    this.rateHz,
    this.signalStrength,
  });

  final String name;
  final bool live;
  final String endpoint;
  final String? rateHz;
  final int? signalStrength;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;

    return TDLPanel(
      title: 'Devices',
      padding: const EdgeInsets.all(TDLSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: text.tableCell),
              ),
              if (live) ...[
                Container(
                  width: TDLSpacing.sm,
                  height: TDLSpacing.sm,
                  decoration: BoxDecoration(
                    color: colors.live,
                    shape: BoxShape.circle,
                  ),
                ),
                TDLSpacing.w(TDLSpacing.xs),
                Text('LIVE', style: text.liveIndicator),
              ] else
                Text('OFFLINE', style: text.caption),
            ],
          ),
          TDLSpacing.h(TDLSpacing.sm),
          Text(endpoint, style: text.monoSmall),
          if (rateHz != null) ...[
            TDLSpacing.h(TDLSpacing.xs),
            Text(rateHz!, style: text.monoSmall),
          ],
          if (signalStrength != null) ...[
            TDLSpacing.h(TDLSpacing.sm),
            _SignalBars(strength: signalStrength!),
          ],
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final clamped = strength.clamp(0, 4);

    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: TDLSpacing.xs,
            height: TDLSpacing.sm + (i * TDLSpacing.xs),
            margin: const EdgeInsets.only(right: TDLSpacing.xxs),
            color: i < clamped ? colors.accent : colors.borderSecondary,
          ),
      ],
    );
  }
}
