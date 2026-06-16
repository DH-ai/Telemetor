import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../network/telemetry_transport.dart';

/// Tracks connection uptime and assigns a session id per connection.
class SessionTracker {
  SessionTracker(TelemetryTransport transport, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _subscription = transport.states.listen(_onState);
    _onState(transport.state);
  }

  final DateTime Function() _clock;
  late final StreamSubscription<TransportState> _subscription;
  Timer? _uptimeTimer;
  DateTime? _connectedAt;

  final ValueNotifier<Duration> uptime = ValueNotifier(Duration.zero);
  final ValueNotifier<String> sessionId = ValueNotifier('—');

  void _onState(TransportState state) {
    if (state == TransportState.connected) {
      _connectedAt = _clock();
      sessionId.value = _newSessionId();
      _uptimeTimer?.cancel();
      _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final start = _connectedAt;
        if (start != null) {
          uptime.value = _clock().difference(start);
        }
      });
      return;
    }

    _connectedAt = null;
    _uptimeTimer?.cancel();
    uptime.value = Duration.zero;
    if (state == TransportState.disconnected) {
      sessionId.value = '—';
    }
  }

  String _newSessionId() {
    final now = _clock();
    final suffix = Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    return 'SES-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$suffix';
  }

  void dispose() {
    _uptimeTimer?.cancel();
    _subscription.cancel();
    uptime.dispose();
    sessionId.dispose();
  }
}
