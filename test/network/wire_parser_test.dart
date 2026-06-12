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

    test('splits a multi-group rocket-style header evenly across tags', () {
      // Two header rows of equal CSV width (incl. padding columns).
      const packet = 'HEADERS[\' time\', \' alt\', \'\', '
          '\'lat(deg)\', \'lon(deg)\', \'\']:TYPES["b\'F\'", "b\'S\'"]';
      final channels = WireParser.parseHeader(packet)!;

      expect(channels.length, 6);
      expect(channels.map((c) => c.name),
          ['time', 'alt', '', 'lat(deg)', 'lon(deg)', '']);
      expect(channels.map((c) => c.type), [
        "b'F'", "b'F'", "b'F'", // first segment
        "b'S'", "b'S'", "b'S'", // second segment
      ]);
    });

    test('leaves types empty when groups cannot be split evenly', () {
      const packet =
          'HEADERS[\' time\', \' state\', \'lat(deg)\']:TYPES["b\'F\'", "b\'S\'"]';
      final channels = WireParser.parseHeader(packet)!;
      expect(channels.map((c) => c.name), ['time', 'state', 'lat(deg)']);
      expect(channels.every((c) => c.type == ''), isTrue);
    });

    test('preserves empty padding names for column alignment', () {
      const packet = "HEADERS['a', '', 'b']:TYPES['A']";
      final channels = WireParser.parseHeader(packet)!;
      expect(channels.map((c) => c.name), ['a', '', 'b']);
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
