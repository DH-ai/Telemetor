import '../models/telemetry_channel.dart';

/// Pure parsing helpers for the TCP+ACK wire protocol (Backend/ACK.md).
///
/// Header packet:  HEADERS['name', ...]:TYPES["b'F'", ...]
/// Data frame:     [['v', ...], ['v', ...]]::ACK(n)  (one or more row groups)
abstract final class WireParser {
  static final RegExp _headerPattern =
      RegExp(r'HEADERS\[(.*?)\]:TYPES\[(.*?)\]');
  static final RegExp _dataFramePattern = RegExp(r'\[(.*)\]::ACK\((\d+)\)');
  static final RegExp _rowGroupPattern = RegExp(r'\[(.*?)\]');

  static bool isHeaderPacket(String packet) =>
      _headerPattern.hasMatch(packet);

  /// Parses the header packet into channels.
  ///
  /// The server sends Python-repr lists. Channel names map onto type tags
  /// positionally only when the backend provides that mapping; with the
  /// current frozen protocol the tags identify row groups, so every channel
  /// gets the single tag when there is one, otherwise tags are matched to
  /// rows at ingest time via [TelemetryChannel.type] being empty.
  static List<TelemetryChannel>? parseHeader(String packet) {
    final match = _headerPattern.firstMatch(packet);
    if (match == null) return null;
    final names = _parsePythonList(match.group(1)!);
    final types = _parsePythonList(match.group(2)!);
    if (names.isEmpty) return null;
    final singleType = types.length == 1 ? types.first : '';
    return [
      for (final name in names)
        TelemetryChannel(name: name, type: singleType),
    ];
  }

  /// Splits a data frame into its ACK number and row groups.
  /// Returns null if the frame is malformed.
  static ({int ackNumber, List<List<String>> rows})? parseDataFrame(
      String frame) {
    final match = _dataFramePattern.firstMatch(frame);
    if (match == null) return null;
    final ackNumber = int.parse(match.group(2)!);
    final payload = match.group(1)!;
    final rows = <List<String>>[];
    for (final group in _rowGroupPattern.allMatches(payload)) {
      final inner = group.group(1)!;
      if (inner.isEmpty) continue;
      rows.add(_parsePythonList(inner));
    }
    return (ackNumber: ackNumber, rows: rows);
  }

  /// Parses `'a', "b", c` into `[a, b, c]`, stripping quotes and whitespace.
  /// Items like `b'F'` keep their full form (`b'F'`) so tags stay distinct.
  static List<String> _parsePythonList(String inner) {
    final items = <String>[];
    for (var item in inner.split(',')) {
      item = item.trim();
      if (item.isEmpty) continue;
      if (item.length >= 2 &&
          ((item.startsWith("'") && item.endsWith("'")) ||
              (item.startsWith('"') && item.endsWith('"')))) {
        item = item.substring(1, item.length - 1).trim();
      }
      items.add(item);
    }
    return items;
  }
}
