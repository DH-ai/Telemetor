import 'package:flutter/material.dart';

/// Teal seed carried over from the original prototype accent color.
const Color kSeedColor = Color(0xff1ccc9d);

ThemeData buildLightTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kSeedColor,
        brightness: Brightness.light,
      ),
    );

ThemeData buildDarkTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kSeedColor,
        brightness: Brightness.dark,
      ),
    );
