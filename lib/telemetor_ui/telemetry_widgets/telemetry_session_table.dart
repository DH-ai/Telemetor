import 'package:flutter/widgets.dart';

import '../components/tdl_panel.dart';
import '../tdl_context.dart';
import '../tokens/spacing.dart';

/// One recorded session row.
class TelemetrySessionEntry {
  const TelemetrySessionEntry({
    required this.name,
    required this.date,
    required this.size,
  });

  final String name;
  final String date;
  final String size;
}

/// Table of recent flight / test sessions.
class TelemetrySessionTable extends StatelessWidget {
  const TelemetrySessionTable({
    super.key,
    required this.sessions,
    this.maxHeight = 140,
    this.expand = false,
  });

  final List<TelemetrySessionEntry> sessions;
  final double maxHeight;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final list = _SessionList(sessions: sessions);

    return TDLPanel(
      title: 'Recent Sessions',
      padding: EdgeInsets.zero,
      expandChild: expand,
      child: expand
          ? list
          : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: list,
            ),
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions});

  final List<TelemetrySessionEntry> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Padding(
        padding: TDLSpacing.panel,
        child: Text(
          'No recorded sessions.',
          style: context.tdlText.caption,
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: sessions.length,
      separatorBuilder: (_, __) => Container(
        height: 1,
        color: context.tdlColors.borderSecondary,
      ),
      itemBuilder: (context, index) => _SessionRow(entry: sessions[index]),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.entry});

  final TelemetrySessionEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = context.tdlText;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TDLSpacing.lg,
        vertical: TDLSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Text(entry.name, style: text.tableCell)),
          TDLSpacing.w(TDLSpacing.sm),
          Text(entry.date, style: text.monoSmall),
          TDLSpacing.w(TDLSpacing.md),
          Text(entry.size, style: text.monoSmall),
        ],
      ),
    );
  }
}
