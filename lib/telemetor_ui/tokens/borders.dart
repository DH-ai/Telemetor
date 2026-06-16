import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'spacing.dart';

/// Border primitives for the Telemetor Design Language.
///
/// Telemetor uses high-contrast 1 px borders instead of shadows for surface
/// separation. All border colors come from [TDLColors] — never hardcoded.
class TDLBorders {
  const TDLBorders._();

  static const double thin = 1;
  static const double medium = 2;

  // ---- BorderSide factories -------------------------------------------------

  static BorderSide side(TDLColors colors, {double width = thin}) =>
      BorderSide(color: colors.borderPrimary, width: width);

  static BorderSide divider(TDLColors colors) =>
      BorderSide(color: colors.borderSecondary, width: thin);

  static BorderSide selected(TDLColors colors) =>
      BorderSide(color: colors.accent, width: medium);

  static BorderSide alert(TDLColors colors) =>
      BorderSide(color: colors.error, width: thin);

  static BorderSide focus(TDLColors colors) =>
      BorderSide(color: colors.borderFocus, width: thin);

  // ---- Border composites ----------------------------------------------------

  static Border panel(TDLColors colors) => Border.all(
        color: colors.borderPrimary,
        width: thin,
      );

  static Border panelSelected(TDLColors colors) => Border.all(
        color: colors.accent,
        width: thin,
      );

  // ---- BoxDecoration presets ------------------------------------------------

  /// Standard bordered panel surface.
  static BoxDecoration panelDecoration(
    TDLColors colors, {
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) =>
      BoxDecoration(
        color: backgroundColor ?? colors.panel,
        border: panel(colors),
        borderRadius: borderRadius,
      );

  /// Elevated panel with a secondary outer feel.
  static BoxDecoration elevatedPanel(
    TDLColors colors, {
    BorderRadius? borderRadius,
  }) =>
      BoxDecoration(
        color: colors.panelElevated,
        border: panel(colors),
        borderRadius: borderRadius,
      );

  /// Horizontal section divider (top border).
  static BoxDecoration sectionDivider(TDLColors colors) => BoxDecoration(
        border: Border(top: divider(colors)),
      );

  /// Vertical rail divider (left border).
  static BoxDecoration railDivider(TDLColors colors) => BoxDecoration(
        border: Border(left: divider(colors)),
      );

  /// Active nav item left accent bar.
  static BoxDecoration navActiveIndicator(TDLColors colors) => BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.accent, width: medium),
        ),
      );

  /// Alert state panel border.
  static BoxDecoration alertPanel(TDLColors colors) => BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.error, width: thin),
      );

  /// Chart container with graph divider border.
  static BoxDecoration chartPanel(
    TDLColors colors, {
    BorderRadius? borderRadius,
  }) =>
      BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.borderSecondary, width: thin),
        borderRadius: borderRadius,
      );

  /// Inset content area inside a panel.
  static EdgeInsets panelInset = TDLSpacing.panel;
}
