import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/telemetry_sample.dart';

/// Prototype line chart fed by a channel's sample stream; plots value
/// against sample index. Replaced by the reusable TelemetryChart in G1-M4.
class AltitudeChart extends StatefulWidget {
  const AltitudeChart({super.key, required this.sampleStream});

  final Stream<TelemetrySample> sampleStream;

  @override
  State<AltitudeChart> createState() => _AltitudeChartState();
}

class _AltitudeChartState extends State<AltitudeChart> {
  final List<FlSpot> _dataPoints = [];
  StreamSubscription<TelemetrySample>? _subscription;
  int _index = 0;

  static const double _yMin = 0;
  static const double _yMax = 100;
  static const double _xMin = 0;
  static const double _xMax = 100;

  @override
  void initState() {
    super.initState();
    _subscription = widget.sampleStream.listen((sample) {
      setState(() {
        _dataPoints.add(FlSpot(_index.toDouble(), sample.value));
        _index++;
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
