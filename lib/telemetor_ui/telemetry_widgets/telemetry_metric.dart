import 'package:flutter/widgets.dart';

import '../components/tdl_panel.dart';
import '../tdl_context.dart';
import '../tokens/spacing.dart';

/// Single metric card — label, value, optional unit and delta indicator.
class TelemetryMetric extends StatelessWidget {
  const TelemetryMetric({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.delta,
    this.deltaPositive,
    this.compact = false,
  });

  final String label;
  final String value;
  final String? unit;
  final String? delta;
  final bool? deltaPositive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;

    final valueText = unit == null || unit!.isEmpty ? value : '$value $unit';

    return TDLPanel(
      padding: EdgeInsets.symmetric(
        horizontal: TDLSpacing.lg,
        vertical: compact ? TDLSpacing.sm : TDLSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: text.metricLabel),
          if (compact)
            Text(valueText, style: text.tableCell)
          else ...[
            Text(valueText, style: text.metricValue),
            if (delta != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    deltaPositive == true
                        ? '▲'
                        : deltaPositive == false
                            ? '▼'
                            : '·',
                    style: text.metricDelta.copyWith(
                      color: deltaPositive == true
                          ? colors.accent
                          : colors.textSecondary,
                    ),
                  ),
                  TDLSpacing.w(TDLSpacing.xxs),
                  Text(delta!, style: text.metricDelta),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
