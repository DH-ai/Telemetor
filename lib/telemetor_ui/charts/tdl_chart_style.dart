import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../tdl_context.dart';
import '../tokens/borders.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../typography/text_styles.dart';

/// Chart styling derived from TDL tokens — axes, grid, touch, and series colors.
///
/// Use [TDLChartStyle.of] inside any fl_chart builder. No chart-specific hex
/// values should appear outside theme definitions.
class TDLChartStyle {
  const TDLChartStyle({
    required this.colors,
    required this.text,
  });

  final TDLColors colors;
  final TDLTextStyles text;

  factory TDLChartStyle.of(BuildContext context) => TDLChartStyle(
        colors: context.tdlColors,
        text: context.tdlText,
      );

  static const double lineWidth = 1.5;
  static const double axisReservedLeft = 44;
  static const double axisReservedBottom = 24;
  static const double crosshairWidth = 1;

  EdgeInsets get chartPadding => const EdgeInsets.fromLTRB(
        TDLSpacing.sm,
        0,
        TDLSpacing.md,
        TDLSpacing.sm,
      );

  EdgeInsets get headerPadding => TDLSpacing.panelHeader;

  TextStyle get axisLabelStyle =>
      text.monoSmall.copyWith(color: colors.chartAxis);

  TextStyle get titleStyle =>
      text.sectionTitle.copyWith(color: colors.textPrimary);

  TextStyle get emptyStateStyle => text.caption;

  Color seriesColor(int index) =>
      colors.chartSeries[index % colors.chartSeries.length];

  FlGridData gridData() => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: colors.chartGrid,
          strokeWidth: TDLBorders.thin,
        ),
      );

  FlBorderData borderData() => FlBorderData(
        show: true,
        border: Border(
          left: TDLBorders.side(colors),
          bottom: TDLBorders.side(colors),
        ),
      );

  FlTitlesData titlesData({
    required Duration timeWindow,
    String Function(double yValue)? formatY,
  }) {
    String formatYDefault(double value) {
      if (value == value.roundToDouble() && value.abs() < 1e6) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(1);
    }

    final formatYFn = formatY ?? formatYDefault;

    return FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: axisReservedBottom,
          interval: math.max(timeWindow.inSeconds / 4, 1).toDouble(),
          getTitlesWidget: (value, meta) {
            final secondsAgo = timeWindow.inMilliseconds / 1000.0 - value;
            if (secondsAgo < 0) return const SizedBox.shrink();
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                '-${secondsAgo.toStringAsFixed(0)}s',
                style: axisLabelStyle,
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: axisReservedLeft,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            axisSide: meta.axisSide,
            child: Text(formatYFn(value), style: axisLabelStyle),
          ),
        ),
      ),
    );
  }

  LineTouchData lineTouchData({
  required List<String> seriesLabels,
  required List<Color> seriesColors,
  String Function(double y)? formatValue,
  }) {
    String format(double value) {
      if (formatValue != null) return formatValue(value);
      if (value == value.roundToDouble() && value.abs() < 1e9) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }

    return LineTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => colors.panelElevated,
        tooltipBorder: BorderSide(color: colors.borderPrimary),
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final index = spot.barIndex.clamp(0, seriesLabels.length - 1);
            final label = seriesLabels[index];
            final color = seriesColors[index % seriesColors.length];
            return LineTooltipItem(
              '$label\n${format(spot.y)}',
              text.mono.copyWith(color: color),
            );
          }).toList();
        },
      ),
      getTouchedSpotIndicator: (barData, spotIndexes) {
        return spotIndexes
            .map(
              (_) => TouchedSpotIndicatorData(
                FlLine(
                  color: colors.chartCrosshair.withValues(alpha: 0.5),
                  strokeWidth: crosshairWidth,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: bar.color ?? colors.accent,
                    strokeWidth: 1,
                    strokeColor: colors.textPrimary,
                  ),
                ),
              ),
            )
            .toList();
      },
    );
  }

  LineChartBarData seriesBar({
    required List<FlSpot> spots,
    required int colorIndex,
    bool curved = false,
  }) =>
      LineChartBarData(
        spots: spots,
        color: seriesColor(colorIndex),
        barWidth: lineWidth,
        isCurved: curved,
        dotData: const FlDotData(show: false),
      );
}
