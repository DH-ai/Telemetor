import 'package:flutter/widgets.dart';

import '../tdl_context.dart';
import '../tokens/borders.dart';
import '../tokens/spacing.dart';
import 'tdl_layout.dart';

/// Thin bottom status strip for secondary metadata (build, copyright, etc.).
class StatusStrip extends StatelessWidget {
  const StatusStrip({
    super.key,
    required this.children,
    this.leading,
    this.trailing,
  });

  final List<Widget> children;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;

    return Container(
      height: TDLLayout.statusStripHeight,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: TDLBorders.divider(colors)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: TDLSpacing.lg),
      child: Row(
        children: [
          if (leading != null) ...[
            DefaultTextStyle(style: text.monoSmall, child: leading!),
            TDLSpacing.w(TDLSpacing.xl),
          ],
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) TDLSpacing.w(TDLSpacing.lg),
            DefaultTextStyle(style: text.monoSmall, child: children[i]),
          ],
          const Spacer(),
          if (trailing != null)
            DefaultTextStyle(style: text.monoSmall, child: trailing!),
        ],
      ),
    );
  }
}
