import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/ai_feedback.dart';

class AiFeedbackCard extends StatelessWidget {
  const AiFeedbackCard({super.key, required this.feedback});

  final AiFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        if (feedback.summaryFeedback.isNotEmpty)
          _Section(
            child: Text(
              feedback.summaryFeedback,
              style: AppTypography.bodyLarge,
            ),
          ),

        // Top issues
        if (feedback.topIssues.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacing20),
          Text('Key Issues', style: AppTypography.titleMedium),
          const SizedBox(height: AppConstants.spacing8),
          ...feedback.topIssues.map(
            (issue) => Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacing8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacing12),
                  Expanded(
                    child: Text(issue, style: AppTypography.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Target sounds
        if (feedback.targetSounds.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacing20),
          Text('Target Sounds', style: AppTypography.titleMedium),
          const SizedBox(height: AppConstants.spacing8),
          Wrap(
            spacing: AppConstants.spacing8,
            runSpacing: AppConstants.spacing8,
            children: feedback.targetSounds
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacing12,
                      vertical: AppConstants.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: Text(s, style: AppTypography.monoMedium),
                  ),
                )
                .toList(),
          ),
        ],

        // Stress pattern advice
        if (feedback.stressPatternAdvice.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacing20),
          Text('Stress & Rhythm', style: AppTypography.titleMedium),
          const SizedBox(height: AppConstants.spacing8),
          Text(feedback.stressPatternAdvice, style: AppTypography.bodyMedium),
        ],

        // Fluency advice
        if (feedback.fluencyAdvice.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacing20),
          Text('Fluency', style: AppTypography.titleMedium),
          const SizedBox(height: AppConstants.spacing8),
          Text(feedback.fluencyAdvice, style: AppTypography.bodyMedium),
        ],

        // Practice exercises
        if (feedback.practiceExercises.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacing20),
          Text('Practice Exercises', style: AppTypography.titleMedium),
          const SizedBox(height: AppConstants.spacing8),
          ...feedback.practiceExercises.asMap().entries.map(
                (entry) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppConstants.spacing8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${entry.key + 1}.',
                          style: AppTypography.monoSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],

        // Native-like rewrite
        if (feedback.nativeLikeRewrite.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacing20),
          Text('Native-like Phrasing', style: AppTypography.titleMedium),
          const SizedBox(height: AppConstants.spacing8),
          Container(
            padding: const EdgeInsets.all(AppConstants.spacing16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusMedium),
            ),
            child: Text(
              feedback.nativeLikeRewrite,
              style: AppTypography.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: child,
    );
  }
}
