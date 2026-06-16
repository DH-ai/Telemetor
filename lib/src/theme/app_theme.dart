import 'package:flutter/material.dart';

import '../../telemetor_ui/telemetor_ui.dart';

/// Legacy entry points — prefer importing [telemetor_ui] directly.
ThemeData buildLightTheme() => buildTDLTheme(TDLThemeMode.lightOperations);

ThemeData buildDarkTheme() => buildTDLTheme(TDLThemeMode.darkMission);
