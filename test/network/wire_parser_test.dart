import 'package:flutter_test/flutter_test.dart';
import 'package:telemetor/src/network/wire_parser.dart';

void main() {
  group('WireParser.parseHeader', () {
    test('parses the simulated single-group header', () {
      const packet = "HEADERS['B', 'C', 'D', 'E']:TYPES['A']";
      expect(WireParser.isHeaderPacket(packet), isTrue);

      final channels = WireParser.parseHeader(packet)!;
      expect(channels.map((c) => c.name), ['B', 'C', 'D', 'E']);
      expect(channels.every((c) => c.type == 'A'), isTrue);
    });

    test('parses a multi-group rocket-style header', () {
      const packet =
          'HEADERS[\' time\', \' state\', \'lat(deg)\']:TYPES["b\'F\'", "b\'S\'"]';
      final channels = WireParser.parseHeader(packet)!;
      expect(channels.map((c) => c.name), ['time', 'state', 'lat(deg)']);
      // With several groups the positional mapping is unknown at header
      // time, so the type tag is left empty.
      expect(channels.every((c) => c.type == ''), isTrue);
    });

    test('returns null for non-header packets', () {
      expect(WireParser.parseHeader('ACK-CONNECT'), isNull);
      expect(WireParser.isHeaderPacket('ACK-CONNECT'), isFalse);
    });
  });

  group('WireParser.parseDataFrame', () {
    test('parses a single-row frame with its ack number', () {
      final parsed =
          WireParser.parseDataFrame("[['1', '67', '6']]::ACK(4)")!;
      expect(parsed.ackNumber, 4);
      expect(parsed.rows, [
        ['1', '67', '6'],
      ]);
    });

    test('parses multiple row groups in one frame', () {
      final parsed = WireParser.parseDataFrame(
          "[['1', '2'], ['3', '4'], ['5', '6']]::ACK(12)")!;
      expect(parsed.ackNumber, 12);
      expect(parsed.rows, [
        ['1', '2'],
        ['3', '4'],
        ['5', '6'],
      ]);
    });

    test('keeps python byte-string tags intact', () {
      final parsed = WireParser.parseDataFrame(
          '[["b\'S\'", \'32\', \'56\']]::ACK(0)')!;
      expect(parsed.rows.single.first, "b'S'");
    });

    test('returns null for malformed frames', () {
      expect(WireParser.parseDataFrame('ACK-CONNECT'), isNull);
      expect(WireParser.parseDataFrame("[['1']]"), isNull);
      expect(WireParser.parseDataFrame('::ACK(3)'), isNull);
    });

    test('handles an empty payload', () {
      final parsed = WireParser.parseDataFrame('[]::ACK(7)')!;
      expect(parsed.ackNumber, 7);
      expect(parsed.rows, isEmpty);
    });
  });
}
