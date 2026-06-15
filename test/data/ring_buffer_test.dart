import 'package:flutter_test/flutter_test.dart';
import 'package:telemetor/src/data/ring_buffer.dart';

void main() {
  test('stores items in insertion order while below capacity', () {
    final buffer = RingBuffer<int>(4);
    buffer.add(1);
    buffer.add(2);
    buffer.add(3);

    expect(buffer.length, 3);
    expect(buffer.isFull, isFalse);
    expect(buffer.toList(), [1, 2, 3]);
    expect(buffer[0], 1);
    expect(buffer[2], 3);
  });

  test('overwrites the oldest items when full', () {
    final buffer = RingBuffer<int>(3);
    for (var i = 1; i <= 5; i++) {
      buffer.add(i);
    }

    expect(buffer.length, 3);
    expect(buffer.isFull, isTrue);
    expect(buffer.toList(), [3, 4, 5]);
    expect(buffer[0], 3);
    expect(buffer[2], 5);
  });

  test('keeps wrapping correctly far beyond capacity', () {
    final buffer = RingBuffer<int>(2);
    for (var i = 0; i < 101; i++) {
      buffer.add(i);
    }
    expect(buffer.toList(), [99, 100]);
  });

  test('clear empties the buffer and allows reuse', () {
    final buffer = RingBuffer<int>(2);
    buffer.add(1);
    buffer.add(2);
    buffer.clear();

    expect(buffer.length, 0);
    expect(buffer.toList(), isEmpty);
    buffer.add(7);
    expect(buffer.toList(), [7]);
  });

  test('index access is range checked', () {
    final buffer = RingBuffer<int>(2);
    buffer.add(1);
    expect(() => buffer[1], throwsRangeError);
  });
}
