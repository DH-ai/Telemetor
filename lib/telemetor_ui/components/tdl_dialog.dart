import 'package:flutter/material.dart';

import '../tdl_context.dart';
import '../tokens/spacing.dart';

/// Mission-control styled dialog shell.
class TDLDialog extends StatelessWidget {
  const TDLDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget> actions = const [],
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => TDLDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = context.tdlText;

    return AlertDialog(
      title: Text(title.toUpperCase(), style: text.sectionTitle),
      content: content,
      actions: actions,
      actionsPadding: const EdgeInsets.fromLTRB(
        TDLSpacing.lg,
        0,
        TDLSpacing.lg,
        TDLSpacing.md,
      ),
    );
  }
}
