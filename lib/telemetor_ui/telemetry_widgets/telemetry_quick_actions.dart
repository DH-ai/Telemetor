import 'package:flutter/widgets.dart';

import '../components/tdl_panel.dart';
import '../layouts/panel_column.dart';
import '../tdl_context.dart';
import '../tokens/spacing.dart';

/// Descriptor for a quick-action button.
class TelemetryAction {
  const TelemetryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
}

/// Vertical stack of mission-control action buttons.
class TelemetryQuickActions extends StatelessWidget {
  const TelemetryQuickActions({
    super.key,
    required this.actions,
  });

  final List<TelemetryAction> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;

    return TDLPanel(
      title: 'Quick Actions',
      padding: const EdgeInsets.all(TDLSpacing.lg),
      child: PanelColumn(
        gap: TDLSpacing.sm,
        children: [
          for (final action in actions)
            GestureDetector(
              onTap: action.onPressed,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TDLSpacing.md,
                  vertical: TDLSpacing.sm,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: action.primary
                        ? colors.accent
                        : colors.borderPrimary,
                  ),
                  color: action.primary ? colors.accentMuted.withValues(alpha: 0.15) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      action.icon,
                      size: 16,
                      color: action.primary ? colors.accent : colors.textSecondary,
                    ),
                    TDLSpacing.w(TDLSpacing.sm),
                    Expanded(
                      child: Text(
                        action.label.toUpperCase(),
                        style: action.primary
                            ? text.navItemActive
                            : text.navItem.copyWith(color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
