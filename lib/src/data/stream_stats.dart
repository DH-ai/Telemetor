import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/telemetry_transport.dart';

/// Live statistics about the incoming packet stream: row rate, totals and
/// dropped frames (detected via gaps in the ACK sequence).
class StreamStats {
  StreamStats(TelemetryTransport transport, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _subscription = transport.packets.listen(_onPacket);
    // 1 Hz UI refresh so the displayed rate decays to zero when the
    // stream goes quiet (the data path itself stays event-driven).
    _refreshTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => _recomputeRate());
  }

  static const _rateWindow = Duration(seconds: 5);

  final DateTime Function() _clock;
  late final StreamSubscription<TelemetryPacket> _subscription;
  Timer? _refreshTimer;

  final List<(DateTime, int)> _rowEvents = [];
  int? _lastAckNumber;

  /// Data rows per second, averaged over the last [_rateWindow].
  final ValueNotifier<double> rowsPerSecond = ValueNotifier(0);

  /// Total data rows received this run.
  final ValueNotifier<int> totalRows = ValueNotifier(0);

  /// Frames the server sent that we never saw (ACK sequence gaps).
  final ValueNotifier<int> droppedFrames = ValueNotifier(0);

  void _onPacket(TelemetryPacket packet) {
    switch (packet) {
      case HeaderPacket():
        // New session: the server's ACK numbering restarts.
        _lastAckNumber = null;
      case DataPacket(:final ackNumber, :final rows):
        final last = _lastAckNumber;
        if (last != null && ackNumber > last + 1) {
          droppedFrames.value += ackNumber - last - 1;
        }
        // Retransmissions reuse the previous number; never go backwards.
        if (last == null || ackNumber > last) {
          _lastAckNumber = ackNumber;
        }
        totalRows.value += rows.length;
        _rowEvents.add((_clock(), rows.length));
        _recomputeRate();
    }
  }

  void _recomputeRate() {
    final cutoff = _clock().subtract(_rateWindow);
    _rowEvents.removeWhere((event) => event.$1.isBefore(cutoff));
    var rows = 0;
    for (final event in _rowEvents) {
      rows += event.$2;
    }
    rowsPerSecond.value = rows / _rateWindow.inSeconds;
  }

  void dispose() {
    _refreshTimer?.cancel();
    _subscription.cancel();
    rowsPerSecond.dispose();
    totalRows.dispose();
    droppedFrames.dispose();
  }
}
