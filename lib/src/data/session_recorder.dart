import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../telemetor_ui/telemetor_ui.dart';
import '../data/notification_feed.dart';
import '../models/recorded_session.dart';
import '../models/telemetry_sample.dart';
import 'telemetry_hub.dart';

/// Records hub samples to CSV, lists sessions on disk, and replays them.
class SessionRecorder extends ChangeNotifier {
  SessionRecorder(
    this.hub, {
    NotificationFeed? notifications,
    DateTime Function()? clock,
  })  : _notifications = notifications,
        _clock = clock ?? DateTime.now {
    _loadSessionsFromDisk();
  }

  final TelemetryHub hub;
  final NotificationFeed? _notifications;
  final DateTime Function() _clock;

  final List<_RecordedRow> _buffer = [];
  final List<StreamSubscription<TelemetrySample>> _subscriptions = [];
  final List<RecordedSession> _sessions = [];

  Timer? _replayTimer;
  List<_RecordedRow> _replayQueue = [];

  bool _recording = false;
  bool _replaying = false;
  String? _activeSessionId;

  bool get isRecording => _recording;
  bool get isReplaying => _replaying;
  List<RecordedSession> get sessions => List.unmodifiable(_sessions);
  int get bufferedSampleCount => _buffer.length;

  Directory get _sessionsDir {
    final home = Platform.environment['HOME'] ?? '.';
    return Directory('$home/.local/share/telemetor/sessions');
  }

  /// Begin capturing all named hub channels into memory.
  void startRecording() {
    if (_recording || _replaying) return;
    _buffer.clear();
    _activeSessionId = _newSessionId();
    _recording = true;
    _resubscribe();
    hub.channelsNotifier.addListener(_resubscribe);
    _notifications?.push('Recording started', TelemetryNotificationLevel.info);
    notifyListeners();
  }

  /// Stop capture and persist to disk.
  Future<RecordedSession?> stopRecording() async {
    if (!_recording) return null;
    _recording = false;
    hub.channelsNotifier.removeListener(_resubscribe);
    _unsubscribe();

    if (_buffer.isEmpty) {
      _notifications?.push(
        'Recording empty — nothing saved',
        TelemetryNotificationLevel.warning,
      );
      notifyListeners();
      return null;
    }

    final session = await _writeSession(_activeSessionId!, _buffer);
    _sessions.insert(0, session);
    _buffer.clear();
    _activeSessionId = null;
    _notifications?.push(
      'Recording saved (${session.formattedSize})',
      TelemetryNotificationLevel.info,
    );
    notifyListeners();
    return session;
  }

  /// Copy [session] to ~/Downloads.
  Future<String?> exportSession(RecordedSession session) async {
    final home = Platform.environment['HOME'] ?? '.';
    final downloads = Directory('$home/Downloads');
    if (!await downloads.exists()) {
      await downloads.create(recursive: true);
    }
    final dest = File(
      '${downloads.path}/telemetor_${session.id}.csv',
    );
    await File(session.filePath).copy(dest.path);
    _notifications?.push(
      'Exported to ${dest.path}',
      TelemetryNotificationLevel.info,
    );
    return dest.path;
  }

  /// Export the in-progress buffer or the most recent session.
  Future<String?> exportLatest() async {
    if (_recording && _buffer.isNotEmpty) {
      final id = _activeSessionId ?? _newSessionId();
      final session = await _writeSession(id, List.of(_buffer));
      if (!_recording) {
        _sessions.insert(0, session);
      }
      return exportSession(session);
    }
    if (_sessions.isEmpty) return null;
    return exportSession(_sessions.first);
  }

  /// Replay [session] into the hub at real-time pacing.
  Future<void> replay(RecordedSession session) async {
    stopReplay();
    final rows = await _readSession(session.filePath);
    if (rows.isEmpty) return;

    _replaying = true;
    _replayQueue = rows;
    notifyListeners();

    _notifications?.push(
      'Replaying ${session.name}',
      TelemetryNotificationLevel.info,
    );

    var index = 0;
    _replayTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (index >= _replayQueue.length) {
        stopReplay();
        _notifications?.push(
          'Replay finished',
          TelemetryNotificationLevel.info,
        );
        return;
      }

      final batchEnd = (index + 20).clamp(0, _replayQueue.length);
      for (var i = index; i < batchEnd; i++) {
        final row = _replayQueue[i];
        hub.injectSample(
          row.channel,
          TelemetrySample(timestamp: row.timestamp, value: row.value),
        );
      }
      index = batchEnd;
    });
  }

  void stopReplay() {
    _replayTimer?.cancel();
    _replayTimer = null;
    _replayQueue = [];
    if (_replaying) {
      _replaying = false;
      notifyListeners();
    }
  }

  void _resubscribe() {
    if (!_recording) return;
    _unsubscribe();
    for (final channel in hub.channels) {
      if (channel.name.trim().isEmpty) continue;
      _subscriptions.add(hub.stream(channel.name).listen((sample) {
        _buffer.add(_RecordedRow(
          timestamp: sample.timestamp,
          channel: channel.name,
          value: sample.value,
        ));
      }));
    }
  }

  void _unsubscribe() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  Future<RecordedSession> _writeSession(
    String id,
    List<_RecordedRow> rows,
  ) async {
    final dir = _sessionsDir;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final path = '${dir.path}/$id.csv';
    final file = File(path);
    final sink = file.openWrite();
    sink.writeln('timestamp_ms,channel,value');
    for (final row in rows) {
      sink.writeln(
        '${row.timestamp.millisecondsSinceEpoch},${row.channel},${row.value}',
      );
    }
    await sink.close();
    final size = await file.length();

    return RecordedSession(
      id: id,
      name: id,
      recordedAt: _clock(),
      filePath: path,
      byteSize: size,
      sampleCount: rows.length,
    );
  }

  Future<List<_RecordedRow>> _readSession(String path) async {
    final file = File(path);
    if (!await file.exists()) return [];

    final rows = <_RecordedRow>[];
    final lines = await file.readAsLines();
    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length < 3) continue;
      final ms = int.tryParse(parts[0]);
      final value = double.tryParse(parts[2]);
      if (ms == null || value == null) continue;
      rows.add(_RecordedRow(
        timestamp: DateTime.fromMillisecondsSinceEpoch(ms),
        channel: parts[1],
        value: value,
      ));
    }
    return rows;
  }

  void _loadSessionsFromDisk() {
    _sessions.clear();
    final dir = _sessionsDir;
    if (!dir.existsSync()) return;

    for (final entity in dir.listSync().whereType<File>()) {
      if (!entity.path.endsWith('.csv')) continue;
      final id = entity.uri.pathSegments.last.replaceAll('.csv', '');
      final stat = entity.statSync();
      _sessions.add(RecordedSession(
        id: id,
        name: id,
        recordedAt: stat.modified,
        filePath: entity.path,
        byteSize: stat.size,
        sampleCount: 0,
      ));
    }
    _sessions.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  String _newSessionId() {
    final now = _clock();
    return 'SES-${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    stopReplay();
    hub.channelsNotifier.removeListener(_resubscribe);
    _unsubscribe();
    super.dispose();
  }
}

class _RecordedRow {
  const _RecordedRow({
    required this.timestamp,
    required this.channel,
    required this.value,
  });

  final DateTime timestamp;
  final String channel;
  final double value;
}
