import 'package:flutter/material.dart';

import '../../telemetor_ui/telemetor_ui.dart';
import '../network/telemetry_transport.dart';

/// Lets the user change the server host/port at runtime.
class ConnectionSettingsDialog extends StatefulWidget {
  const ConnectionSettingsDialog({super.key, required this.transport});

  final TelemetryTransport transport;

  static Future<void> show(BuildContext context, TelemetryTransport transport) {
    return showDialog<void>(
      context: context,
      builder: (_) => ConnectionSettingsDialog(transport: transport),
    );
  }

  @override
  State<ConnectionSettingsDialog> createState() =>
      _ConnectionSettingsDialogState();
}

class _ConnectionSettingsDialogState extends State<ConnectionSettingsDialog> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.transport.host);
    _portController =
        TextEditingController(text: widget.transport.port.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (!_formKey.currentState!.validate()) return;
    final host = _hostController.text.trim();
    final port = int.parse(_portController.text.trim());
    Navigator.of(context).pop();
    await widget.transport.setEndpoint(host: host, port: port);
  }

  @override
  Widget build(BuildContext context) {
    return TDLDialog(
      title: 'Connection Settings',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(labelText: 'Host'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            TDLSpacing.h(TDLSpacing.md),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(labelText: 'Port'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final port = int.tryParse(value?.trim() ?? '');
                if (port == null || port < 1 || port > 65535) {
                  return 'Port must be 1-65535';
                }
                return null;
              },
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
          onPressed: _apply,
          child: const Text('APPLY'),
        ),
      ],
    );
  }
}
