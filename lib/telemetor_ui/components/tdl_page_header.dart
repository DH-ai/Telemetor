import 'package:flutter/material.dart';

import '../layouts/panel_row.dart';
import '../tdl_context.dart';
import '../tokens/spacing.dart';
import 'tdl_live_badge.dart';

/// Top page header with title, breadcrumb, live metrics, and actions.
class TDLPageHeader extends StatelessWidget {
  const TDLPageHeader({
    super.key,
    required this.title,
    this.breadcrumb,
    this.live = false,
    this.metrics = const [],
    this.actions = const [],
  });

  final String title;
  final String? breadcrumb;
  final bool live;
  final List<HeaderMetric> metrics;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;

    return DecoratedBox(
      decoration: BoxDecoration(color: colors.surface),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TDLSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: text.pageTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (breadcrumb != null)
                    Text(
                      breadcrumb!.toUpperCase(),
                      style: text.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TDLLiveBadge(active: live),
                    TDLSpacing.w(TDLSpacing.lg),
                    PanelRow(
                      gap: TDLSpacing.lg,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (final metric in metrics)
                          _MetricChip(
                            label: metric.label,
                            value: metric.value,
                          ),
                      ],
                    ),
                    TDLSpacing.w(TDLSpacing.lg),
                    Container(
                      width: 1,
                      height: TDLSpacing.xl,
                      color: colors.borderSecondary,
                    ),
                    TDLSpacing.w(TDLSpacing.sm),
                    PanelRow(
                      gap: TDLSpacing.xs,
                      children: actions,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderMetric {
  const HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.tdlText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${label.toUpperCase()} ', style: text.caption),
        Text(value, style: text.mono),
      ],
    );
  }
}

/// Icon button styled for the mission-control header.
class TDLHeaderIconButton extends StatelessWidget {
  const TDLHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(TDLSpacing.sm),
          child: Icon(icon, size: 18, color: colors.textSecondary),
        ),
      ),
    );
  }
}
