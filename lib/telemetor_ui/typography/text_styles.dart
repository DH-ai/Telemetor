import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/colors.dart';

/// Typography tokens for the Telemetor Design Language.
///
/// All styles use Inter. Registered as a [ThemeExtension] so they update when
/// the theme changes. Access via [TDLTextStyles.of] or `context.tdlText`.
@immutable
class TDLTextStyles extends ThemeExtension<TDLTextStyles> {
  const TDLTextStyles({
    required this.pageTitle,
    required this.sectionTitle,
    required this.metricLabel,
    required this.metricValue,
    required this.metricDelta,
    required this.tableHeader,
    required this.tableCell,
    required this.caption,
    required this.navItem,
    required this.navItemActive,
    required this.liveIndicator,
    required this.statusLabel,
    required this.mono,
    required this.monoSmall,
  });

  final TextStyle pageTitle;
  final TextStyle sectionTitle;
  final TextStyle metricLabel;
  final TextStyle metricValue;
  final TextStyle metricDelta;
  final TextStyle tableHeader;
  final TextStyle tableCell;
  final TextStyle caption;
  final TextStyle navItem;
  final TextStyle navItemActive;
  final TextStyle liveIndicator;
  final TextStyle statusLabel;
  final TextStyle mono;
  final TextStyle monoSmall;

  static TDLTextStyles of(BuildContext context) =>
      Theme.of(context).extension<TDLTextStyles>()!;

  /// Build the full typography set from a [TDLColors] palette.
  factory TDLTextStyles.fromColors(TDLColors colors) {
    TextStyle style({
      required double size,
      FontWeight weight = FontWeight.w400,
      Color? color,
      double? letterSpacing,
      double? height,
      bool uppercase = false,
    }) {
      final textStyle = GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? colors.textPrimary,
        letterSpacing: letterSpacing,
        height: height,
      );
      if (!uppercase) return textStyle;
      return textStyle.copyWith(
        // Uppercase is applied at the widget level via .toUpperCase() or
        // Text widget — keep the style itself clean for flexibility.
        letterSpacing: letterSpacing ?? 0.8,
      );
    }

    return TDLTextStyles(
      pageTitle: style(
        size: 18,
        weight: FontWeight.w600,
        letterSpacing: 1.2,
        uppercase: true,
      ),
      sectionTitle: style(
        size: 11,
        weight: FontWeight.w600,
        color: colors.textSecondary,
        letterSpacing: 1.0,
        uppercase: true,
      ),
      metricLabel: style(
        size: 10,
        weight: FontWeight.w500,
        color: colors.textSecondary,
        letterSpacing: 0.6,
        uppercase: true,
      ),
      metricValue: style(
        size: 22,
        weight: FontWeight.w600,
        height: 1.1,
      ),
      metricDelta: style(
        size: 10,
        weight: FontWeight.w500,
        color: colors.textSecondary,
      ),
      tableHeader: style(
        size: 10,
        weight: FontWeight.w600,
        color: colors.textSecondary,
        letterSpacing: 0.8,
        uppercase: true,
      ),
      tableCell: style(
        size: 12,
        weight: FontWeight.w400,
      ),
      caption: style(
        size: 10,
        weight: FontWeight.w400,
        color: colors.textMuted,
      ),
      navItem: style(
        size: 11,
        weight: FontWeight.w500,
        color: colors.navInactive,
        letterSpacing: 0.8,
        uppercase: true,
      ),
      navItemActive: style(
        size: 11,
        weight: FontWeight.w600,
        color: colors.navActive,
        letterSpacing: 0.8,
        uppercase: true,
      ),
      liveIndicator: style(
        size: 10,
        weight: FontWeight.w700,
        color: colors.live,
        letterSpacing: 1.2,
        uppercase: true,
      ),
      statusLabel: style(
        size: 10,
        weight: FontWeight.w500,
        color: colors.textSecondary,
      ),
      mono: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      ),
      monoSmall: GoogleFonts.jetBrainsMono(
        fontSize: 9,
        fontWeight: FontWeight.w400,
        color: colors.textMuted,
      ),
    );
  }

  @override
  TDLTextStyles copyWith({
    TextStyle? pageTitle,
    TextStyle? sectionTitle,
    TextStyle? metricLabel,
    TextStyle? metricValue,
    TextStyle? metricDelta,
    TextStyle? tableHeader,
    TextStyle? tableCell,
    TextStyle? caption,
    TextStyle? navItem,
    TextStyle? navItemActive,
    TextStyle? liveIndicator,
    TextStyle? statusLabel,
    TextStyle? mono,
    TextStyle? monoSmall,
  }) {
    return TDLTextStyles(
      pageTitle: pageTitle ?? this.pageTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      metricLabel: metricLabel ?? this.metricLabel,
      metricValue: metricValue ?? this.metricValue,
      metricDelta: metricDelta ?? this.metricDelta,
      tableHeader: tableHeader ?? this.tableHeader,
      tableCell: tableCell ?? this.tableCell,
      caption: caption ?? this.caption,
      navItem: navItem ?? this.navItem,
      navItemActive: navItemActive ?? this.navItemActive,
      liveIndicator: liveIndicator ?? this.liveIndicator,
      statusLabel: statusLabel ?? this.statusLabel,
      mono: mono ?? this.mono,
      monoSmall: monoSmall ?? this.monoSmall,
    );
  }

  @override
  TDLTextStyles lerp(ThemeExtension<TDLTextStyles>? other, double t) {
    if (other is! TDLTextStyles) return this;
    return TDLTextStyles(
      pageTitle: TextStyle.lerp(pageTitle, other.pageTitle, t)!,
      sectionTitle: TextStyle.lerp(sectionTitle, other.sectionTitle, t)!,
      metricLabel: TextStyle.lerp(metricLabel, other.metricLabel, t)!,
      metricValue: TextStyle.lerp(metricValue, other.metricValue, t)!,
      metricDelta: TextStyle.lerp(metricDelta, other.metricDelta, t)!,
      tableHeader: TextStyle.lerp(tableHeader, other.tableHeader, t)!,
      tableCell: TextStyle.lerp(tableCell, other.tableCell, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      navItem: TextStyle.lerp(navItem, other.navItem, t)!,
      navItemActive: TextStyle.lerp(navItemActive, other.navItemActive, t)!,
      liveIndicator: TextStyle.lerp(liveIndicator, other.liveIndicator, t)!,
      statusLabel: TextStyle.lerp(statusLabel, other.statusLabel, t)!,
      mono: TextStyle.lerp(mono, other.mono, t)!,
      monoSmall: TextStyle.lerp(monoSmall, other.monoSmall, t)!,
    );
  }
}
