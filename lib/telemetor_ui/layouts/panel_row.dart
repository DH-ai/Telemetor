import 'package:flutter/widgets.dart';

import '../tokens/spacing.dart';

/// Horizontal panel row with consistent [TDLSpacing] gaps.
class PanelRow extends StatelessWidget {
  const PanelRow({
    super.key,
    required this.children,
    this.gap = TDLSpacing.md,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          children[i],
        ],
      ],
    );
  }
}
