import 'package:flutter/foundation.dart';

/// A single telemetry data series, e.g. "altitude" or "gyro_x".
@immutable
class TelemetryChannel {
  const TelemetryChannel({
    required this.name,
    this.type = '',
    this.unit = '',
  });

  /// Unique channel name, e.g. "temperature".
  final String name;

  /// Group/type tag this channel belongs to on the wire, e.g. "b'F'".
  /// Rows arriving with this tag carry values for this channel.
  final String type;

  /// Display unit, e.g. "m/s". Empty when unknown.
  final String unit;

  @override
  bool operator ==(Object other) =>
      other is TelemetryChannel &&
      other.name == name &&
      other.type == type &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(name, type, unit);

  @override
  String toString() => 'TelemetryChannel($name, type: $type, unit: $unit)';
}
