import 'package:flutter/material.dart';

/// Color palette.
///
/// Neutrals follow Tailwind's neutral scale. Semantic colors are only used
/// where the color carries meaning (Pomodoro phases, destructive actions).
class AppColors {
  AppColors._();

  // Neutrals
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral900 = Color(0xFF171717);
  static const Color neutral950 = Color(0xFF0A0A0A);

  // Light mode
  static const Color background = neutral50;
  static const Color surface = Colors.white;
  static const Color border = neutral200;
  static const Color textPrimary = neutral950;
  static const Color textSecondary = neutral600;
  static const Color textHint = neutral400;

  // Dark mode. Background is near-black (not pure black) to avoid OLED
  // smearing during scroll; surface sits slightly above it.
  static const Color darkBackground = neutral950;
  static const Color darkSurface = neutral900;
  static const Color darkBorder = Color(0xFF262626); // neutral-800
  static const Color darkTextPrimary = neutral50;
  static const Color darkTextSecondary = neutral400;
  static const Color darkTextHint = neutral600;

  // Accent
  static const Color accent = Color(0xFF10B981); // emerald-500

  // Pomodoro phases
  static const Color focus = Color(0xFFE11D48); // rose-600
  static const Color shortBreak = Color(0xFF10B981); // emerald-500
  static const Color longBreak = Color(0xFF3B82F6); // blue-500

  // Due-date warning and destructive actions
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color danger = Color(0xFFE11D48); // rose-600
}
