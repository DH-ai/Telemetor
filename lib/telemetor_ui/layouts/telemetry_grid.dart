import 'package:flutter/widgets.dart';

import '../tokens/spacing.dart';

/// Fixed-column telemetry chart wall — rows expand to fill available height.
///
/// Default is a 2-column mission-control grid matching the TELEMETOR V2 mockup.
class TelemetryGrid extends StatelessWidget {
  const TelemetryGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.columns = 2,
    this.maxItems,
    this.spacing = TDLSpacing.md,
    this.padding = TDLSpacing.panel,
  });

  final int itemCount;
  final int columns;
  /// Cap visible cells — defaults to [columns]×2 for a 2×2 wall.
  final int? maxItems;
  final double spacing;
  final EdgeInsets padding;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final cap = maxItems ?? columns * 2;
    final visibleCount = itemCount < cap ? itemCount : cap;
    if (visibleCount == 0) return const SizedBox.shrink();

    final rowCount = (visibleCount + columns - 1) ~/ columns;

    return Padding(
      padding: padding,
      child: Column(
        children: [
          for (var row = 0; row < rowCount; row++) ...[
            if (row > 0) SizedBox(height: spacing),
            Expanded(
              child: Row(
                children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) SizedBox(width: spacing),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final index = row * columns + col;
                          if (index >= visibleCount) {
                            return const SizedBox.shrink();
                          }
                          return SizedBox.expand(
                            child: itemBuilder(context, index),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
