import 'package:flutter/foundation.dart';

/// One timestamped value on a telemetry channel.
@immutable
class TelemetrySample {
  const TelemetrySample({required this.timestamp, required this.value});

  final DateTime timestamp;
  final double value;

  @override
  bool operator ==(Object other) =>
      other is TelemetrySample &&
      other.timestamp == timestamp &&
      other.value == value;

  @override
  int get hashCode => Object.hash(timestamp, value);

  @override
  String toString() => 'TelemetrySample($value @ $timestamp)';
}
