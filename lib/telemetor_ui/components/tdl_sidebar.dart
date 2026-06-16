import 'package:flutter/widgets.dart';

import '../components/tdl_nav_item.dart';
import '../layouts/panel_column.dart';
import '../tdl_context.dart';
import '../tokens/spacing.dart';

/// Navigation destination descriptor.
class TDLSidebarDestination {
  const TDLSidebarDestination({
    required this.id,
    required this.label,
    this.enabled = true,
  });

  final String id;
  final String label;
  final bool enabled;
}

/// Navigation section grouping destinations under a label.
class TDLSidebarSection {
  const TDLSidebarSection({
    required this.label,
    required this.destinations,
  });

  final String label;
  final List<TDLSidebarDestination> destinations;
}

/// Mission-control sidebar with logo, grouped nav, and connection footer.
class TDLSidebar extends StatelessWidget {
  const TDLSidebar({
    super.key,
    required this.sections,
    required this.selectedId,
    required this.onSelected,
    this.footer,
    this.versionLabel = 'V2',
  });

  final List<TDLSidebarSection> sections;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final Widget? footer;
  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;

    return ColoredBox(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TDLSpacing.lg,
              TDLSpacing.xl,
              TDLSpacing.lg,
              TDLSpacing.lg,
            ),
            child: Row(
              children: [
                Container(
                  width: TDLSpacing.xl,
                  height: TDLSpacing.xl,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.accent),
                  ),
                  child: CustomPaint(
                    painter: _WaveformIconPainter(color: colors.accent),
                  ),
                ),
                TDLSpacing.w(TDLSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TELEMETOR', style: text.navItemActive),
                      Text(versionLabel, style: text.monoSmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: colors.borderSecondary),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final section in sections) ...[
                  TDLNavSection(label: section.label),
                  PanelColumn(
                    gap: TDLSpacing.none,
                    children: [
                      for (final dest in section.destinations)
                        TDLNavItem(
                          label: dest.label,
                          selected: dest.id == selectedId,
                          enabled: dest.enabled,
                          onTap: () => onSelected(dest.id),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: colors.borderSecondary),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

class _WaveformIconPainter extends CustomPainter {
  _WaveformIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(2, size.height * 0.7)
      ..lineTo(6, size.height * 0.3)
      ..lineTo(10, size.height * 0.55)
      ..lineTo(14, size.height * 0.2)
      ..lineTo(18, size.height * 0.65)
      ..lineTo(22, size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveformIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
