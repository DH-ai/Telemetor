import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../telemetor_ui/telemetor_ui.dart';
import '../data/session_recorder.dart';
import '../models/recorded_session.dart';

/// Pick a recorded session to replay.
class ReplaySessionDialog extends StatelessWidget {
  const ReplaySessionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const ReplaySessionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recorder = context.read<SessionRecorder>();
    final sessions = recorder.sessions;
    final text = context.tdlText;

    return TDLDialog(
      title: 'Replay Session',
      content: SizedBox(
        width: 400,
        child: sessions.isEmpty
            ? Text('No recorded sessions.', style: text.tableCell)
            : ListView.separated(
                shrinkWrap: true,
                itemCount: sessions.length,
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  color: context.tdlColors.borderSecondary,
                ),
                itemBuilder: (context, index) =>
                    _SessionPickRow(session: sessions[index]),
              ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }
}

class _SessionPickRow extends StatelessWidget {
  const _SessionPickRow({required this.session});

  final RecordedSession session;

  @override
  Widget build(BuildContext context) {
    final recorder = context.read<SessionRecorder>();
    final text = context.tdlText;

    return ListTile(
      dense: true,
      title: Text(session.name, style: text.tableCell),
      subtitle: Text(
        '${session.formattedDate} · ${session.formattedSize}',
        style: text.monoSmall,
      ),
      trailing: const Icon(Icons.play_arrow, size: 18),
      onTap: () async {
        Navigator.of(context).pop();
        await recorder.replay(session);
      },
    );
  }
}
