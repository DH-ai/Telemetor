import 'package:flutter/widgets.dart';

import '../tdl_context.dart';
import '../tokens/spacing.dart';

/// Pulsing LIVE badge shown in the page header during active streaming.
class TDLLiveBadge extends StatelessWidget {
  const TDLLiveBadge({super.key, this.active = true});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;

    if (!active) {
      return Text(
        'OFFLINE',
        style: text.liveIndicator.copyWith(color: colors.textMuted),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
      ],
    );
  }
}
