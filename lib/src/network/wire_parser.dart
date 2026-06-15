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

  /// End offset (exclusive) of the header inside [packet], or -1 when no
  /// complete header is present. Lets stream buffers consume exactly the
  /// header and keep whatever follows.
  static int headerEnd(String packet) =>
      _headerPattern.firstMatch(packet)?.end ?? -1;

  /// Parses the header packet into channels.
  ///
  /// The server concatenates one header row per type tag (minus the tag
  /// column itself), all rows padded to the same CSV width. With a single
  /// tag every channel gets it. With several tags the name list is split
  /// evenly and each segment is assigned its tag positionally, preserving
  /// empty padding names so that data rows keep their column alignment
  /// (consumers should hide channels with empty names).
  static List<TelemetryChannel>? parseHeader(String packet) {
    final match = _headerPattern.firstMatch(packet);
    if (match == null) return null;
    final names = _parsePythonList(match.group(1)!);
    final types =
        _parsePythonList(match.group(2)!).where((t) => t.isNotEmpty).toList();
    if (names.isEmpty) return null;

    if (types.length > 1 && names.length % types.length == 0) {
      final groupSize = names.length ~/ types.length;
      return [
        for (var i = 0; i < names.length; i++)
          TelemetryChannel(name: names[i], type: types[i ~/ groupSize]),
      ];
    }
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
  /// Empty items are preserved (as empty strings) so positional column
  /// alignment with data rows survives padded CSV columns.
  static List<String> _parsePythonList(String inner) {
    if (inner.trim().isEmpty) return const [];
    final items = <String>[];
    for (var item in inner.split(',')) {
      item = item.trim();
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
