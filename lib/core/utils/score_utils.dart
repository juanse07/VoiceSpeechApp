import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

abstract final class ScoreUtils {
  static Color colorForScore(double score) {
    if (score >= 80) return AppColors.scoreGood;
    if (score >= 60) return AppColors.scoreOk;
    return AppColors.scorePoor;
  }

  static Color wordUnderlineColor(double accuracyScore, String errorType) {
    if (errorType == 'Omission') return AppColors.wordIncorrect;
    if (errorType == 'Insertion') return AppColors.wordIncorrect;
    if (errorType == 'Mispronunciation') {
      if (accuracyScore >= 80) return AppColors.wordNeedsWork;
      return AppColors.wordIncorrect;
    }
    if (accuracyScore >= 80) return AppColors.wordCorrect;
    if (accuracyScore >= 60) return AppColors.wordNeedsWork;
    return AppColors.wordIncorrect;
  }

  static String scoreLabel(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 60) return 'Fair';
    if (score >= 40) return 'Needs Work';
    return 'Poor';
  }

  static String errorTypeLabel(String errorType) {
    switch (errorType) {
      case 'Omission':
        return 'Skipped';
      case 'Insertion':
        return 'Extra word';
      case 'Mispronunciation':
        return 'Mispronounced';
      default:
        return 'Correct';
    }
  }
}
