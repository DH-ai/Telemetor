import 'package:flutter/widgets.dart';

/// Strict spacing scale for the Telemetor Design Language.
///
/// Spacing is theme-independent: it never changes between Dark Mission and
/// Light Operations modes. Every gap, pad and inset in the application must
/// come from this scale — no raw numbers in layout code.
///
/// Scale: 2 · 4 · 8 · 12 · 16 · 24 · 32 · 48 · 64
class TDLSpacing {
  const TDLSpacing._();

  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;

  // ---- Symmetric insets -----------------------------------------------------
  static const EdgeInsets insetXs = EdgeInsets.all(xs);
  static const EdgeInsets insetSm = EdgeInsets.all(sm);
  static const EdgeInsets insetMd = EdgeInsets.all(md);
  static const EdgeInsets insetLg = EdgeInsets.all(lg);
  static const EdgeInsets insetXl = EdgeInsets.all(xl);

  /// Standard padding used inside panels.
  static const EdgeInsets panel = EdgeInsets.all(lg);

  /// Padding used inside compact panel headers.
  static const EdgeInsets panelHeader =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);

  // ---- Square gaps (use inside Row or Column) -------------------------------
  static const SizedBox gXs = SizedBox(width: xs, height: xs);
  static const SizedBox gSm = SizedBox(width: sm, height: sm);
  static const SizedBox gMd = SizedBox(width: md, height: md);
  static const SizedBox gLg = SizedBox(width: lg, height: lg);
  static const SizedBox gXl = SizedBox(width: xl, height: xl);

  /// Horizontal gap of [size].
  static SizedBox w(double size) => SizedBox(width: size);

  /// Vertical gap of [size].
  static SizedBox h(double size) => SizedBox(height: size);
}
