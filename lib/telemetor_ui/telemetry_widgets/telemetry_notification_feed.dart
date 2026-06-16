import 'package:flutter/widgets.dart';

import '../components/tdl_panel.dart';
import '../tdl_context.dart';
import '../tokens/spacing.dart';

enum TelemetryNotificationLevel { info, warning, alert }

/// One notification in [TelemetryNotificationFeed].
class TelemetryNotification {
  const TelemetryNotification({
    required this.message,
    required this.timestamp,
    this.level = TelemetryNotificationLevel.info,
  });

  final String message;
  final DateTime timestamp;
  final TelemetryNotificationLevel level;
}

/// Chronological feed of system alerts and status messages.
class TelemetryNotificationFeed extends StatelessWidget {
  const TelemetryNotificationFeed({
    super.key,
    required this.notifications,
    this.maxHeight = 140,
    this.expand = false,
  });

  final List<TelemetryNotification> notifications;
  final double maxHeight;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final list = _NotificationList(notifications: notifications);

    return TDLPanel(
      title: 'Notifications',
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

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.notifications});

  final List<TelemetryNotification> notifications;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Padding(
        padding: TDLSpacing.panel,
        child: Text(
          'No notifications.',
          style: context.tdlText.caption,
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: notifications.length,
      separatorBuilder: (_, __) => Container(
        height: 1,
        color: context.tdlColors.borderSecondary,
      ),
      itemBuilder: (context, index) =>
          _NotificationRow(notification: notifications[index]),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});

  final TelemetryNotification notification;

  @override
  Widget build(BuildContext context) {
    final colors = context.tdlColors;
    final text = context.tdlText;

    final dotColor = switch (notification.level) {
      TelemetryNotificationLevel.alert => colors.error,
      TelemetryNotificationLevel.warning => colors.warning,
      TelemetryNotificationLevel.info => colors.textSecondary,
    };

    final time = _formatTime(notification.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TDLSpacing.lg,
        vertical: TDLSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: TDLSpacing.xxs),
            child: Container(
              width: TDLSpacing.sm,
              height: TDLSpacing.sm,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          TDLSpacing.w(TDLSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message, style: text.tableCell),
                Text(time, style: text.monoSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
