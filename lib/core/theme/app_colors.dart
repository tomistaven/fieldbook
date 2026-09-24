import 'package:flutter/material.dart';

/// Color palette. Neutrals follow Tailwind's gray scale; semantic colors are
/// only used where the color carries meaning (Pomodoro phases, overdue,
/// destructive actions).
abstract final class AppColors {
  // Light mode
  static const Color background = Color(0xFFF9FAFB); // gray-50
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE5E7EB); // gray-200
  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF4B5563); // gray-600
  static const Color textHint = Color(0xFF9CA3AF); // gray-400

  // Dark mode: deep grays instead of pure black; surfaces step up in
  // lightness so cards separate from the background.
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkBorder = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFF3F4F6); // gray-100
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // gray-400
  static const Color darkTextHint = Color(0xFF6B7280); // gray-500

  // Accent
  static const Color accent = Color(0xFF10B981); // emerald-500

  // Pomodoro phases
  static const Color focus = Color(0xFFE11D48); // rose-600
  static const Color shortBreak = Color(0xFF10B981); // emerald-500
  static const Color longBreak = Color(0xFF3B82F6); // blue-500

  // Overdue and destructive actions
  static const Color danger = Color(0xFFE11D48); // rose-600
}
