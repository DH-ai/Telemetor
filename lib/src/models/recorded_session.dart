import 'package:flutter/foundation.dart';

/// Metadata for a recorded telemetry session on disk.
@immutable
class RecordedSession {
  const RecordedSession({
    required this.id,
    required this.name,
    required this.recordedAt,
    required this.filePath,
    required this.byteSize,
    required this.sampleCount,
  });

  final String id;
  final String name;
  final DateTime recordedAt;
  final String filePath;
  final int byteSize;
  final int sampleCount;

  String get formattedDate =>
      '${recordedAt.year}-${recordedAt.month.toString().padLeft(2, '0')}-'
      '${recordedAt.day.toString().padLeft(2, '0')}';

  String get formattedSize {
    if (byteSize < 1024) return '$byteSize B';
    if (byteSize < 1024 * 1024) {
      return '${(byteSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(byteSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
