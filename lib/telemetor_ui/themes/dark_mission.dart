import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Color palette for Dark Mission Mode — black field, white type, red accent.
///
/// Matches the TELEMETOR V2 mission-control aesthetic: high contrast borders,
/// no shadows, red for live/active states.
const TDLColors darkMissionColors = TDLColors(
  background: Color(0xFF000000),
  surface: Color(0xFF050505),
  panel: Color(0xFF0A0A0A),
  panelElevated: Color(0xFF111111),
  borderPrimary: Color(0xFF2A2A2A),
  borderSecondary: Color(0xFF1A1A1A),
  borderFocus: Color(0xFF444444),
  accent: Color(0xFFE52B2B),
  accentMuted: Color(0xFF8B1A1A),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFF888888),
  textMuted: Color(0xFF555555),
  textOnAccent: Color(0xFFFFFFFF),
  success: Color(0xFF4ADE80),
  warning: Color(0xFFFBBF24),
  error: Color(0xFFE52B2B),
  live: Color(0xFFE52B2B),
  chartGrid: Color(0xFF1A1A1A),
  chartAxis: Color(0xFF555555),
  chartCrosshair: Color(0xFF888888),
  chartSeries: [
    Color(0xFFFFFFFF),
    Color(0xFFE52B2B),
    Color(0xFF666666),
    Color(0xFF4ADE80),
    Color(0xFFFBBF24),
    Color(0xFF60A5FA),
    Color(0xFFC084FC),
    Color(0xFF34D399),
  ],
  navActive: Color(0xFFE52B2B),
  navInactive: Color(0xFF666666),
  statusConnected: Color(0xFFE52B2B),
  statusDisconnected: Color(0xFF888888),
);
