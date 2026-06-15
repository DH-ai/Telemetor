import 'package:fl_chart/fl_chart.dart';

/// Largest-Triangle-Three-Buckets downsampling.
///
/// Reduces [data] (assumed sorted by x) to at most [threshold] points while
/// preserving the visual shape of the line. The first and last points are
/// always kept.
List<FlSpot> lttbDecimate(List<FlSpot> data, int threshold) {
  if (threshold <= 2 || data.length <= threshold) {
    return data;
  }

  final sampled = <FlSpot>[data.first];
  // Bucket size for everything between the fixed first and last points.
  final bucketSize = (data.length - 2) / (threshold - 2);
  var previousIndex = 0;

  for (var bucket = 0; bucket < threshold - 2; bucket++) {
    // Average point of the next bucket, used as the triangle's third vertex.
    var nextStart = ((bucket + 1) * bucketSize).floor() + 1;
    var nextEnd = ((bucket + 2) * bucketSize).floor() + 1;
    if (nextEnd > data.length) nextEnd = data.length;
    var avgX = 0.0, avgY = 0.0;
    final nextCount = nextEnd - nextStart;
    if (nextCount > 0) {
      for (var i = nextStart; i < nextEnd; i++) {
        avgX += data[i].x;
        avgY += data[i].y;
      }
      avgX /= nextCount;
      avgY /= nextCount;
    } else {
      avgX = data.last.x;
      avgY = data.last.y;
    }

    final rangeStart = (bucket * bucketSize).floor() + 1;
    var rangeEnd = ((bucket + 1) * bucketSize).floor() + 1;
    if (rangeEnd > data.length - 1) rangeEnd = data.length - 1;

    final anchor = data[previousIndex];
    var maxArea = -1.0;
    var chosenIndex = rangeStart;
    for (var i = rangeStart; i < rangeEnd; i++) {
      final area = ((anchor.x - avgX) * (data[i].y - anchor.y) -
              (anchor.x - data[i].x) * (avgY - anchor.y))
          .abs();
      if (area > maxArea) {
        maxArea = area;
        chosenIndex = i;
      }
    }
    sampled.add(data[chosenIndex]);
    previousIndex = chosenIndex;
  }

  sampled.add(data.last);
  return sampled;
}
