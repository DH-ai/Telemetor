import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../telemetor_ui/telemetor_ui.dart';

import '../data/ring_buffer.dart';
import '../data/telemetry_hub.dart';
import '../models/telemetry_channel.dart';
import '../models/telemetry_sample.dart';
import 'lttb.dart';

/// Reusable multi-series live telemetry chart.
///
/// Subscribes to one hub stream per channel, keeps samples in per-series
/// ring buffers, shows a sliding time window with auto-scaling axes, and
/// decimates with LTTB so at most [maxPoints] points per series reach
/// fl_chart. All visual styling comes from [TDLChartStyle].
class TelemetryChart extends StatefulWidget {
  const TelemetryChart({
    super.key,
    required this.hub,
    required this.channels,
    required this.title,
    this.unit = '',
    this.showLegend = true,
    this.timeWindow = const Duration(seconds: 60),
    this.maxPoints = 2000,
    this.bufferCapacity = 8192,
    this.minRepaintInterval = const Duration(milliseconds: 33),
    this.enableTouch = true,
  });

  final TelemetryHub hub;
  final List<TelemetryChannel> channels;
  final String title;
  final String unit;
  final bool showLegend;
  final Duration timeWindow;
  final int maxPoints;
  final int bufferCapacity;
  final Duration minRepaintInterval;
  final bool enableTouch;

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
    final style = TDLChartStyle.of(context);
    final hasData = _buffers.values.any((b) => b.isNotEmpty);
    final headerTitle = widget.unit.isEmpty
        ? widget.title
        : '${widget.title} (${widget.unit})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (headerTitle.isNotEmpty || widget.showLegend)
          Padding(
            padding: style.headerPadding,
            child: Row(
              children: [
                if (headerTitle.isNotEmpty)
                  Expanded(
                    child: Text(
                      headerTitle.toUpperCase(),
                      style: style.titleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (widget.showLegend && widget.channels.length > 1)
                  TDLChartLegend(
                    labels: [
                      for (final c in widget.channels) c.name,
                    ],
                    style: style,
                  ),
              ],
            ),
          ),
        Expanded(
          child: Padding(
            padding: style.chartPadding,
            child: RepaintBoundary(
              child: hasData
                  ? LineChart(
                      _buildChartData(style),
                      duration: Duration.zero,
                    )
                  : Center(
                      child: Text(
                        'Waiting for data…',
                        style: style.emptyStateStyle,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(TDLChartStyle style) {
    var newestMs = 0;
    for (final buffer in _buffers.values) {
      if (buffer.isNotEmpty) {
        newestMs = math.max(
          newestMs,
          buffer[buffer.length - 1].timestamp.millisecondsSinceEpoch,
        );
      }
    }
    final windowEnd = newestMs / 1000.0;
    final windowStart =
        windowEnd - widget.timeWindow.inMilliseconds / 1000.0;

    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    final series = <LineChartBarData>[];
    final labels = <String>[];
    final seriesColors = <Color>[];

    for (var i = 0; i < widget.channels.length; i++) {
      final channel = widget.channels[i];
      final buffer = _buffers[channel.name];
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

      labels.add(channel.name);
      seriesColors.add(style.seriesColor(i));
      series.add(
        style.seriesBar(
          spots: lttbDecimate(spots, widget.maxPoints),
          colorIndex: i,
        ),
      );
    }

    if (!minY.isFinite) {
      minY = 0;
      maxY = 1;
    }
    if (minY == maxY) {
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
      titlesData: style.titlesData(timeWindow: widget.timeWindow),
      gridData: style.gridData(),
      borderData: style.borderData(),
      lineTouchData: widget.enableTouch
          ? style.lineTouchData(
              seriesLabels: labels,
              seriesColors: seriesColors,
            )
          : const LineTouchData(enabled: false),
      lineBarsData: series,
    );
  }
}
