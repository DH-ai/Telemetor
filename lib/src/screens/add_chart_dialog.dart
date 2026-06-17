import 'package:flutter/material.dart';

import '../../telemetor_ui/telemetor_ui.dart';
import '../data/dashboard_controller.dart';

/// Multi-select of discovered channels; creates one (possibly multi-series)
/// chart tile.
class AddChartDialog extends StatefulWidget {
  const AddChartDialog({super.key, required this.controller});

  final DashboardController controller;

  static Future<void> show(BuildContext context, DashboardController controller) {
    return showDialog<void>(
      context: context,
      builder: (_) => AddChartDialog(controller: controller),
    );
  }

  @override
  State<AddChartDialog> createState() => _AddChartDialogState();
}

class _AddChartDialogState extends State<AddChartDialog> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final channels = widget.controller.availableChannels;
    final text = context.tdlText;

    return TDLDialog(
      title: 'Add Chart',
      content: SizedBox(
        width: 320,
        child: channels.isEmpty
            ? Text('No channels discovered yet.', style: text.tableCell)
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final name in channels)
                    CheckboxListTile(
                      dense: true,
                      title: Text(name, style: text.tableCell),
                      value: _selected.contains(name),
                      onChanged: (checked) => setState(() {
                        checked == true
                            ? _selected.add(name)
                            : _selected.remove(name);
                      }),
                    ),
                ],
              ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () {
                  widget.controller.addTile(_selected.toList());
                  Navigator.of(context).pop();
                },
          child: const Text('ADD'),
        ),
      ],
    );
  }
}
