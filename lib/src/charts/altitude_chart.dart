import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Prototype line chart fed by a stream of parsed data rows.
/// Replaced by the reusable TelemetryChart in G1-M4.
class AltitudeChart extends StatefulWidget {
  const AltitudeChart({super.key, required this.dataStream});

  final Stream<List<int>> dataStream;

  @override
  State<AltitudeChart> createState() => _AltitudeChartState();
}

class _AltitudeChartState extends State<AltitudeChart> {
  final List<FlSpot> _dataPoints = [];
  StreamSubscription<List<int>>? _subscription;

  static const double _yMin = 0;
  static const double _yMax = 100;
  static const double _xMin = 0;
  static const double _xMax = 100;

  @override
  void initState() {
    super.initState();
    _subscription = widget.dataStream.listen((event) {
      if (event.length < 2) return;
      setState(() {
        _dataPoints.add(FlSpot(event[0].toDouble(), event[1].toDouble()));
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minX: _xMin,
        maxX: _xMax,
        minY: _yMin,
        maxY: _yMax,
        lineBarsData: [
          LineChartBarData(
            spots: _dataPoints,
            isCurved: true,
            color: Colors.red,
            barWidth: 1,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
