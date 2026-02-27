import 'package:flutter/material.dart';

abstract final class AppColors {
  // Core palette
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFFF8C42);

  // Surfaces
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF5F5F5);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9E9E9E);

  // Borders
  static const Color border = Color(0xFFE8E8E8);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Scores
  static const Color scoreGood = Color(0xFF2D8A4E);
  static const Color scoreOk = Color(0xFFFF8C42);
  static const Color scorePoor = Color(0xFFD64045);

  // Subtle underlines for word analysis
  static const Color wordCorrect = Color(0xFF2D8A4E);
  static const Color wordNeedsWork = Color(0xFFFF8C42);
  static const Color wordIncorrect = Color(0xFFD64045);

  // Error type badge colors
  static const Color errorOmission = Color(0xFF9E9E9E);
  static const Color errorInsertion = Color(0xFF7B5EA7);
  static const Color errorMispronunciation = Color(0xFFD64045);

  // Prosody
  static const Color prosodyWarning = Color(0xFFE8A020);
}
