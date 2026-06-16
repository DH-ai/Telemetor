import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../telemetor_ui/telemetor_ui.dart';
import '../network/telemetry_transport.dart';

/// In-memory notification feed for dashboard alerts.
class NotificationFeed extends ChangeNotifier {
  NotificationFeed(TelemetryTransport transport, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _subscription = transport.states.listen(_onState);
    _onState(transport.state);
  }

  final DateTime Function() _clock;
  late final StreamSubscription<TransportState> _subscription;
  TransportState? _lastState;

  final List<TelemetryNotification> _items = [];

  List<TelemetryNotification> get items => List.unmodifiable(_items);

  void _onState(TransportState state) {
    if (_lastState == state) return;
    final previous = _lastState;
    _lastState = state;

    switch (state) {
      case TransportState.connected:
        _push('Connection established', TelemetryNotificationLevel.info);
      case TransportState.disconnected:
        if (previous != null) {
          _push('Connection lost', TelemetryNotificationLevel.alert);
        }
      case TransportState.reconnecting:
        _push('Reconnecting…', TelemetryNotificationLevel.warning);
      case TransportState.connecting:
      case TransportState.handshaking:
        break;
    }
    notifyListeners();
  }

  void push(String message, TelemetryNotificationLevel level) {
    _push(message, level);
    notifyListeners();
  }

  void _push(String message, TelemetryNotificationLevel level) {
    _items.insert(
      0,
      TelemetryNotification(
        message: message,
        timestamp: _clock(),
        level: level,
      ),
    );
    if (_items.length > 30) {
      _items.removeRange(30, _items.length);
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
