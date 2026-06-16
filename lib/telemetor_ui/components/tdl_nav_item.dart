import 'package:flutter/widgets.dart';

import '../tdl_context.dart';
import '../tokens/borders.dart';
import '../tokens/spacing.dart';

/// Single sidebar navigation item.
class TDLNavItem extends StatelessWidget {
  const TDLNavItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: selected
            ? TDLBorders.navActiveIndicator(colors)
            : const BoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TDLSpacing.lg,
            vertical: TDLSpacing.sm,
          ),
          child: Text(
            label.toUpperCase(),
            style: selected
                ? text.navItemActive
                : text.navItem.copyWith(
                    color: enabled ? colors.navInactive : colors.textMuted,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Grouped section label inside the sidebar.
class TDLNavSection extends StatelessWidget {
  const TDLNavSection({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = context.tdlText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TDLSpacing.lg,
        TDLSpacing.md,
        TDLSpacing.lg,
        TDLSpacing.xs,
      ),
      child: Text(label.toUpperCase(), style: text.caption),
    );
  }
}
