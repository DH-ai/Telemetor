import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/ring_buffer.dart';
import '../data/telemetry_hub.dart';
import '../models/telemetry_channel.dart';
import '../models/telemetry_sample.dart';
import 'lttb.dart';

/// Default series palette; cycles when there are more series than colors.
const List<Color> kDefaultChartPalette = [
  Color(0xff1ccc9d),
  Color(0xff4f8cff),
  Color(0xffff7043),
  Color(0xffba68c8),
  Color(0xffffd54f),
  Color(0xff4dd0e1),
  Color(0xfff06292),
  Color(0xffaed581),
];

/// Reusable multi-series live telemetry chart.
///
/// Subscribes to one hub stream per channel, keeps samples in per-series
/// ring buffers, shows a sliding time window with auto-scaling axes, and
/// decimates with LTTB so at most [maxPoints] points per series reach
/// fl_chart. Repaints are throttled to [minRepaintInterval] (default 30 fps)
/// and isolated behind a [RepaintBoundary].
class TelemetryChart extends StatefulWidget {
  const TelemetryChart({
    super.key,
    required this.hub,
    required this.channels,
    required this.title,
    this.unit = '',
    this.showLegend = true,
    this.palette = kDefaultChartPalette,
    this.timeWindow = const Duration(seconds: 60),
    this.maxPoints = 2000,
    this.bufferCapacity = 8192,
    this.minRepaintInterval = const Duration(milliseconds: 33),
  });

  final TelemetryHub hub;

  /// Channels plotted as separate series, in palette order.
  final List<TelemetryChannel> channels;

  final String title;
  final String unit;
  final bool showLegend;
  final List<Color> palette;

  /// Width of the sliding x-axis window.
  final Duration timeWindow;

  /// Maximum points per series handed to fl_chart after decimation.
  final int maxPoints;

  /// Raw samples retained per series.
  final int bufferCapacity;

  /// Minimum delay between repaints (default ~30 fps).
  final Duration minRepaintInterval;

  @override
  State<TelemetryChart> createState() => _TelemetryChartState();
}

class _TelemetryChartState extends State<TelemetryChart> {
  final Map<String, RingBuffer<TelemetrySample>> _buffers = {};
  final List<StreamSubscription<TelemetrySample>> _subscriptions = [];
  Timer? _repaintTimer;
  DateTime _lastPaint = DateTime.fromMillisecondsSinceEpoch(0);
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(TelemetryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldNames = oldWidget.channels.map((c) => c.name).toList();
    final newNames = widget.channels.map((c) => c.name).toList();
    if (oldNames.toString() != newNames.toString() ||
        oldWidget.hub != widget.hub) {
      _unsubscribe();
      _buffers.removeWhere((name, _) => !newNames.contains(name));
      _subscribe();
    }
  }

  void _subscribe() {
    for (final channel in widget.channels) {
      _buffers.putIfAbsent(
          channel.name, () => RingBuffer(widget.bufferCapacity));
      _subscriptions.add(widget.hub.stream(channel.name).listen((sample) {
        _buffers[channel.name]!.add(sample);
        _markDirty();
      }));
    }
  }

  void _unsubscribe() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Coalesces bursts of samples into at most one repaint per
  /// [TelemetryChart.minRepaintInterval].
  void _markDirty() {
    _dirty = true;
    if (_repaintTimer?.isActive ?? false) return;
    final sinceLast = DateTime.now().difference(_lastPaint);
    final wait = sinceLast >= widget.minRepaintInterval
        ? Duration.zero
        : widget.minRepaintInterval - sinceLast;
    _repaintTimer = Timer(wait, () {
      if (!mounted || !_dirty) return;
      setState(() {
        _dirty = false;
        _lastPaint = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _repaintTimer?.cancel();
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = _buffers.values.any((b) => b.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.unit.isEmpty
                      ? widget.title
                      : '${widget.title} (${widget.unit})',
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.showLegend) _Legend(widget: widget),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 8),
            child: RepaintBoundary(
              child: hasData
                  ? LineChart(_buildChartData(theme), duration: Duration.zero)
                  : Center(
                      child: Text(
                        'Waiting for data…',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(ThemeData theme) {
    // The window ends at the newest visible sample across all series.
    var newestMs = 0;
    for (final buffer in _buffers.values) {
      if (buffer.isNotEmpty) {
        newestMs =
            math.max(newestMs, buffer[buffer.length - 1].timestamp.millisecondsSinceEpoch);
      }
    }
    final windowEnd = newestMs / 1000.0;
    final windowStart =
        windowEnd - widget.timeWindow.inMilliseconds / 1000.0;

    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    final series = <LineChartBarData>[];

    for (var i = 0; i < widget.channels.length; i++) {
      final buffer = _buffers[widget.channels[i].name];
      if (buffer == null || buffer.isEmpty) continue;

      final spots = <FlSpot>[];
      for (final sample in buffer) {
        final x = sample.timestamp.millisecondsSinceEpoch / 1000.0;
        if (x < windowStart) continue;
        spots.add(FlSpot(x - windowStart, sample.value));
        minY = math.min(minY, sample.value);
        maxY = math.max(maxY, sample.value);
      }
      if (spots.isEmpty) continue;

      series.add(LineChartBarData(
        spots: lttbDecimate(spots, widget.maxPoints),
        color: widget.palette[i % widget.palette.length],
        barWidth: 1.5,
        isCurved: false,
        dotData: const FlDotData(show: false),
      ));
    }

    if (!minY.isFinite) {
      minY = 0;
      maxY = 1;
    }
    if (minY == maxY) {
      // Flat line: give the axis some height so it renders.
      minY -= 1;
      maxY += 1;
    } else {
      final padding = (maxY - minY) * 0.05;
      minY -= padding;
      maxY += padding;
    }

    return LineChartData(
      minX: 0,
      maxX: widget.timeWindow.inMilliseconds / 1000.0,
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (value, meta) {
              final secondsAgo =
                  widget.timeWindow.inMilliseconds / 1000.0 - value;
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  '-${secondsAgo.toStringAsFixed(0)}s',
                  style: theme.textTheme.labelSmall,
                ),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 44),
        ),
      ),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: series,
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.widget});

  final TelemetryChart widget;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        for (var i = 0; i < widget.channels.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.palette[i % widget.palette.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.channels[i].name,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
      ],
    );
  }
}
