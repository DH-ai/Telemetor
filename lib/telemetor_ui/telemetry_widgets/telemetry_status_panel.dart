import 'package:flutter/widgets.dart';

import '../components/tdl_panel.dart';
import '../layouts/panel_column.dart';
import '../tdl_context.dart';
import '../tokens/spacing.dart';

/// Key-value row for status panels.
class TelemetryStatusRow {
  const TelemetryStatusRow({required this.label, required this.value});

  final String label;
  final String value;
}

/// System status panel — packet rate, drops, uptime, session id.
class TelemetryStatusPanel extends StatelessWidget {
  const TelemetryStatusPanel({
    super.key,
    required this.rows,
  });

  final List<TelemetryStatusRow> rows;

  @override
  Widget build(BuildContext context) {
    final text = context.tdlText;

    return TDLPanel(
      title: 'System Status',
      padding: const EdgeInsets.symmetric(
        horizontal: TDLSpacing.lg,
        vertical: TDLSpacing.md,
      ),
      child: PanelColumn(
        gap: TDLSpacing.sm,
        children: [
          for (final row in rows)
            Row(
              children: [
                Expanded(
                  child: Text(row.label.toUpperCase(), style: text.caption),
                ),
                Text(row.value, style: text.mono),
              ],
            ),
        ],
      ),
    );
  }
}
