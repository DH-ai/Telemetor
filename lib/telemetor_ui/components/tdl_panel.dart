import 'package:flutter/widgets.dart';

import '../tdl_context.dart';
import '../tokens/borders.dart';
import '../tokens/spacing.dart';

/// Bordered panel surface — the primary container primitive.
class TDLPanel extends StatelessWidget {
  const TDLPanel({
    super.key,
    required this.child,
    this.title,
    this.headerActions,
    this.padding,
    this.selected = false,
    this.alert = false,
    this.expandChild = false,
  });

  final Widget child;
  final String? title;
  final List<Widget>? headerActions;
  final EdgeInsets? padding;
  final bool selected;
  final bool alert;

  /// When true, the child expands to fill remaining vertical space inside a
  /// bounded flex parent (e.g. [Expanded] in a bottom-row panel).
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;

    final decoration = alert
        ? TDLBorders.alertPanel(colors)
        : selected
            ? BoxDecoration(
                color: colors.panel,
                border: TDLBorders.panelSelected(colors),
              )
            : TDLBorders.panelDecoration(colors);

    final body = Padding(
      padding: padding ?? TDLSpacing.panel,
      child: child,
    );

    return DecoratedBox(
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize:
            expandChild ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (title != null)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: TDLBorders.divider(colors),
                ),
              ),
              padding: TDLSpacing.panelHeader,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!.toUpperCase(),
                      style: text.sectionTitle,
                    ),
                  ),
                  if (headerActions != null) ...headerActions!,
                ],
              ),
            ),
          if (expandChild) Expanded(child: body) else body,
        ],
      ),
    );
  }
}
