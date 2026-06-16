import 'package:flutter/material.dart';

/// Semantic color tokens for the Telemetor Design Language.
///
/// Registered as a [ThemeExtension] so themes swap tokens without touching
/// component code. Access via [TDLColors.of] or `context.tdlColors`.
@immutable
class TDLColors extends ThemeExtension<TDLColors> {
  const TDLColors({
    required this.background,
    required this.surface,
    required this.panel,
    required this.panelElevated,
    required this.borderPrimary,
    required this.borderSecondary,
    required this.borderFocus,
    required this.accent,
    required this.accentMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    required this.success,
    required this.warning,
    required this.error,
    required this.live,
    required this.chartGrid,
    required this.chartAxis,
    required this.chartCrosshair,
    required this.chartSeries,
    required this.navActive,
    required this.navInactive,
    required this.statusConnected,
    required this.statusDisconnected,
  });

  final Color background;
  final Color surface;
  final Color panel;
  final Color panelElevated;

  final Color borderPrimary;
  final Color borderSecondary;
  final Color borderFocus;

  final Color accent;
  final Color accentMuted;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnAccent;

  final Color success;
  final Color warning;
  final Color error;
  final Color live;

  final Color chartGrid;
  final Color chartAxis;
  final Color chartCrosshair;
  final List<Color> chartSeries;

  final Color navActive;
  final Color navInactive;

  final Color statusConnected;
  final Color statusDisconnected;

  static TDLColors of(BuildContext context) =>
      Theme.of(context).extension<TDLColors>()!;

  @override
  TDLColors copyWith({
    Color? background,
    Color? surface,
    Color? panel,
    Color? panelElevated,
    Color? borderPrimary,
    Color? borderSecondary,
    Color? borderFocus,
    Color? accent,
    Color? accentMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnAccent,
    Color? success,
    Color? warning,
    Color? error,
    Color? live,
    Color? chartGrid,
    Color? chartAxis,
    Color? chartCrosshair,
    List<Color>? chartSeries,
    Color? navActive,
    Color? navInactive,
    Color? statusConnected,
    Color? statusDisconnected,
  }) {
    return TDLColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      panel: panel ?? this.panel,
      panelElevated: panelElevated ?? this.panelElevated,
      borderPrimary: borderPrimary ?? this.borderPrimary,
      borderSecondary: borderSecondary ?? this.borderSecondary,
      borderFocus: borderFocus ?? this.borderFocus,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      live: live ?? this.live,
      chartGrid: chartGrid ?? this.chartGrid,
      chartAxis: chartAxis ?? this.chartAxis,
      chartCrosshair: chartCrosshair ?? this.chartCrosshair,
      chartSeries: chartSeries ?? this.chartSeries,
      navActive: navActive ?? this.navActive,
      navInactive: navInactive ?? this.navInactive,
      statusConnected: statusConnected ?? this.statusConnected,
      statusDisconnected: statusDisconnected ?? this.statusDisconnected,
    );
  }

  @override
  TDLColors lerp(ThemeExtension<TDLColors>? other, double t) {
    if (other is! TDLColors) return this;
    return TDLColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelElevated: Color.lerp(panelElevated, other.panelElevated, t)!,
      borderPrimary: Color.lerp(borderPrimary, other.borderPrimary, t)!,
      borderSecondary: Color.lerp(borderSecondary, other.borderSecondary, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      live: Color.lerp(live, other.live, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      chartAxis: Color.lerp(chartAxis, other.chartAxis, t)!,
      chartCrosshair: Color.lerp(chartCrosshair, other.chartCrosshair, t)!,
      chartSeries: _lerpSeries(chartSeries, other.chartSeries, t),
      navActive: Color.lerp(navActive, other.navActive, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      statusConnected: Color.lerp(statusConnected, other.statusConnected, t)!,
      statusDisconnected:
          Color.lerp(statusDisconnected, other.statusDisconnected, t)!,
    );
  }

  static List<Color> _lerpSeries(List<Color> a, List<Color> b, double t) {
    final length = a.length < b.length ? b.length : a.length;
    return List.generate(length, (i) {
      final ca = a[i % a.length];
      final cb = b[i % b.length];
      return Color.lerp(ca, cb, t)!;
    });
  }
}
