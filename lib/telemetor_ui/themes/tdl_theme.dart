import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../typography/text_styles.dart';
import 'dark_mission.dart';
import 'light_operations.dart';

/// Named Telemetor themes. Only token values differ between modes —
/// component code stays identical.
enum TDLThemeMode {
  darkMission,
  lightOperations,
}

/// Build a complete [ThemeData] for the given [TDLThemeMode].
ThemeData buildTDLTheme(TDLThemeMode mode) {
  final colors = switch (mode) {
    TDLThemeMode.darkMission => darkMissionColors,
    TDLThemeMode.lightOperations => lightOperationsColors,
  };
  final text = TDLTextStyles.fromColors(colors);
  final brightness =
      mode == TDLThemeMode.darkMission ? Brightness.dark : Brightness.light;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: colors.accent,
    onPrimary: colors.textOnAccent,
    secondary: colors.textSecondary,
    onSecondary: colors.textPrimary,
    error: colors.error,
    onError: colors.textOnAccent,
    surface: colors.surface,
    onSurface: colors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    colorScheme: colorScheme,
    extensions: [colors, text],
    fontFamily: GoogleFonts.inter().fontFamily,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.pageTitle,
    ),
    cardTheme: CardThemeData(
      color: colors.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.borderPrimary),
        borderRadius: BorderRadius.zero,
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: colors.borderSecondary,
      thickness: 1,
      space: 1,
    ),
    iconTheme: IconThemeData(
      color: colors.textSecondary,
      size: 18,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.panelElevated,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.borderPrimary),
        borderRadius: BorderRadius.zero,
      ),
      textStyle: text.tableCell,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.textOnAccent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: text.navItem.copyWith(color: colors.textOnAccent),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.borderPrimary),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: text.navItem,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colors.textSecondary,
        hoverColor: colors.panelElevated,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.panelElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.borderPrimary),
        borderRadius: BorderRadius.zero,
      ),
      titleTextStyle: text.sectionTitle.copyWith(color: colors.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.panel,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: colors.borderPrimary),
        borderRadius: BorderRadius.zero,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.borderPrimary),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.accent),
        borderRadius: BorderRadius.zero,
      ),
      labelStyle: text.caption,
      hintStyle: text.caption,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(colors.borderFocus),
      trackColor: WidgetStatePropertyAll(colors.borderSecondary),
      thickness: const WidgetStatePropertyAll(4),
      radius: Radius.zero,
    ),
  );
}

/// Convert Flutter [ThemeMode] to [TDLThemeMode].
TDLThemeMode tdlModeFromThemeMode(ThemeMode mode) => switch (mode) {
      ThemeMode.light => TDLThemeMode.lightOperations,
      ThemeMode.dark => TDLThemeMode.darkMission,
      ThemeMode.system => TDLThemeMode.darkMission,
    };

/// Convert [TDLThemeMode] to Flutter [ThemeMode].
ThemeMode themeModeFromTdl(TDLThemeMode mode) => switch (mode) {
      TDLThemeMode.darkMission => ThemeMode.dark,
      TDLThemeMode.lightOperations => ThemeMode.light,
    };
