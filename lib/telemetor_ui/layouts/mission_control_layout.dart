import 'package:flutter/widgets.dart';

import '../tdl_context.dart';
import '../tokens/borders.dart';
import 'tdl_layout.dart';

/// Root mission-control shell: sidebar + header + body + optional right rail.
///
/// Every Telemetor screen should be composed inside this layout rather than
/// rolling a custom Scaffold.
class MissionControlLayout extends StatelessWidget {
  const MissionControlLayout({
    super.key,
    required this.sidebar,
    required this.header,
    required this.body,
    this.rightRail,
    this.footer,
  });

  final Widget sidebar;
  final Widget header;
  final Widget body;
  final Widget? rightRail;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;

    return ColoredBox(
      color: colors.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: TDLLayout.sidebarWidth, child: sidebar),
          Container(width: 1, color: colors.borderSecondary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: TDLLayout.headerHeight, child: header),
                Container(height: 1, color: colors.borderSecondary),
                Expanded(child: body),
                if (footer != null) footer!,
              ],
            ),
          ),
          if (rightRail != null) ...[
            Container(width: 1, color: colors.borderSecondary),
            SizedBox(width: TDLLayout.rightRailWidth, child: rightRail),
          ],
        ],
      ),
    );
  }
}

/// Content area wrapper with standard panel padding.
class MissionControlBody extends StatelessWidget {
  const MissionControlBody({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    return ColoredBox(
      color: colors.background,
      child: Padding(
        padding: padding ?? TDLBorders.panelInset,
        child: child,
      ),
    );
  }
}
