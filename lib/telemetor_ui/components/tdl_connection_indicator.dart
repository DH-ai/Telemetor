import 'package:flutter/widgets.dart';

import '../tdl_context.dart';
import '../tokens/spacing.dart';

/// Sidebar / status connection indicator.
class TDLConnectionIndicator extends StatelessWidget {
  const TDLConnectionIndicator({
    super.key,
    required this.connected,
    required this.label,
    this.detail,
    this.subtitle,
    this.trailing,
  });

  final bool connected;
  final String label;
  final String? detail;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;
    final dotColor =
        connected ? colors.statusConnected : colors.statusDisconnected;

    return Padding(
      padding: const EdgeInsets.all(TDLSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: TDLSpacing.sm,
                height: TDLSpacing.sm,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              TDLSpacing.w(TDLSpacing.sm),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: text.navItemActive.copyWith(color: dotColor),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            TDLSpacing.h(TDLSpacing.xs),
            Text(subtitle!, style: text.monoSmall),
          ],
          if (detail != null) ...[
            TDLSpacing.h(TDLSpacing.xxs),
            Text(detail!, style: text.monoSmall),
          ],
        ],
      ),
    );
  }
}
