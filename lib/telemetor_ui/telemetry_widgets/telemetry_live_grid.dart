import 'package:flutter/widgets.dart';

import '../components/tdl_panel.dart';
import '../layouts/panel_column.dart';
import '../tdl_context.dart';
import '../tokens/spacing.dart';

/// Compact label/value pair for grid cells.
class TelemetryLiveValue {
  const TelemetryLiveValue({
    required this.label,
    required this.value,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;
}

/// Dense grid of current telemetry values.
class TelemetryLiveGrid extends StatelessWidget {
  const TelemetryLiveGrid({
    super.key,
    required this.values,
    this.footer,
  });

  final List<TelemetryLiveValue> values;
  final List<TelemetryLiveValue>? footer;

  @override
  Widget build(BuildContext context) {
    return TDLPanel(
      title: 'Live Values',
      padding: const EdgeInsets.all(TDLSpacing.md),
      child: PanelColumn(
        gap: TDLSpacing.sm,
        children: [
          _ValueGrid(values: values),
          if (footer != null && footer!.isNotEmpty) ...[
            Container(
              height: 1,
              color: context.tdlColors.borderSecondary,
            ),
            _ValueGrid(values: footer!, compact: true),
          ],
        ],
      ),
    );
  }
}

class _ValueGrid extends StatelessWidget {
  const _ValueGrid({required this.values, this.compact = false});

  final List<TelemetryLiveValue> values;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = context.tdlText;

    return Wrap(
      spacing: TDLSpacing.sm,
      runSpacing: TDLSpacing.sm,
      children: [
        for (final item in values)
          SizedBox(
            width: compact ? 120 : 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label.toUpperCase(), style: text.caption),
                Text(
                  item.unit == null || item.unit!.isEmpty
                      ? item.value
                      : '${item.value} ${item.unit}',
                  style: compact ? text.monoSmall : text.mono,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
