import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetor/src/charts/lttb.dart';

List<FlSpot> sineWave(int count) => [
      for (var i = 0; i < count; i++)
        FlSpot(i.toDouble(), math.sin(i / 20) * 100),
    ];

void main() {
  test('returns data untouched when already below the threshold', () {
    final data = sineWave(100);
    expect(lttbDecimate(data, 200), same(data));
    expect(lttbDecimate(data, 100), same(data));
  });

  test('reduces to exactly the threshold', () {
    final data = sineWave(10000);
    final result = lttbDecimate(data, 2000);
    expect(result.length, 2000);
  });

  test('always keeps the first and last points', () {
    final data = sineWave(5000);
    final result = lttbDecimate(data, 100);
    expect(result.first, data.first);
    expect(result.last, data.last);
  });

  test('keeps x strictly increasing', () {
    final data = sineWave(5000);
    final result = lttbDecimate(data, 250);
    for (var i = 1; i < result.length; i++) {
      expect(result[i].x, greaterThan(result[i - 1].x));
    }
  });

  test('keeps extreme outliers (visual shape preservation)', () {
    final data = sineWave(5000);
    data[2500] = const FlSpot(2500, 100000);
    final result = lttbDecimate(data, 100);
    expect(result.any((spot) => spot.y == 100000), isTrue);
  });

  test('handles tiny thresholds by returning the input', () {
    final data = sineWave(50);
    expect(lttbDecimate(data, 2), same(data));
  });
}
