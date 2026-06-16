import 'package:flutter/widgets.dart';

import '../tokens/spacing.dart';

/// Vertical panel column with consistent [TDLSpacing] gaps.
class PanelColumn extends StatelessWidget {
  const PanelColumn({
    super.key,
    required this.children,
    this.gap = TDLSpacing.md,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    );
  }
}
