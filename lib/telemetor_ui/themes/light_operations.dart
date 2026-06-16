import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Color palette for Light Operations Mode — bright surfaces, same red accent.
const TDLColors lightOperationsColors = TDLColors(
  background: Color(0xFFF0F0F0),
  surface: Color(0xFFFFFFFF),
  panel: Color(0xFFFAFAFA),
  panelElevated: Color(0xFFFFFFFF),
  borderPrimary: Color(0xFFD4D4D4),
  borderSecondary: Color(0xFFE8E8E8),
  borderFocus: Color(0xFFAAAAAA),
  accent: Color(0xFFCC1F1F),
  accentMuted: Color(0xFFFFE5E5),
  textPrimary: Color(0xFF111111),
  textSecondary: Color(0xFF666666),
  textMuted: Color(0xFF999999),
  textOnAccent: Color(0xFFFFFFFF),
  success: Color(0xFF16A34A),
  warning: Color(0xFFD97706),
  error: Color(0xFFCC1F1F),
  live: Color(0xFFCC1F1F),
  chartGrid: Color(0xFFE8E8E8),
  chartAxis: Color(0xFF999999),
  chartCrosshair: Color(0xFF666666),
  chartSeries: [
    Color(0xFF111111),
    Color(0xFFCC1F1F),
    Color(0xFF888888),
    Color(0xFF16A34A),
    Color(0xFFD97706),
    Color(0xFF2563EB),
    Color(0xFF9333EA),
    Color(0xFF059669),
  ],
  navActive: Color(0xFFCC1F1F),
  navInactive: Color(0xFF888888),
  statusConnected: Color(0xFF16A34A),
  statusDisconnected: Color(0xFF999999),
);
