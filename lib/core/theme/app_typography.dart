import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  // IBM Plex Sans — primary
  static TextStyle get _baseSans => GoogleFonts.ibmPlexSans(
        color: AppColors.textPrimary,
      );

  // IBM Plex Mono — technical / IPA
  static TextStyle get _baseMono => GoogleFonts.ibmPlexMono(
        color: AppColors.textPrimary,
      );

  // Headlines
  static TextStyle get displayLarge => _baseSans.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => _baseSans.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle get headlineLarge => _baseSans.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  static TextStyle get headlineMedium => _baseSans.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  // Titles
  static TextStyle get titleLarge => _baseSans.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get titleMedium => _baseSans.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // Body
  static TextStyle get bodyLarge => _baseSans.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => _baseSans.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => _baseSans.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  // Labels
  static TextStyle get labelLarge => _baseSans.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => _baseSans.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
      );

  // Monospace — for IPA, phonemes, scores
  static TextStyle get monoLarge => _baseMono.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get monoMedium => _baseMono.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get monoSmall => _baseMono.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // Score display
  static TextStyle get scoreLarge => _baseMono.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.1,
      );

  static TextStyle get scoreMedium => _baseMono.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );
}
