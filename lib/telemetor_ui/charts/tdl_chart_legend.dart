import 'package:flutter/widgets.dart';

import '../layouts/panel_row.dart';
import '../tdl_context.dart';
import '../tokens/spacing.dart';
import 'tdl_chart_style.dart';

/// Series legend for telemetry charts.
class TDLChartLegend extends StatelessWidget {
  const TDLChartLegend({
    super.key,
    required this.labels,
    required this.style,
  });

  final List<String> labels;
  final TDLChartStyle style;

  @override
  Widget build(BuildContext context) {
    final text = context.tdlText;

    return PanelRow(
      gap: TDLSpacing.md,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < labels.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: TDLSpacing.sm,
                height: TDLSpacing.sm,
                decoration: BoxDecoration(
                  color: style.seriesColor(i),
                  shape: BoxShape.circle,
                ),
              ),
              TDLSpacing.w(TDLSpacing.xs),
              Text(labels[i], style: text.caption),
            ],
          ),
      ],
    );
  }
}
